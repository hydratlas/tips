# sssd_sudo_provider

SSSD sudoプロバイダー設定ロール

## 概要

このロールは、SSSDをFreeIPA/IdMのsudoプロバイダーとして設定します。これにより、FreeIPAサーバーで集中管理されたsudoルールを使用できるようになります。

## 要件

- SSSDがインストールされ、FreeIPA/IdMドメインに参加していること
- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

なし（このロールは固定の設定を適用します）

## 使用例

```yaml
- hosts: ipa_clients
  become: true
  roles:
    - sssd_sudo_provider
```

## 設定内容

- SSSDのsudoプロバイダー設定を追加
- FreeIPA/IdMサーバーからのsudoルール取得を有効化
- SSSDサービスの再起動
- 集中管理されたsudoポリシーの適用