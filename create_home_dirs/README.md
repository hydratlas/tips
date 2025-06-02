# create_home_dirs

ローカルホームディレクトリ作成ロール（Podman用）

## 概要

このロールは、NFSマウントされたホームディレクトリ（`/nfs/home`）とは別に、ローカルのbtrfsファイルシステム上に`/home`ディレクトリを作成します。これは、Podmanのコンテナストレージ（graphroot）をNFS上ではなくローカルディスクに配置するために使用されます。

## 要件

- ローカルファイルシステム（btrfs限定）
- NFSホームディレクトリが別パスにマウントされていること

## ロール変数

- `create_home_dirs.home_base`: ローカルホームディレクトリのベースパス（デフォルト: `/home`）
- `user_list`: ユーザー情報のリスト
  - `name`: ユーザー名
  - `uid`: ユーザーID
  - `gid`: グループID

## 使用例

```yaml
- hosts: computes
  become: true
  vars:
    create_home_dirs:
      home_base: /home
    user_list:
      - { name: alice, uid: 1001, gid: 1001 }
      - { name: bob, uid: 1002, gid: 1002 }
  roles:
    - create_home_dirs
```

## 設定内容

- ローカル `/home` ディレクトリの作成（権限: 755）
- 各ユーザーのローカルホームディレクトリの作成（権限: 700）
- Podmanストレージ用の適切な所有権設定