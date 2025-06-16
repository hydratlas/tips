# hostname

システムホスト名設定ロール

## 概要

このロールは、システムのホスト名を設定します。

## 要件

- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `hostname`: 設定するホスト名

## 使用例

```yaml
- hosts: all
  become: true
  vars:
    hostname: webserver01
  roles:
    - hostname
```

## 設定内容

- システムのホスト名を指定された値に設定