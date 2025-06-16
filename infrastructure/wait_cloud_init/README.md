# wait-cloud-init

cloud-init完了待機ロール

## 概要

このロールは、cloud-initの初期化が完了するまで待機します。cloud-initが存在しない場合は、正常にスキップします。

## 機能

1. **cloud-init待機**: cloud-initの初期化完了まで待機

## 要件

- cloud-initコマンドの実行にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要
- cloud-initが存在しない場合は自動的にスキップ

## ロール変数

- `wait_cloud_init_enabled`: cloud-init待機を有効化（デフォルト: true）

## 使用例

```yaml
- hosts: cloud_instances
  become: true
  roles:
    - wait-cloud-init
    - other_roles  # cloud-init完了後に実行される
```

待機を無効化する場合：
```yaml
- hosts: cloud_instances
  become: true
  roles:
    - role: wait-cloud-init
      vars:
        wait_cloud_init_enabled: false  # cloud-init待機を無効化
```

## 設定内容

### cloud-init待機
- cloud-initステータスの確認
- 初期化完了まで待機
- cloud-initが存在しない場合は正常にスキップ
- VMのプロビジョニング後の設定競合を防止