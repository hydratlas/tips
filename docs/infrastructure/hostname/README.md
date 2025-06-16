# hostname

システムホスト名設定ロール

## 概要

このロールは、システムのホスト名を設定します。`hostnamectl`コマンドを使用して永続的な変更を行います。

## 要件

- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `hostname`: 設定するホスト名（英数字とハイフンのみ、最大63文字）

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

## 手動での設定手順

```bash
# ホスト名を設定
sudo hostnamectl set-hostname webserver01

# 現在のホスト名を確認
hostnamectl status

# /etc/hostsファイルも更新（必要に応じて）
sudo sed -i "s/127.0.1.1.*/127.0.1.1\twebserver01/" /etc/hosts
```
