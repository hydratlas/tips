# timezone

システムタイムゾーン設定ロール

## 概要

このロールは、システムのタイムゾーンを設定します。

## 要件

- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `timezone`: 設定するタイムゾーン（例: "Asia/Tokyo", "UTC"）

## 使用例

```yaml
- hosts: all
  become: true
  vars:
    timezone: Asia/Tokyo
  roles:
    - timezone
```

## 設定内容

- システムタイムゾーンを指定された値に設定
- 変更は即座に反映される