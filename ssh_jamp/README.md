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