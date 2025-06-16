# create_containers_storage_dir

ローカルコンテナストレージディレクトリ作成ロール

## 概要

このロールは、ローカルのbtrfsファイルシステム上（`/home`）に、Podmanのルートレスコンテナストレージディレクトリ構造を作成します。ホームディレクトリがNFS上の`/nfs/home`にある環境で、コンテナのgraphrootをローカルディスクに配置するために使用されます。

## 要件

- `create_home_dirs`ロールが事前に実行されていること
- ディレクトリ作成にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要

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

## 手動での設定手順

以下の手順により、Podmanのルートレスコンテナ用ストレージディレクトリを手動で作成できます：

### 1. ユーザー情報の確認

まず、対象ユーザーのUID/GIDを確認します：

```bash
# ユーザー情報の確認
id alice
# 出力例: uid=1001(alice) gid=1001(alice) groups=1001(alice)
```

### 2. ディレクトリ構造の作成

各ユーザーのローカルストレージディレクトリを作成します：

```bash
# ユーザー名とUID/GIDを設定
USERNAME="alice"
USER_UID="1001"
USER_GID="1001"

# .localディレクトリの作成
sudo mkdir -p /home/${USERNAME}/.local

# .local/shareディレクトリの作成
sudo mkdir -p /home/${USERNAME}/.local/share

# .local/share/containersディレクトリの作成
sudo mkdir -p /home/${USERNAME}/.local/share/containers

# .local/share/containers/storageディレクトリの作成
sudo mkdir -p /home/${USERNAME}/.local/share/containers/storage
```

### 3. 所有権とパーミッションの設定

作成したディレクトリに適切な所有権とパーミッションを設定します：

```bash
# 所有権の設定（UID:GIDを使用）
sudo chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.local
sudo chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.local/share
sudo chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.local/share/containers
sudo chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.local/share/containers/storage

# パーミッションの設定（755）
sudo chmod 755 /home/${USERNAME}/.local
sudo chmod 755 /home/${USERNAME}/.local/share
sudo chmod 755 /home/${USERNAME}/.local/share/containers
sudo chmod 755 /home/${USERNAME}/.local/share/containers/storage
```

### 4. 一括作成（効率的な方法）

複数のディレクトリを効率的に作成する場合：

```bash
# ユーザー情報を設定
USERNAME="alice"
USER_UID="1001"
USER_GID="1001"

# ディレクトリを一度に作成
sudo mkdir -p /home/${USERNAME}/.local/share/containers/storage

# 所有権を再帰的に設定
sudo chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.local

# パーミッションを確認（find使用）
find /home/${USERNAME}/.local -type d -exec chmod 755 {} \;
```

### 5. 設定の確認

ディレクトリ構造が正しく作成されたことを確認します：

```bash
# ディレクトリ構造の確認
tree -pugd /home/${USERNAME}/.local

# 期待される出力：
# /home/alice/.local [drwxr-xr-x 1001 1001]
# └── share [drwxr-xr-x 1001 1001]
#     └── containers [drwxr-xr-x 1001 1001]
#         └── storage [drwxr-xr-x 1001 1001]
```

### 注意事項

- このディレクトリ構造は、Podmanがルートレスモードで動作する際に必要です
- 各ユーザーのUID/GIDを正確に設定することが重要です
- 複数ユーザーを設定する場合は、各ユーザーに対して上記の手順を繰り返します