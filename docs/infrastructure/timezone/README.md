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

## 手動での設定手順

### 設定

```bash
# タイムゾーンを設定（例: Asia/Tokyo）
sudo timedatectl set-timezone Asia/Tokyo

# 現在のタイムゾーンを確認
timedatectl status
```

### 利用可能なタイムゾーンの一覧を表示

```bash
timedatectl list-timezones
```