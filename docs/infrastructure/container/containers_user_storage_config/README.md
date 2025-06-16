# containers_user_storage_config

Podmanストレージ設定ロール（NFS環境用）

## 概要

このロールは、NFSホームディレクトリ環境でPodmanを使用する際の設定を行います。NFSマウントされたホームディレクトリ（`/nfs/home`）に設定ファイルを配置し、実際のコンテナストレージ（graphroot）はローカルディスク（`/home`）を使用するよう設定します。これにより、NFSの性能問題を回避します。ストレージドライバには`btrfs`を設定します。

## 要件

- NFSのホームディレクトリが`/nfs/home`にマウントされていること
- 前項のホームディレクトリとは別にローカルの`/home`ディレクトリが存在すること（btrfs限定）
- Podmanがインストールされていること
- ファイル操作にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要

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
  - `driver`: `btrfs`（高速なストレージドライバ）
- 適切な権限設定（644）

## 手動での設定手順

以下の手順により、NFSホームディレクトリ環境でPodmanストレージを手動で設定できます：

### 1. 必要なディレクトリの作成

各ユーザーごとに設定ディレクトリを作成します：

```bash
# ユーザー名を設定
USERNAME="alice"

# .configディレクトリの作成
sudo mkdir -p /nfs/home/${USERNAME}/.config/containers

# 所有権の設定
sudo chown -R ${USERNAME}:${USERNAME} /nfs/home/${USERNAME}/.config
```

### 2. storage.confの作成

Podmanのストレージ設定ファイルを作成します：

```bash
# storage.confファイルの作成
sudo tee /nfs/home/${USERNAME}/.config/containers/storage.conf << 'EOF'
[storage]
driver = "btrfs"
graphroot = "/home/${USERNAME}/.local/share/containers/storage"
EOF
```

### 3. 権限設定

権限を修正します：

```bash
# ファイルの所有権と権限を設定
sudo chown ${USERNAME}:${USERNAME} /nfs/home/${USERNAME}/.config/containers/storage.conf
sudo chmod 644 /nfs/home/${USERNAME}/.config/containers/storage.conf
```

### 4. 設定の確認

設定が正しく適用されたことを確認します：

```bash
# storage.confの内容確認
cat /nfs/home/${USERNAME}/.config/containers/storage.conf

# 期待される出力：
# [storage]
# driver = "btrfs"
# graphroot = "/home/alice/.local/share/containers/storage"
```

### 5. ローカルストレージディレクトリの準備

実際のコンテナストレージが配置されるローカルディレクトリを準備します：

```bash
# ローカルストレージディレクトリの作成（ユーザー自身で実行）
su - ${USERNAME} -c "mkdir -p /home/${USERNAME}/.local/share/containers/storage"
```

### 注意事項

- NFSホームディレクトリ（`/nfs/home`）には設定ファイルのみが配置されます
- 実際のコンテナイメージとレイヤーはローカルディスク（`/home`）に保存されます
- ローカルディスクはbtrfsファイルシステムである必要があります
- 複数ユーザーを設定する場合は、各ユーザーに対して上記の手順を繰り返します