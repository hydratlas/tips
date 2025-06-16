# ssh_secure

SSHセキュリティ強化ロール

## 概要

このロールは、SSHサーバーのセキュリティを強化します。パスワード認証の無効化、公開鍵認証の強制、その他のセキュリティ設定を適用します。オプションでカスタムSSHホストキーの設定も可能です。

## 要件

- OpenSSHサーバー
- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `ssh_host_ed25519_key`: カスタムEd25519ホストキー（オプション、Vault暗号化推奨）
- `ssh_host_ed25519_key_pub`: カスタムEd25519ホスト公開鍵（オプション）

## 使用例

```yaml
- hosts: all
  become: true
  roles:
    - ssh_secure
```

カスタムホストキーを使用する場合：
```yaml
- hosts: all
  become: true
  vars:
    ssh_host_ed25519_key: "{{ vault_ssh_host_ed25519_key }}"
    ssh_host_ed25519_key_pub: "ssh-ed25519 AAAAC3..."
  roles:
    - ssh_secure
```

## 設定内容

- パスワード認証の無効化
- 公開鍵認証の強制
- セキュアなSSH設定の適用（`/etc/ssh/sshd_config.d/00-ssh-secure.conf`）
- カスタムSSHホストキーの設定（オプション）
- SSHデーモンの再起動

## 手動での設定手順

### 1. sshd_config.dディレクトリの作成

```bash
# ディレクトリが存在しない場合は作成
sudo mkdir -p /etc/ssh/sshd_config.d
sudo chmod 755 /etc/ssh/sshd_config.d
```

### 2. セキュアSSH設定の適用

```bash
# セキュアSSH設定ファイルを作成
sudo tee /etc/ssh/sshd_config.d/00-ssh-secure.conf > /dev/null << 'EOF'
PasswordAuthentication no
PermitRootLogin prohibit-password
EOF

# 権限を設定
sudo chmod 644 /etc/ssh/sshd_config.d/00-ssh-secure.conf
sudo chown root:root /etc/ssh/sshd_config.d/00-ssh-secure.conf
```

### 3. カスタムSSHホストキーの設定（オプション）

カスタムホストキーを使用する場合：

```bash
# カスタムホストキー設定ファイルを作成
sudo tee /etc/ssh/sshd_config.d/80-custom-hostkey.conf > /dev/null << 'EOF'
HostKey /etc/ssh/custom_ssh_host_ed25519_key
EOF

# 権限を設定
sudo chmod 644 /etc/ssh/sshd_config.d/80-custom-hostkey.conf
sudo chown root:root /etc/ssh/sshd_config.d/80-custom-hostkey.conf

# カスタム秘密鍵を配置（事前に生成した鍵を使用）
# 例: ssh-keygen -t ed25519 -f custom_ssh_host_ed25519_key -N '' -C ''
sudo cp custom_ssh_host_ed25519_key /etc/ssh/custom_ssh_host_ed25519_key
sudo chmod 600 /etc/ssh/custom_ssh_host_ed25519_key
sudo chown root:root /etc/ssh/custom_ssh_host_ed25519_key

# カスタム公開鍵を配置
sudo cp custom_ssh_host_ed25519_key.pub /etc/ssh/custom_ssh_host_ed25519_key.pub
sudo chmod 644 /etc/ssh/custom_ssh_host_ed25519_key.pub
sudo chown root:root /etc/ssh/custom_ssh_host_ed25519_key.pub
```

### 4. SSHサービスの再起動

```bash
# Debian/Ubuntu
sudo systemctl reload ssh

# RHEL/CentOS/Rocky Linux
sudo systemctl reload sshd
```

### 5. 設定の確認

```bash
# SSH設定のテスト
sudo sshd -t

# 現在の設定を確認
sudo sshd -T | grep -E "(PasswordAuthentication|PermitRootLogin)"
```

**注意**: SSHの設定を変更する前に、必ず別のセッションを開いたままにして、設定ミスによるアクセス不能を防いでください。