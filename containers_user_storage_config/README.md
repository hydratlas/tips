# containers_user_storage_config

Podmanストレージ設定ロール（NFS環境用）

## 概要

このロールは、NFSホームディレクトリ環境でPodmanを使用する際の設定を行います。NFSマウントされたホームディレクトリ（`/nfs/home`）に設定ファイルを配置し、実際のコンテナストレージ（graphroot）はローカルディスク（`/home`）を使用するよう設定します。これにより、NFSの性能問題を回避します。

## 要件

- NFSホームディレクトリが`/nfs/home`にマウントされていること
- ローカルの`/home`ディレクトリが存在すること（btrfs限定）
- Podmanがインストールされていること

## ロール変数

- `containers_user_storage_config.home_base`: NFSホームディレクトリのベースパス（デフォルト: `/nfs/home`）
- `containers_user_storage_config.graphroot_home_base`: ローカルストレージのベースパス（デフォルト: `/home`）
- `user_list`: ユーザー情報のリスト
  - `name`: ユーザー名

## 使用例

```yaml
- hosts: nfs_home_servers
  become: true
  vars:
    containers_user_storage_config:
      home_base: /nfs/home
      graphroot_home_base: /home
    user_list:
      - { name: alice, uid: 1001, gid: 1001 }
      - { name: bob, uid: 1002, gid: 1002 }
  roles:
    - containers_user_storage_config
```

## 設定内容

各ユーザーに対して以下を実行：
- `/nfs/home/<user>/.config/containers` ディレクトリの作成
- `storage.conf` の作成：
  - `graphroot`: `/home/<user>/.local/share/containers/storage`（ローカル）
  - `driver`: `btrfs`（高速なストレージドライバー）
- 適切な権限設定（644）