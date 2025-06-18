# nfs_mounts

NFSクライアント設定・マウント管理ロール

## 概要

### このドキュメントの目的
このロールは、NFSクライアントのセットアップとNFS共有のマウント管理を行います。必要なパッケージのインストール、マウントポイントの作成、永続的なNFSマウント設定を自動化します。Ansible自動設定と手動設定の両方の方法について説明します。

### 実現される機能
- NFSクライアントパッケージの自動インストール
- マウントポイントディレクトリの作成と権限設定
- `/etc/fstab`へのNFSエントリ追加
- NFSシェアの自動マウント
- 再起動後も維持される永続的なマウント設定

## 要件と前提条件

### 共通要件
- Linux OS（Debian/Ubuntu/RHEL/CentOS/AlmaLinux）
- root権限またはsudo権限
- NFSサーバーへのネットワーク接続
- NFSサーバー側でエクスポート設定済み

### Ansible固有の要件
- Ansible 2.9以上
- プレイブックレベルで`become: true`の指定が必要

### 手動設定の要件
- bashシェル
- sudo権限を持つユーザー
- テキストエディタ（nano、vim等）
- NFSサーバーのIPアドレスまたはホスト名

## 設定方法

### 方法1: Ansible Roleを使用

#### ロール変数

| 変数名 | 説明 | デフォルト値 | 必須 |
|--------|------|-------------|------|
| `nfs_mount_patterns` | NFSマウントパターンの辞書 | なし | はい |
| `nfs_mount_patterns.<name>.src` | NFSサーバーとエクスポートパス | なし | はい |
| `nfs_mount_patterns.<name>.path` | ローカルマウントポイント | なし | はい |
| `nfs_mount_patterns.<name>.fstype` | ファイルシステムタイプ | `nfs` | いいえ |
| `nfs_mount_patterns.<name>.opts` | マウントオプション | なし | はい |
| `nfs_mount_patterns.<name>.state` | マウント状態 | なし | はい |
| `nfs_mount_patterns.<name>.mode` | ディレクトリ権限 | `'0755'` | いいえ |
| `nfs_mount_selectors` | 適用するパターン名のリスト | なし | はい |

#### 依存関係
なし

#### タグとハンドラー
- タグ: なし
- ハンドラー: なし

#### 使用例

基本的な使用例：
```yaml
- hosts: app_servers
  become: true
  vars:
    nfs_mount_patterns:
      shared_data:
        src: "192.168.1.100:/export/data"
        path: "/mnt/shared"
        fstype: "nfs"
        opts: "rw,sync,hard,intr"
        state: "mounted"
        mode: "0755"
    nfs_mount_selectors:
      - shared_data
  roles:
    - infrastructure/nfs_mounts
```

複数のNFSマウント設定例：
```yaml
- hosts: web_servers
  become: true
  vars:
    nfs_mount_patterns:
      home_dirs:
        src: "nfs-server.example.com:/export/home"
        path: "/nfs/home"
        fstype: "nfs"
        opts: "rw,sync,hard,intr,noatime"
        state: "mounted"
        mode: "0755"
      
      shared_apps:
        src: "nfs-server.example.com:/export/apps"
        path: "/nfs/apps"
        fstype: "nfs"
        opts: "ro,sync,hard,intr"
        state: "mounted"
        mode: "0755"
      
      backup_storage:
        src: "backup-nfs.example.com:/backup"
        path: "/mnt/backup"
        fstype: "nfs"
        opts: "rw,sync,hard,intr,_netdev"
        state: "mounted"
        mode: "0700"
    
    nfs_mount_selectors:
      - home_dirs
      - shared_apps
      - backup_storage
  roles:
    - infrastructure/nfs_mounts
```

NFSv4の使用例：
```yaml
- hosts: nfs_clients
  become: true
  vars:
    nfs_mount_patterns:
      nfsv4_share:
        src: "nfs4-server.example.com:/data"
        path: "/mnt/nfsv4"
        fstype: "nfs4"
        opts: "rw,sync,hard,intr,sec=sys"
        state: "mounted"
    nfs_mount_selectors:
      - nfsv4_share
  roles:
    - infrastructure/nfs_mounts
```

### 方法2: 手動での設定手順

#### ステップ1: 環境準備

```bash
# NFSサーバーへの接続確認
ping -c 4 nfs-server.example.com

# 現在のマウント状況確認
mount | grep nfs
df -h

# /etc/fstabのバックアップ
sudo cp /etc/fstab /etc/fstab.backup
```

#### ステップ2: NFSクライアントパッケージのインストール

Debian/Ubuntu系：
```bash
# パッケージリストの更新
sudo apt-get update

# NFSクライアントのインストール
sudo apt-get install -y nfs-common

# rpcbindサービスの確認
sudo systemctl status rpcbind
```

RHEL/CentOS/AlmaLinux系：
```bash
# NFSユーティリティのインストール
sudo yum install -y nfs-utils
# または
sudo dnf install -y nfs-utils

# 必要なサービスの起動
sudo systemctl enable --now rpcbind
sudo systemctl enable --now nfs-client.target
```

#### ステップ3: NFSエクスポートの確認

```bash
# NFSサーバーのエクスポート一覧を表示
showmount -e nfs-server.example.com

# 特定のエクスポートの詳細確認
rpcinfo -p nfs-server.example.com
```

#### ステップ4: マウントポイントの作成

