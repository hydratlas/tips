# keepalived

VRRP高可用性設定ロール

## 概要

このロールは、Keepalivedを使用してVRRP（Virtual Router Redundancy Protocol）による高可用性を実現します。ジャンプホストなどの重要なサービスで仮想IPアドレスのフェイルオーバーを提供します。

## 要件

- Debian/RedHat系ディストリビューション
- rootまたはsudo権限
- ネットワークインターフェース設定済み
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

### デフォルト変数

- `keepalived_base_dir`: Keepalivedのベースディレクトリ（デフォルト: `/etc/keepalived`）
- `keepalived_config_file`: メイン設定ファイル（デフォルト: `{{ keepalived_base_dir }}/keepalived.conf`）
- `keepalived_config_dir`: 設定ディレクトリ（デフォルト: `{{ keepalived_base_dir }}/conf.d`）
- `keepalived_check_scripts_dir`: チェックスクリプトディレクトリ（デフォルト: `{{ keepalived_base_dir }}/scripts`）
- `keepalived_check_script_user`: チェックスクリプトのグローバルデフォルト実行ユーザー（デフォルト: `keepalived_script`）
- `keepalived_global_defs`: グローバル設定
- `keepalived_vrrp_instances`: VRRPインスタンス設定のリスト
- `keepalived_check_scripts`: チェックスクリプト設定のリスト（デフォルト: `[]`）

### VRRPインスタンスパラメータ

- `name`: インスタンス名（必須）
- `interface`: インターフェース名（必須）
- `state`: MASTER/BACKUP（デフォルト: MASTER）
- `virtual_router_id`: 仮想ルーターID（必須）
- `priority`: 優先度（必須）
- `virtual_ipaddresses`: 仮想IPアドレスリスト（必須）
- `auth_type`/`auth_pass`: 認証設定（オプション）
- `track_scripts`: トラッキングするスクリプト名のリスト（オプション）

## 使用例

### 基本設定

```yaml
- hosts: jamp_hosts
  become: true
  roles:
    - keepalived
```

### ホスト個別設定（host_vars）

```yaml
# host-01（MASTER）
keepalived_vrrp_instances:
  - name: "VI_1"
    interface: "eth0"
    state: "MASTER"
    virtual_router_id: 51
    priority: 100
    virtual_ipaddresses:
      - "192.168.1.100/24"
    track_scripts:
      - "check_ssh"

# host-02（BACKUP）
keepalived_vrrp_instances:
  - name: "VI_1"
    interface: "eth0"
    state: "BACKUP"
    virtual_router_id: 51
    priority: 90
    virtual_ipaddresses:
      - "192.168.1.100/24"
    track_scripts:
      - "check_ssh"
```

## 設定ファイル構造

- `/etc/keepalived/keepalived.conf` - メイン設定
- `/etc/keepalived/conf.d/00-global_defs.conf` - グローバル定義
- `/etc/keepalived/conf.d/10-vrrp_scripts.conf` - チェックスクリプト定義（チェックスクリプト使用時）
- `/etc/keepalived/conf.d/20-vrrp_instances.conf` - 全VRRPインスタンス設定

## チェックスクリプト

このロールでは、サービス監視用のチェックスクリプトを柔軟に管理できます。

### チェックスクリプトの設定

チェックスクリプトは`keepalived_check_scripts`変数で定義します：

```yaml
keepalived_check_scripts:
  - name: "check_ssh.sh"                 # スクリプトファイル名
    template: "check_ssh.sh.j2"          # テンプレートファイル名
    vrrp_name: "check_ssh"               # VRRP設定で使用する名前
    interval: 2                          # チェック間隔（秒）
    weight: -10                          # 失敗時の優先度変更値
    fall: 2                              # 失敗判定回数
    rise: 2                              # 復旧判定回数
    user: "keepalived_script"            # 実行ユーザー（デフォルト: "keepalived_script"）
    create_script_user: true             # ユーザーを自動作成するか（デフォルト: true）
```

### デフォルトで提供されるスクリプト

#### check_systemd_service.sh.j2
systemdサービス監視用のシンプルなスクリプトです。指定されたsystemdサービスの稼働状態を監視します。

使用方法：
```yaml
keepalived_check_scripts:
  - name: "check_ssh.sh"
    template: "check_systemd_service.sh.j2"
    vrrp_name: "check_ssh"
    service_name: "ssh.service"  # 監視するサービス名を指定
```

パラメータ：
- `service_name`: 監視するサービス名（必須。例: "ssh.service", "nginx.service", "cloudflared.service"）

### チェックスクリプトユーザーの管理

チェックスクリプトの実行ユーザーは以下のように制御できます：

1. **チェックスクリプトを使用しない場合**
   ```yaml
   keepalived_check_scripts: []
   ```
   この場合、ユーザーは作成されません。

2. **デフォルトユーザーを使用する場合**
   ```yaml
   keepalived_check_scripts:
     - name: "check_ssh.sh"
       template: "check_ssh.sh.j2"
       vrrp_name: "check_ssh"
       # userを省略すると"keepalived_script"が使用されます
   ```
   デフォルトで`keepalived_script`ユーザーが作成・使用されます。

3. **既存のユーザーを使用する場合**
   ```yaml
   keepalived_check_scripts:
     - name: "check_ssh.sh"
       template: "check_ssh.sh.j2"
       vrrp_name: "check_ssh"
       user: "nagios"
       create_script_user: false
   ```
   既存の`nagios`ユーザーを使用し、新規作成はしません。

4. **グローバルデフォルトユーザーを変更する場合**
   ```yaml
   # 全てのスクリプトのデフォルト実行ユーザーを変更
   keepalived_check_script_user: "monitoring"
   ```
   この設定により、個別に`user`を指定しないスクリプトは`monitoring`ユーザーで実行されます。

### Cloudflaredとの統合例

Cloudflaredロールと組み合わせて使用する場合：

```yaml
# group_vars/cloudflared_hosts.yml
keepalived_check_scripts:
  - name: "check_cloudflared.sh"
    template: "check_systemd_service.sh.j2"
    vrrp_name: "check_cloudflared"
    service_name: "cloudflared.service"  # 正確なサービス名を指定
    interval: 5
    weight: -20
    user: "cloudflared"  # cloudflaredユーザーで実行
    create_script_user: false  # cloudflaredロールでユーザーが作成済み

keepalived_vrrp_instances:
  - name: "VI_CLOUDFLARED"
    interface: "eth0"
    virtual_router_id: 60
    priority: 100
    virtual_ipaddresses:
      - "10.0.0.100/24"
    track_scripts:
      - "check_cloudflared"
```

## 動作確認

```bash
# ステータス確認
systemctl status keepalived

# 仮想IP確認
ip addr show dev eth0

# フェイルオーバーテスト
systemctl stop keepalived  # MASTERで実行
```