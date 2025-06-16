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

## 手動での設定手順

### 1. チェックスクリプト用ユーザーの作成

```bash
# keepalived_script ユーザーの作成（システムユーザー）
sudo useradd -r -s /usr/sbin/nologin -d /nonexistent -M -c "Keepalived health check script user" keepalived_script
```

### 2. Keepalivedのインストール

#### Debian/Ubuntu
```bash
# パッケージリストの更新
sudo apt-get update

# keepalivedのインストール
sudo apt-get install -y keepalived
```

#### RHEL/CentOS/Fedora
```bash
# keepalivedのインストール
sudo dnf install -y keepalived
```

### 3. ディレクトリ構造の作成

```bash
# 設定ディレクトリの作成
sudo mkdir -p /etc/keepalived/conf.d
sudo chmod 755 /etc/keepalived
sudo chmod 755 /etc/keepalived/conf.d

# スクリプトディレクトリの作成
sudo mkdir -p /etc/keepalived/scripts
sudo chmod 755 /etc/keepalived/scripts
```

### 4. チェックスクリプトの作成

```bash
# systemdサービス監視スクリプトの作成（例：SSH監視）
sudo tee /etc/keepalived/scripts/check_ssh.sh << 'EOF' > /dev/null
#!/bin/bash
# Check if systemd service is active
if systemctl is-active --quiet ssh.service; then
    exit 0
else
    exit 1
fi
EOF

# スクリプトに実行権限を付与
sudo chmod 755 /etc/keepalived/scripts/check_ssh.sh
sudo chown root:root /etc/keepalived/scripts/check_ssh.sh
```

### 5. メイン設定ファイルの作成

```bash
# メイン設定ファイル（conf.dディレクトリをインクルード）
sudo tee /etc/keepalived/keepalived.conf << 'EOF' > /dev/null
# Main configuration file for keepalived
# Include all configuration files from conf.d directory
include /etc/keepalived/conf.d/*.conf
EOF

sudo chmod 644 /etc/keepalived/keepalived.conf
sudo chown root:root /etc/keepalived/keepalived.conf
```

### 6. グローバル設定の作成

```bash
# グローバル定義
sudo tee /etc/keepalived/conf.d/00-global_defs.conf << 'EOF' > /dev/null
global_defs {
    # 通知メール無効化（メール設定なし）
    enable_script_security
    script_user keepalived_script
}
EOF

sudo chmod 644 /etc/keepalived/conf.d/00-global_defs.conf
sudo chown root:root /etc/keepalived/conf.d/00-global_defs.conf
```

### 7. VRRPスクリプトの定義

```bash
# チェックスクリプトの定義
sudo tee /etc/keepalived/conf.d/10-vrrp_scripts.conf << 'EOF' > /dev/null
vrrp_script check_ssh {
    script "/etc/keepalived/scripts/check_ssh.sh"
    interval 2      # チェック間隔（秒）
    weight -10      # 失敗時の優先度減少値
    fall 2          # 失敗判定回数
    rise 2          # 復旧判定回数
    user keepalived_script
}
EOF

sudo chmod 644 /etc/keepalived/conf.d/10-vrrp_scripts.conf
sudo chown root:root /etc/keepalived/conf.d/10-vrrp_scripts.conf
```

### 8. VRRPインスタンスの設定

#### MASTERノードの場合
```bash
# VRRPインスタンス設定（MASTER）
sudo tee /etc/keepalived/conf.d/20-vrrp_instances.conf << 'EOF' > /dev/null
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    
    # 認証設定（オプション）
    authentication {
        auth_type PASS
        auth_pass 1234
    }
    
    # 仮想IPアドレス
    virtual_ipaddress {
        10.120.20.51/24
    }
    
    # トラッキングスクリプト
    track_script {
        check_ssh
    }
}
EOF

sudo chmod 600 /etc/keepalived/conf.d/20-vrrp_instances.conf
sudo chown root:root /etc/keepalived/conf.d/20-vrrp_instances.conf
```

#### BACKUPノードの場合
```bash
# VRRPインスタンス設定（BACKUP）
sudo tee /etc/keepalived/conf.d/20-vrrp_instances.conf << 'EOF' > /dev/null
vrrp_instance VI_1 {
    state BACKUP
    interface eth0
    virtual_router_id 51
    priority 90
    advert_int 1
    
    # 認証設定（オプション）
    authentication {
        auth_type PASS
        auth_pass 1234
    }
    
    # 仮想IPアドレス
    virtual_ipaddress {
        10.120.20.51/24
    }
    
    # トラッキングスクリプト
    track_script {
        check_ssh
    }
}
EOF

sudo chmod 600 /etc/keepalived/conf.d/20-vrrp_instances.conf
sudo chown root:root /etc/keepalived/conf.d/20-vrrp_instances.conf
```

### 9. サービスの有効化と起動

```bash
# systemdデーモンのリロード
sudo systemctl daemon-reload

# keepalivedサービスの有効化
sudo systemctl enable keepalived

# keepalivedサービスの起動
sudo systemctl start keepalived
```

### 10. 動作確認

```bash
# サービスステータスの確認
sudo systemctl status keepalived

# 設定の検証
sudo keepalived -t

# ログの確認
sudo journalctl -u keepalived -f

# 仮想IPアドレスの確認（MASTERで実行）
ip addr show dev eth0 | grep -E "inet .* secondary"

# VRRPステータスの確認
sudo journalctl -u keepalived | grep -E "(Entering|Leaving) (MASTER|BACKUP) STATE"
```

### 11. フェイルオーバーテスト

```bash
# MASTERノードでサービスを停止
sudo systemctl stop keepalived

# BACKUPノードで仮想IPを確認
ip addr show dev eth0 | grep -E "inet .* secondary"

# MASTERノードでサービスを再開
sudo systemctl start keepalived
```

### 注意事項
- `virtual_router_id`は同一ネットワーク内で一意である必要があります（1-255）
- 優先度（priority）は0-255の範囲で、値が大きいほど優先されます
- 認証パスワードは8文字以内である必要があります
- ファイアウォールでVRRPプロトコル（112）を許可する必要があります