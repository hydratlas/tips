# ssh_secure

SSHセキュリティ強化ロール

## 概要

このロールは、SSHサーバーのセキュリティを強化します。パスワード認証の無効化、公開鍵認証の強制、その他のセキュリティ設定を適用します。オプションでカスタムSSHホストキーの設定も可能です。

## 要件

- OpenSSHサーバー
- rootまたはsudo権限

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