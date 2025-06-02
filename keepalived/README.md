# Keepalivedロール

このロールは、VRRP（仮想ルーター冗長プロトコル）を使用した高可用性のためにKeepalived をインストールおよび設定します。

## 要件

- DebianベースまたはRedHatベースのディストリビューション
- rootまたはsudoアクセス
- 設定済みで有効なネットワークインターフェース

## 設定ファイル構造

このロールは、Keepalivedの設定を以下のように構成します：

- `/etc/keepalived/keepalived.conf` - メイン設定ファイル（conf.dディレクトリを含む）
- `/etc/keepalived/conf.d/` - 設定ファイルディレクトリ
  - `00-global_defs.conf` - グローバル定義
  - `<interface>.conf` - インターフェース別のVRRPインスタンス設定（例: `eth0.conf`）

## ロール変数

### デフォルト変数（defaults/main.yml）

#### 設定パス
- `keepalived_config_file`: メイン設定ファイルのパス（デフォルト: "/etc/keepalived/keepalived.conf"）
- `keepalived_config_dir`: 設定ディレクトリのパス（デフォルト: "/etc/keepalived/conf.d"）

#### グローバル定義
- `keepalived_global_defs`: グローバル設定のディクショナリ（デフォルトはrouter_idのみ）
  ```yaml
  keepalived_global_defs:
    router_id: "{{ inventory_hostname_short }}"
  ```

#### VRRPインスタンス設定
- `keepalived_vrrp_instances`: VRRPインスタンスのリスト（デフォルトは空リスト）
  - 各インスタンスで設定可能なパラメータ：
    - `name`: インスタンス名（必須）
    - `interface`: インターフェース名（必須）
    - `state`: MASTER または BACKUP（省略時はMASTER）
    - `virtual_router_id`: 仮想ルーターID（必須）
    - `priority`: 優先度（必須）
    - `advert_int`: アドバタイズメント間隔（デフォルト: 1）
    - `auth_type`: 認証タイプ（オプション）
    - `auth_pass`: 認証パスワード（オプション）
    - `virtual_ipaddresses`: 仮想IPアドレスのリスト（必須）
    - `nopreempt`: プリエンプトを無効化（オプション）
    - `preempt_delay`: プリエンプト遅延（オプション）
    - その他のKeepalived設定パラメータ

### ホスト固有の変数

各ホストのVRRP状態（MASTER/BACKUP）は、host_varsで個別に設定します。
これにより、特定のホスト名にハードコーディングされることなく、柔軟な構成が可能です。

例：
- `jamp-01.int.home.arpa`: state: "MASTER"、priority: 100
- `jamp-02.int.home.arpa`: state: "BACKUP"、priority: 90

## 依存関係

なし

## プレイブックの例

### 基本的な使用例

```yaml
- hosts: jamp_hosts
  become: true
  roles:
    - keepalived
```

### ホスト固有の設定例 (host_vars)

#### host_vars/jamp-01.int.home.arpa.yml
```yaml
keepalived_vrrp_instances:
  - name: "VI_1"
    interface: "eth0"
    state: "MASTER"  # このホストがMASTER
    virtual_router_id: 51
    priority: 100    # 高い優先度
    advert_int: 1
    auth_type: "PASS"
    auth_pass: "{{ vault_keepalived_auth_pass }}"
    virtual_ipaddresses:
      - "10.120.20.51/16"
```

#### host_vars/jamp-02.int.home.arpa.yml
```yaml
keepalived_vrrp_instances:
  - name: "VI_1"
    interface: "eth0"
    state: "BACKUP"  # このホストがBACKUP
    virtual_router_id: 51
    priority: 90     # 低い優先度
    advert_int: 1
    auth_type: "PASS"
    auth_pass: "{{ vault_keepalived_auth_pass }}"
    virtual_ipaddresses:
      - "10.120.20.51/16"
```

### 複数インターフェースの設定例

```yaml
# host_vars/server1.yml
keepalived_vrrp_instances:
  - name: "VI_1"
    interface: "eth0"
    state: "MASTER"
    virtual_router_id: 51
    priority: 100
    advert_int: 1
    auth_type: "PASS"
    auth_pass: "{{ vault_keepalived_auth_pass }}"
    virtual_ipaddresses:
      - "10.120.20.51/24"
  - name: "VI_2"
    interface: "eth1"
    state: "BACKUP"  # 同じホストでもインターフェースごとに異なる役割を設定可能
    virtual_router_id: 52
    priority: 90
    advert_int: 1
    auth_type: "PASS"
    auth_pass: "{{ vault_keepalived_auth_pass }}"
    virtual_ipaddresses:
      - "192.168.1.100/24"
      - "192.168.1.101/24"
```

### カスタムグローバル定義の例

```yaml
- hosts: jamp_hosts
  become: true
  vars:
    keepalived_global_defs:
      router_id: "custom_router_id"
      enable_script_security: true
      script_user: "keepalived_script"
      vrrp_skip_check_adv_addr: true
      vrrp_strict: true
      vrrp_garp_interval: 0
      vrrp_gna_interval: 0
  roles:
    - keepalived
```

## 生成される設定ファイル

### /etc/keepalived/keepalived.conf
```
! Configuration File for keepalived
! Ansible managed

! Include all configuration files from conf.d directory
include /etc/keepalived/conf.d/*.conf
```

### /etc/keepalived/conf.d/00-global_defs.conf
```
! Global definitions configuration
! Ansible managed

global_defs {
    router_id jamp-01
}
```

### /etc/keepalived/conf.d/eth0.conf
```
! VRRP instance configuration for interface eth0
! Ansible managed

vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    
    authentication {
        auth_type PASS
        auth_pass ********
    }
    
    virtual_ipaddress {
        10.120.20.51/24
    }
}
```

## テスト

keepalived設定をテストするには：

```bash
# keepalivedのステータスを確認
systemctl status keepalived

# keepalivedのログを表示
journalctl -u keepalived -f

# 仮想IPが割り当てられているか確認（MASTERで）
ip addr show dev eth0

# 設定ファイルの確認
ls -la /etc/keepalived/conf.d/

# MASTERでkeepalivedを停止してフェイルオーバーをテスト
systemctl stop keepalived
```

## セキュリティに関する考慮事項

- `keepalived_auth_pass`変数は必ずAnsible Vaultで暗号化する
- 仮想ルーターIDがネットワーク内で一意であることを確認する
- VRRPトラフィック（プロトコル112）を許可するファイアウォールルールを設定する

## ライセンス

メインプロジェクトと同じ