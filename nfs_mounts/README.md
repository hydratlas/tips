# nfs_mounts

NFSクライアント設定・マウント管理ロール

## 概要

このロールは、NFSクライアントの設定とNFS共有のマウントを管理します。必要なパッケージのインストール、マウントポイントの作成、NFSマウントの設定を行います。

## 要件

- NFSサーバーへのネットワークアクセス
- rootまたはsudo権限

## ロール変数

- `nfs_mount_patterns`: NFSマウントパターンの定義（辞書形式）
  - キー: パターン名
  - 値:
    - `src`: NFSサーバーとエクスポートパス
    - `path`: ローカルマウントポイント
    - `fstype`: ファイルシステムタイプ（通常は`nfs`）
    - `opts`: マウントオプション
    - `state`: マウント状態
    - `mode`: ディレクトリのパーミッション（オプション）
- `nfs_mount_selectors`: 適用するマウントパターンのリスト

## 使用例

```yaml
- hosts: nfs_clients
  become: true
  vars:
    nfs_mount_patterns:
      home:
        src: "nfs-server:/export/home"
        path: "/home"
        fstype: "nfs"
        opts: "rw,sync,hard,intr"
        state: "mounted"
      data:
        src: "nfs-server:/export/data"
        path: "/mnt/data"
        fstype: "nfs"
        opts: "ro,soft"
        state: "mounted"
    nfs_mount_selectors:
      - home
      - data
  roles:
    - nfs_mounts
```

## 設定内容

- NFSクライアントパッケージのインストール（nfs-common/nfs-utils）
- マウントポイントディレクトリの作成
- 選択されたパターンのNFSマウントを実行