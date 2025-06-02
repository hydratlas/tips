# ansible_user_config

Ansibleユーザー設定ロール

## 概要

このロールは、Ansible管理用ユーザーの設定を行います。SSHキーの配置、sudo権限の設定、シェル環境の設定、セキュリティ向上のためのroot SSHアクセスの削除を実施します。

## 要件

- rootまたはsudo権限
- ansibleユーザーが存在すること

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