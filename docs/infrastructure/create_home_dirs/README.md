# create_home_dirs

ローカルホームディレクトリ作成ロール（Podman用）

## 概要

このロールは、NFSマウントされたホームディレクトリ（`/nfs/home`）とは別に、ローカルのbtrfsファイルシステム上に`/home`ディレクトリを作成します。これは、Podmanのコンテナストレージ（graphroot）をNFS上ではなくローカルディスクに配置するために使用されます。

## 要件

- ローカルファイルシステム（btrfs限定）
- NFSホームディレクトリが別パスにマウントされていること
- ディレクトリ作成にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要

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

## 手動での設定手順

### 1. ホームディレクトリのベースを作成

```bash
# /homeディレクトリの作成（通常は既に存在）
sudo mkdir -p /home
sudo chmod 755 /home
sudo chown root:root /home
```

### 2. 各ユーザーのホームディレクトリを作成

```bash
# ユーザー alice (UID: 1001, GID: 1001) の例
sudo mkdir -p /home/alice
sudo chown 1001:1001 /home/alice
sudo chmod 700 /home/alice

# ユーザー bob (UID: 1002, GID: 1002) の例
sudo mkdir -p /home/bob
sudo chown 1002:1002 /home/bob
sudo chmod 700 /home/bob
```

### 3. 複数ユーザーを一括処理する場合

```bash
# ユーザーリストを定義（名前:UID:GID形式）
cat > /tmp/user_list.txt << 'EOF'
alice:1001:1001
bob:1002:1002
carol:1003:1003
EOF

# 一括でホームディレクトリを作成
while IFS=: read -r username uid gid; do
    sudo mkdir -p "/home/${username}"
    sudo chown "${uid}:${gid}" "/home/${username}"
    sudo chmod 700 "/home/${username}"
    echo "Created home directory for ${username}"
done < /tmp/user_list.txt

# 一時ファイルを削除
rm /tmp/user_list.txt
```

### 4. 作成したディレクトリの確認

```bash
# ディレクトリ一覧と権限を確認
ls -la /home/

# 特定ユーザーのディレクトリ情報を確認
stat /home/alice
```

### 5. Podmanストレージの確認（参考）

```bash
# ユーザーとしてPodmanストレージの場所を確認
su - alice -c "podman info --format '{{.Store.GraphRoot}}'"

# 通常は /home/alice/.local/share/containers/storage に作成される
```

**注意**: 
- このロールは主にPodmanのローカルストレージ用にホームディレクトリを作成します
- NFSマウントされたホームディレクトリ（通常は `/nfs/home`）とは別に管理されます
- UID/GIDは既存のLDAP/IDMユーザーと一致させる必要があります