```bash
# 単一のマウントポイント作成
sudo mkdir -p /mnt/shared
sudo chmod 755 /mnt/shared

# 複数のマウントポイント作成
for dir in /nfs/home /nfs/apps /mnt/backup; do
    sudo mkdir -p "$dir"
    sudo chmod 755 "$dir"
done

# 特定の権限設定が必要な場合
sudo chmod 700 /mnt/backup
```

#### ステップ5: 手動マウントのテスト

```bash
# 一時的なマウント（NFSv3）
sudo mount -t nfs -o rw,sync,hard,intr nfs-server.example.com:/export/data /mnt/shared

# NFSv4の場合
sudo mount -t nfs4 -o rw,sync,hard,intr,sec=sys nfs-server.example.com:/data /mnt/nfsv4

# マウントの確認
mount | grep /mnt/shared
ls -la /mnt/shared

# アンマウント
sudo umount /mnt/shared
```

#### ステップ6: 永続的なマウント設定（/etc/fstab）

```bash
# /etc/fstabに追加
echo "nfs-server.example.com:/export/data /mnt/shared nfs rw,sync,hard,intr,_netdev 0 0" | sudo tee -a /etc/fstab

# 複数のエントリを追加
cat << EOF | sudo tee -a /etc/fstab
nfs-server.example.com:/export/home /nfs/home nfs rw,sync,hard,intr,noatime,_netdev 0 0
nfs-server.example.com:/export/apps /nfs/apps nfs ro,sync,hard,intr,_netdev 0 0
backup-nfs.example.com:/backup /mnt/backup nfs rw,sync,hard,intr,_netdev 0 0
EOF

# fstabの構文確認
sudo mount -a -v --dry-run

# すべてのfstabエントリをマウント
sudo mount -a
```

## 運用管理

### 基本操作

NFSマウントの状態確認：
```bash
# 現在のNFSマウント
mount -t nfs,nfs4

# NFSマウントの統計情報
nfsstat -m

# マウントポイントの詳細
findmnt -t nfs,nfs4
```

NFSマウントの再マウント：
```bash
# 特定のマウントを再マウント
sudo umount /mnt/shared && sudo mount /mnt/shared

# すべてのNFSマウントを再マウント
sudo mount -a -t nfs,nfs4
```

### ログとモニタリング

```bash
# NFSクライアントのログ
sudo journalctl -u nfs-client.target -f

# マウント関連のカーネルメッセージ
sudo dmesg | grep -i nfs

# RPC関連のデバッグ情報
rpcdebug -m nfs -s all
```

パフォーマンス監視：
```bash
# NFS統計情報
nfsstat -c

# I/O統計
nfsiostat 1 10

# マウントポイントのI/O監視
iostat -n 1
```

### トラブルシューティング

#### 診断フロー

1. ネットワーク接続の確認
   ```bash
   ping -c 4 nfs-server
   telnet nfs-server 2049
   ```

2. NFSサービスの状態確認
   ```bash
   rpcinfo -p nfs-server
   showmount -e nfs-server
   ```

3. マウントのデバッグ
   ```bash
   sudo mount -v -t nfs -o vers=3 nfs-server:/export /mnt/test
   ```

#### よくある問題と対処方法

- **問題**: "mount.nfs: No route to host"
  - **対処**: ファイアウォール設定を確認、ポート111(rpcbind)と2049(nfs)を開放

- **問題**: "mount.nfs: access denied by server"
  - **対処**: サーバー側のエクスポート設定とクライアントのIPアドレスを確認

- **問題**: マウントがハングする
  - **対処**: `soft`オプションの使用を検討、タイムアウト値を調整

### メンテナンス

古いマウントのクリーンアップ：
```bash
# 応答しないNFSマウントの強制アンマウント
sudo umount -f /mnt/shared

# lazyアンマウント（使用中でも切断）
sudo umount -l /mnt/shared
```

NFSキャッシュのクリア：
```bash
# ページキャッシュをクリア
echo 3 | sudo tee /proc/sys/vm/drop_caches
```

## アンインストール（手動）

NFSマウントを削除する手順：

```bash
# 1. マウントを解除
sudo umount /mnt/shared
# 複数の場合
sudo umount /nfs/home /nfs/apps /mnt/backup

# 2. fstabエントリを削除
sudo sed -i '/nfs-server.example.com/d' /etc/fstab
# または手動で編集
sudo nano /etc/fstab

# 3. マウントポイントを削除（オプション）
sudo rmdir /mnt/shared
# 複数の場合
sudo rmdir /nfs/home /nfs/apps /mnt/backup

# 4. NFSクライアントパッケージを削除（オプション）
# Debian/Ubuntu
sudo apt-get remove --purge nfs-common

# RHEL/CentOS
sudo yum remove nfs-utils

# 5. 設定の確認
cat /etc/fstab | grep nfs
mount | grep nfs
```

## 注意事項

- `_netdev`オプションを必ず追加してネットワーク起動後にマウントするようにしてください
- ハードマウント（`hard`）は信頼性が高いが、サーバー障害時にハングする可能性があります
- ソフトマウント（`soft`）はタイムアウトしますが、データ損失のリスクがあります
- NFSv4を使用する場合は、適切なセキュリティ設定（`sec=`オプション）を検討してください
- ファイアウォールでポート111（rpcbind）と2049（nfs）を開放する必要があります