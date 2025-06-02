# nsswitch_subid

NSS subuid/subgid設定ロール

## 概要

このロールは、コンテナのsubuid/subgid検索のためにNSS（Name Service Switch）を設定します。`/etc/nsswitch.conf` にSSSDをプロバイダーとして追加し、集中管理されたUID/GIDマッピングを有効にします。

## 要件

- SSSDがインストールされ設定されていること
- rootまたはsudo権限

## ロール変数

なし（このロールは固定の設定を適用します）

## 使用例

```yaml
- hosts: container_hosts
  become: true
  roles:
    - nsswitch_subid
```

## 設定内容

- `/etc/nsswitch.conf` の更新
- `subuid` と `subgid` エントリにSSSDプロバイダーを追加
- コンテナのユーザー名前空間マッピングを集中管理可能に