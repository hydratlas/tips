# wait-cloud-init

cloud-init完了待機ロール

## 概要

このロールは、cloud-initの初期化が完了するまで待機します。cloud-initが存在しない場合は、正常にスキップします。

## 要件

- cloud-initコマンドの実行にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要
- cloud-initが存在しない場合は自動的にスキップ

## ロール変数

なし

## 使用例

```yaml
- hosts: cloud_instances
  become: true
  roles:
    - wait-cloud-init
    - other_roles  # cloud-init完了後に実行される
```

## 設定内容

- cloud-initステータスの確認
- 初期化完了まで待機（最大600秒）
- cloud-initが存在しない場合は正常にスキップ
- VMのプロビジョニング後の設定競合を防止