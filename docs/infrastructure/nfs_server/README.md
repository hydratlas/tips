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

## 手動での設定手順

### Debian/Ubuntu の場合

```bash
# NFSサーバーパッケージのインストール
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

# エクスポートディレクトリの作成（例: /export/data）
sudo mkdir -p /export/data
sudo chmod 755 /export/data

# /etc/exports の編集
sudo nano /etc/exports
# 以下の行を追加:
# /export/data 192.168.1.0/24(rw,sync,no_subtree_check)

# エクスポート設定の再読み込み
sudo exportfs -ra

# NFSサービスの起動と有効化
sudo systemctl start nfs-kernel-server
sudo systemctl enable nfs-kernel-server

# エクスポート状態の確認
sudo exportfs -v
```

### RHEL/CentOS の場合

```bash
# NFSサーバーパッケージのインストール
sudo dn install -y nfs-utils

# エクスポートディレクトリの作成（例: /export/data）
sudo mkdir -p /export/data
sudo chmod 755 /export/data

# /etc/exports の編集
sudo vi /etc/exports
# 以下の行を追加:
# /export/data 192.168.1.0/24(rw,sync,no_subtree_check)

# エクスポート設定の再読み込み
sudo exportfs -ra

# NFSサービスの起動と有効化
sudo systemctl start nfs-server
sudo systemctl enable nfs-server

# ファイアウォールの設定（必要な場合）
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --reload

# エクスポート状態の確認
sudo exportfs -v
```

### トラブルシューティング

```bash
# NFSサービスの状態確認
sudo systemctl status nfs-kernel-server  # Debian/Ubuntu
sudo systemctl status nfs-server         # RHEL/CentOS

# ログの確認
sudo journalctl -u nfs-kernel-server -f  # Debian/Ubuntu
sudo journalctl -u nfs-server -f         # RHEL/CentOS

# クライアントからのマウントテスト
showmount -e nfs-server-ip
```