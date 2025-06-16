# mounts

ローカルファイルシステムマウント管理ロール

## 概要

このロールは、ローカルファイルシステムのマウントポイントを管理します。`/etc/fstab` エントリの作成とマウントの実行を行います。

## 要件

- rootまたはsudo権限
- マウント対象のデバイスまたはファイルシステム
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `mounts`: マウント設定のリスト
  - `src`: ソースデバイスまたはファイルシステム
  - `path`: マウントポイント
  - `fstype`: ファイルシステムタイプ
  - `opts`: マウントオプション（デフォルト: defaults）
  - `state`: マウント状態（mounted/present/absent/unmounted）

## 使用例

```yaml
- hosts: all
  become: true
  vars:
    mounts:
      - src: /dev/sdb1
        path: /data
        fstype: ext4
        opts: defaults,noatime
        state: mounted
  roles:
    - mounts
```

## 設定内容

- マウントポイントディレクトリの作成
- `/etc/fstab` エントリの管理
- ファイルシステムのマウント/アンマウント

## 手動での設定手順

### 1. マウントポイントの作成

```bash
# マウントポイントディレクトリを作成
sudo mkdir -p /data
sudo chmod 755 /data
sudo chown root:root /data

# カスタム権限が必要な場合
sudo mkdir -p /backup
sudo chmod 750 /backup
sudo chown root:root /backup
```

### 2. ファイルシステムの確認

```bash
# 利用可能なブロックデバイスを確認
lsblk

# ファイルシステムタイプを確認
sudo blkid /dev/sdb1

# ディスクのパーティション情報を確認
sudo fdisk -l /dev/sdb
```

### 3. 手動マウント（一時的）

```bash
# ext4ファイルシステムをマウント
sudo mount -t ext4 -o defaults,noatime /dev/sdb1 /data

# btrfsファイルシステムをマウント
sudo mount -t btrfs -o defaults,compress=zstd /dev/sdc1 /backup

# マウント状態を確認
mount | grep /data
df -h /data
```

### 4. /etc/fstabへの追加（永続的）

```bash
# fstabのバックアップを作成
sudo cp /etc/fstab /etc/fstab.backup

# fstabエントリを追加
echo "/dev/sdb1 /data ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab

# UUIDを使用する場合（推奨）
# まずUUIDを確認
sudo blkid /dev/sdb1
# 出力例: /dev/sdb1: UUID="1234-5678-..." TYPE="ext4"

# UUIDでfstabに追加
echo "UUID=1234-5678-... /data ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab

# btrfsの例
echo "UUID=abcd-ef01-... /backup btrfs defaults,compress=zstd 0 0" | sudo tee -a /etc/fstab
```

### 5. fstabの検証とマウント

```bash
# fstabの構文をチェック
sudo mount -a --fake

# 全てのfstabエントリをマウント
sudo mount -a

# エラーが発生した場合は、fstabを修正
sudo nano /etc/fstab
```

### 6. マウント状態の確認

```bash
# マウント状態を確認
mount | grep -E "(^/dev/|UUID=)"

# ディスク使用状況を確認
df -hT

# 特定のマウントポイントの詳細情報
findmnt /data
```

### 7. アンマウント

```bash
# 通常のアンマウント
sudo umount /data

# 使用中でアンマウントできない場合
# 使用中のプロセスを確認
sudo lsof /data
sudo fuser -v /data

# 強制的にアンマウント（注意して使用）
sudo umount -f /data

# 遅延アンマウント（プロセス終了後にアンマウント）
sudo umount -l /data
```

### 8. fstabからエントリを削除

```bash
# fstabを編集してエントリを削除
sudo nano /etc/fstab
# 該当行を削除またはコメントアウト（行頭に#を追加）

# またはsedで自動削除
sudo sed -i '/\/data/d' /etc/fstab
```

**注意**:
- `/etc/fstab`を編集する際は必ずバックアップを作成してください
- 間違った設定をするとシステムが起動しなくなる可能性があります
- UUIDの使用を推奨します（デバイス名は変更される可能性があるため）
- `dump`と`passno`の値について：
  - dump: 0（バックアップ不要）または1（バックアップ対象）
  - passno: 0（チェック不要）、1（ルート）、2（その他）