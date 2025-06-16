# nfs_server

NFSサーバー設定ロール

## 概要

このロールは、NFSサーバーをセットアップし、ディレクトリをエクスポートします。必要なパッケージのインストール、エクスポートディレクトリの作成、`/etc/exports` の設定を行います。

## 要件

- rootまたはsudo権限
- エクスポートするディレクトリ
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `nfs_exports`: NFSエクスポート設定のリスト
  - `path`: エクスポートするディレクトリパス
  - `options`: エクスポートオプション
  - `clients`: クライアント設定のリスト

## 使用例

```yaml
- hosts: nfs_servers
  become: true
  vars:
    nfs_exports:
      - path: /export/data
        clients:
          - host: "192.168.1.0/24"
            options: "rw,sync,no_subtree_check"
  roles:
    - nfs_server
```

## 設定内容

- NFSサーバーパッケージのインストール
- エクスポートディレクトリの作成
- `/etc/exports` の設定（テンプレート使用）
- NFSサービスの起動と有効化