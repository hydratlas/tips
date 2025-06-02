# create_containers_storage_dir

ローカルコンテナストレージディレクトリ作成ロール

## 概要

このロールは、ローカルのbtrfsファイルシステム上（`/home`）に、Podmanのルートレスコンテナストレージディレクトリ構造を作成します。NFSホームディレクトリが`/nfs/home`にある環境で、コンテナのgraphrootをローカルディスクに配置するために使用されます。

## 要件

- ローカルファイルシステム（btrfs限定）
- `create_home_dirs`ロールが事前に実行されていること

## ロール変数

- `create_containers_storage_dir.home_base`: ローカルホームディレクトリのベースパス（デフォルト: `/home`）
- `user_list`: ユーザー情報のリスト
  - `name`: ユーザー名
  - `uid`: ユーザーID
  - `gid`: グループID

## 使用例

```yaml
- hosts: computes
  become: true
  vars:
    create_containers_storage_dir:
      home_base: /home
    user_list:
      - { name: alice, uid: 1001, gid: 1001 }
      - { name: bob, uid: 1002, gid: 1002 }
  roles:
    - create_containers_storage_dir
```

## 設定内容

各ユーザーに対して以下のディレクトリ構造を作成：
- `/home/<user>/.local`
- `/home/<user>/.local/share`
- `/home/<user>/.local/share/containers`
- `/home/<user>/.local/share/containers/storage`

すべて適切な所有権（uid/gid）とパーミッション（755）で設定されます。