# nfs_mounts

NFSクライアント設定・マウント管理ロール

## 概要

このロールは、NFSクライアントの設定とNFS共有のマウントを管理します。必要なパッケージのインストール、マウントポイントの作成、NFSマウントの設定を行います。

## 要件

- NFSサーバーへのネットワークアクセス
- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

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

## 手動での設定手順

### 1. NFSクライアントパッケージのインストール

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y nfs-common

# RHEL/CentOS/Rocky Linux
sudo dnf install -y nfs-utils
```

### 2. NFSサーバーの確認

```bash
# NFSサーバーでエクスポートされているディレクトリを確認
showmount -e nfs-server.example.com

# 出力例:
# Export list for nfs-server.example.com:
# /export/home *
# /export/data 192.168.1.0/24
```

### 3. マウントポイントの作成

```bash
# ホームディレクトリ用
sudo mkdir -p /nfs/home
sudo chmod 755 /nfs/home

# データディレクトリ用
sudo mkdir -p /mnt/data
sudo chmod 755 /mnt/data

# カスタム権限が必要な場合
sudo mkdir -p /mnt/backup
sudo chmod 750 /mnt/backup
```

### 4. 手動マウント（一時的）

```bash
# 基本的なNFSマウント
sudo mount -t nfs nfs-server:/export/home /nfs/home

# オプション付きマウント
sudo mount -t nfs -o rw,sync,hard,intr nfs-server:/export/home /nfs/home

# 読み取り専用マウント
sudo mount -t nfs -o ro,soft nfs-server:/export/data /mnt/data

# NFSv4を明示的に指定
sudo mount -t nfs4 -o rw,sync nfs-server:/export/home /nfs/home
```

### 5. /etc/fstabへの追加（永続的）

```bash
# fstabのバックアップを作成
sudo cp /etc/fstab /etc/fstab.backup

# NFSマウントエントリを追加
echo "nfs-server:/export/home /nfs/home nfs rw,sync,hard,intr 0 0" | sudo tee -a /etc/fstab

# 複数のエントリを追加
cat >> /etc/fstab << 'EOF'
nfs-server:/export/home /nfs/home nfs rw,sync,hard,intr 0 0
nfs-server:/export/data /mnt/data nfs ro,soft 0 0
EOF

# NFSv4の場合
echo "nfs-server:/export/home /nfs/home nfs4 rw,sync 0 0" | sudo tee -a /etc/fstab
```

### 6. マウントオプションの説明

```bash
# よく使用されるNFSマウントオプション:
# rw        - 読み書き可能
# ro        - 読み取り専用
# sync      - 同期書き込み（データの整合性を保証）
# async     - 非同期書き込み（パフォーマンス向上）
# hard      - サーバー応答まで無限に再試行
# soft      - タイムアウト後にエラーを返す
# intr      - 割り込み可能（Ctrl+Cで中断可能）
# timeo=n   - タイムアウト時間（1/10秒単位）
# retrans=n - 再送信回数
# rsize=n   - 読み取りバッファサイズ
# wsize=n   - 書き込みバッファサイズ

# 推奨設定例
# ホームディレクトリ（信頼性重視）
echo "nfs-server:/home /nfs/home nfs rw,sync,hard,intr,timeo=100,retrans=5 0 0" | sudo tee -a /etc/fstab

# 一時データ（パフォーマンス重視）
echo "nfs-server:/tmp /mnt/tmp nfs rw,async,soft,timeo=50,retrans=2,rsize=8192,wsize=8192 0 0" | sudo tee -a /etc/fstab
```

### 7. fstabからのマウント

```bash
# fstabの構文をチェック
sudo mount -a --fake

# 全てのNFSエントリをマウント
sudo mount -a

# 特定のマウントポイントのみマウント
sudo mount /nfs/home
```

### 8. マウント状態の確認

```bash
# 現在のNFSマウントを確認
mount -t nfs
mount -t nfs4

# より詳細な情報
findmnt -t nfs,nfs4

# NFSの統計情報
nfsstat -m

# ディスク使用状況
df -hT | grep nfs
```

### 9. トラブルシューティング

```bash
# マウントできない場合の確認事項

# 1. ネットワーク接続を確認
ping nfs-server

# 2. NFSサービスの状態を確認（NFSサーバー側）
sudo systemctl status nfs-server

# 3. ファイアウォールを確認
# NFSv3: ポート 111 (portmapper), 2049 (nfs)
# NFSv4: ポート 2049 のみ

# 4. rpcbindサービスを確認（NFSv3の場合）
sudo systemctl status rpcbind
sudo systemctl start rpcbind

# 5. 詳細なデバッグ情報でマウント
sudo mount -v -t nfs nfs-server:/export/home /nfs/home

# 6. dmesgでカーネルメッセージを確認
sudo dmesg | tail -20
```

### 10. アンマウント

```bash
# 通常のアンマウント
sudo umount /nfs/home

# 使用中の場合の対処
# プロセスを確認
sudo lsof /nfs/home
sudo fuser -v /nfs/home

# 強制アンマウント（データ損失の可能性あり）
sudo umount -f /nfs/home

# 遅延アンマウント
sudo umount -l /nfs/home
```

**注意**:
- NFSマウントはネットワークに依存するため、ネットワーク接続を確認してください
- `hard`マウントはサーバー障害時にプロセスがハングする可能性があります
- `soft`マウントはデータ損失の可能性がありますが、タイムアウトします
- NFSv4はNFSv3よりもファイアウォール設定が簡単です（ポート2049のみ）
- 重要なデータには`sync`オプションを使用してください