# ifupdown_config

ネットワークインターフェース設定ロール

## 概要

このロールは、Debianスタイルのネットワーク設定（ifupdown）を管理します。`/etc/network/interfaces` ファイルを配置してネットワークインターフェースを設定します。

## 要件

- Debianベースのディストリビューション
- ifupdownパッケージ
- root権限が必要なため、プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `ifupdown_config_content`: interfaces設定ファイルの内容

## 使用例

```yaml
- hosts: debian_hosts
  become: true
  vars:
    ifupdown_config_content: |
      auto lo
      iface lo inet loopback
      
      auto eth0
      iface eth0 inet dhcp
  roles:
    - ifupdown_config
```

## 設定内容

- `/etc/network/interfaces` ファイルの配置
- ネットワークインターフェースの設定