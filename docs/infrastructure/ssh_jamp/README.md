# ssh_jamp

SSHジャンプホスト設定ロール

## 概要

このロールは、SSHジャンプホスト（踏み台サーバー）専用の設定を適用します。エージェント転送の有効化など、ジャンプホストに必要な特別なSSH設定を行います。

## 要件

- OpenSSHサーバー
- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

このロールは変数を使用しません。設定はテンプレートに固定されています。

## 使用例

```yaml
- hosts: jamp_hosts
  become: true
  roles:
    - ssh_jamp
```

## 設定内容

- `/etc/ssh/sshd_config.d/10-ssh-jamp.conf` の配置
- SSHエージェント転送の有効化
- ジャンプホスト用の接続制限とタイムアウト設定
- SSHデーモンの再起動

## 手動での設定手順

## 設定

```bash
# SSH設定ディレクトリの作成
sudo mkdir -p /etc/ssh/sshd_config.d
sudo chmod 755 /etc/ssh/sshd_config.d

# ジャンプホスト用設定ファイルの作成（ansibleは実際のユーザー名に置換）
sudo tee /etc/ssh/sshd_config.d/10-ssh-jamp.conf > /dev/null << 'EOF'
Match User ansible
    PermitTTY yes
    ForceCommand none

Match all
    PermitTTY no
    ForceCommand /usr/usr/sbin/nologin
EOF

# 設定ファイルの権限設定
sudo chmod 644 /etc/ssh/sshd_config.d/10-ssh-jamp.conf
sudo chown root:root /etc/ssh/sshd_config.d/10-ssh-jamp.conf

# SSH設定の検証
sudo sshd -t

# SSHサービスの再読み込み
sudo systemctl reload ssh
```

### 設定の確認

```bash
# SSH設定の確認
sudo sshd -T | grep -E "permittty|forcecommand"

# 接続テスト（別のホストから）
ssh -J jumphost-server target-server

# ログの確認
sudo journalctl -u ssh -f    # Debian/Ubuntu
sudo journalctl -u sshd -f   # RHEL/CentOS
```

### 注意事項

- この設定は特定のユーザー（通常はansibleユーザー）のみにTTYアクセスを許可します
- その他のユーザーはnologinコマンドに制限されます
- ジャンプホストとして使用する場合は、必要に応じてユーザーを追加設定してください