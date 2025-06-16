# ansible_user_config

Ansibleユーザー設定ロール

## 概要

このロールは、Ansible管理用ユーザーの設定を行います。SSHキーの配置、sudo権限の設定、シェル環境の設定、セキュリティ向上のためのroot SSHアクセスの削除を実施します。

## 要件

- rootまたはsudo権限
- ansibleユーザーが存在すること
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `ansible_user_authorized_keys`: 許可するSSH公開鍵のリスト
- `ansible_user_shell`: ユーザーのシェル（デフォルト: /bin/bash）

## 使用例

```yaml
- hosts: all
  become: true
  vars:
    ansible_user_authorized_keys:
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... admin@example.com"
  roles:
    - ansible_user_config
```

## 設定内容

- ansibleユーザーのSSH authorized_keysファイルの設定
- sudo権限の設定（パスワードなしsudo）
- ユーザーシェルの設定
- セキュリティ向上のためrootユーザーのSSHキー削除

## 手動での設定手順

### 1. ansibleユーザーの作成（既に存在しない場合）

```bash
# ユーザーを作成
sudo useradd -m -s /bin/bash ansible

# パスワードを無効化（ログイン不可、SSHキー認証のみ）
sudo passwd -l ansible
```

### 2. SSH公開鍵の設定

```bash
# .sshディレクトリの作成
sudo mkdir -p /home/ansible/.ssh
sudo chmod 700 /home/ansible/.ssh
sudo chown ansible:ansible /home/ansible/.ssh

# authorized_keysファイルの作成
sudo touch /home/ansible/.ssh/authorized_keys
sudo chmod 600 /home/ansible/.ssh/authorized_keys
sudo chown ansible:ansible /home/ansible/.ssh/authorized_keys

# SSH公開鍵を追加
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... admin@example.com" | sudo tee -a /home/ansible/.ssh/authorized_keys

# 複数の鍵を追加する場合
cat >> /home/ansible/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... admin1@example.com
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... admin2@example.com
EOF
```

### 3. sudo権限の設定

```bash
# sudoersファイルを作成（パスワードなしsudo）
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/95-ansible-user

# ファイル権限を設定
sudo chmod 440 /etc/sudoers.d/95-ansible-user
sudo chown root:root /etc/sudoers.d/95-ansible-user

# 構文をチェック
sudo visudo -cf /etc/sudoers.d/95-ansible-user
```

### 4. ユーザーシェルとパスワードの設定

```bash
# シェルを/bin/bashに設定
sudo usermod -s /bin/bash ansible

# パスワードを無効化（*に設定）
sudo usermod -p '*' ansible

# 設定を確認
grep ansible /etc/passwd
sudo grep ansible /etc/shadow
```

### 5. rootユーザーのセキュリティ強化

```bash
# rootユーザーのSSH鍵を削除
sudo rm -f /root/.ssh/authorized_keys

# rootのパスワードを無効化
sudo passwd -l root
# または
sudo usermod -p '*' root
```

### 6. 設定の確認

```bash
# ansibleユーザーでSSH接続をテスト
ssh ansible@localhost

# sudo権限をテスト（ansibleユーザーとして）
sudo -l
sudo whoami

# authorized_keysの内容を確認
sudo cat /home/ansible/.ssh/authorized_keys

# sudoersファイルの確認
sudo cat /etc/sudoers.d/95-ansible-user
```

### 7. トラブルシューティング

```bash
# SSH接続できない場合
# 1. SSH鍵の権限を確認
sudo ls -la /home/ansible/.ssh/
# .ssh: 700, authorized_keys: 600 であることを確認

# 2. SSHデーモンの設定を確認
sudo sshd -T | grep -E "(PubkeyAuthentication|AuthorizedKeysFile)"

# 3. SELinuxのコンテキストを修正（RHEL系の場合）
sudo restorecon -R /home/ansible/.ssh

# sudo権限が動作しない場合
# 1. sudoersファイルの構文を再確認
sudo visudo -c

# 2. sudoersディレクトリの内容を確認
sudo ls -la /etc/sudoers.d/

# 3. メインのsudoersファイルがincludeディレクティブを含むか確認
sudo grep "#includedir" /etc/sudoers
```

### 8. セキュリティのベストプラクティス

```bash
# 定期的にSSH鍵を更新
# 1. 新しい鍵を生成（クライアント側）
ssh-keygen -t ed25519 -C "admin@example.com"

# 2. 新しい公開鍵を追加
echo "新しい公開鍵" | sudo tee -a /home/ansible/.ssh/authorized_keys

# 3. 古い鍵を削除
sudo sed -i '/古い鍵の一部/d' /home/ansible/.ssh/authorized_keys

# ログの監視
# ansibleユーザーのsudo使用履歴
sudo grep ansible /var/log/auth.log    # Debian/Ubuntu
sudo grep ansible /var/log/secure      # RHEL/CentOS
```

**注意**:
- ansibleユーザーは管理専用のため、通常のログインには使用しないでください
- SSH鍵は定期的に更新し、不要な鍵は削除してください
- sudoersファイルの編集は必ず`visudo`コマンドまたは構文チェックを使用してください
- rootアカウントへの直接アクセスを無効化することでセキュリティが向上します