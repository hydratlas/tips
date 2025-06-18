# mounts

ローカルファイルシステムマウント管理ロール

## 概要

### このドキュメントの目的
このロールは、Linuxシステムのローカルファイルシステムマウントポイントを管理します。`/etc/fstab`エントリの作成、マウントポイントディレクトリの作成、マウント/アンマウント操作を自動化します。Ansible自動設定と手動設定の両方の方法について説明します。

### 実現される機能
- マウントポイントディレクトリの自動作成
- `/etc/fstab`エントリの管理
- ファイルシステムのマウント/アンマウント
- マウントオプションの設定
- 永続的なマウント設定

## 要件と前提条件

### 共通要件
- Linux OS
- root権限またはsudo権限
- マウント対象のデバイスまたはファイルシステムが利用可能
- 必要なファイルシステムドライバがカーネルに組み込まれている

### Ansible固有の要件
- Ansible 2.9以上
- プレイブックレベルで`become: true`の指定が必要

### 手動設定の要件
- bashシェル
- sudo権限を持つユーザー
- mount/umountコマンド
- テキストエディタ（nano、vim等）

## 設定方法

### 方法1: Ansible Roleを使用

#### ロール変数

| 変数名 | 説明 | デフォルト値 | 必須 |
|--------|------|-------------|------|
| `mounts` | マウント設定のリスト | `[]` | いいえ |
| `mounts[].src` | ソースデバイスまたはファイルシステム | なし | はい |
| `mounts[].path` | マウントポイントのパス | なし | はい |
| `mounts[].fstype` | ファイルシステムタイプ | なし | はい |
| `mounts[].opts` | マウントオプション | なし | はい |
| `mounts[].dump` | dumpフラグ（0または1） | なし | はい |
| `mounts[].passno` | fsckパス番号（0、1、2） | なし | はい |
| `mounts[].state` | マウント状態（mounted/present/absent/unmounted） | なし | はい |
| `mounts[].mode` | ディレクトリのパーミッション | `'0755'` | いいえ |

#### 依存関係
なし

#### タグとハンドラー
- タグ: なし
- ハンドラー: なし

#### 使用例

基本的なマウント設定：
```yaml
- hosts: storage_servers
  become: true
  vars:
    mounts:
      - src: /dev/sdb1
        path: /data
        fstype: ext4
        opts: defaults,noatime
        dump: 0
        passno: 2
        state: mounted
        mode: '0755'
  roles:
    - infrastructure/mounts
```

複数のマウントポイント設定：
```yaml
- hosts: app_servers
  become: true
  vars:
    mounts:
      # データパーティション
      - src: /dev/vg_data/lv_app
        path: /app
        fstype: xfs
        opts: defaults,noatime,nodiratime
        dump: 0
        passno: 2
        state: mounted
        mode: '0755'
      
      # ログパーティション
      - src: /dev/vg_data/lv_logs
        path: /var/log/app
        fstype: ext4
        opts: defaults,noatime
        dump: 0
        passno: 2
        state: mounted
        mode: '0755'
      
      # 一時ファイル用tmpfs
      - src: tmpfs
        path: /app/tmp
        fstype: tmpfs
        opts: size=2G,mode=1777
        dump: 0
        passno: 0
        state: mounted
  roles:
    - infrastructure/mounts
```

バインドマウントの例：
```yaml
- hosts: containers
  become: true
  vars:
    mounts:
      - src: /data/shared
        path: /opt/app/shared
        fstype: none
        opts: bind,rw
        dump: 0
        passno: 0
        state: mounted
        mode: '0755'
  roles:
    - infrastructure/mounts
```

### 方法2: 手動での設定手順

#### ステップ1: 環境準備

```bash
# 利用可能なデバイスを確認
lsblk -f
sudo fdisk -l

# 現在のマウント状況を確認
mount | column -t
df -h

# /etc/fstabのバックアップ
sudo cp /etc/fstab /etc/fstab.backup
```

#### ステップ2: マウントポイントの作成

```bash
# マウントポイントディレクトリを作成
sudo mkdir -p /data
sudo chmod 755 /data
sudo chown root:root /data

# 複数のマウントポイントを作成する場合
for dir in /app /var/log/app /app/tmp; do
    sudo mkdir -p "$dir"
    sudo chmod 755 "$dir"
    sudo chown root:root "$dir"
done
```

#### ステップ3: ファイルシステムの作成（必要な場合）

```bash
# ext4ファイルシステムを作成
sudo mkfs.ext4 -L data /dev/sdb1

# XFSファイルシステムを作成
sudo mkfs.xfs -L app /dev/vg_data/lv_app

# ファイルシステムの確認
sudo blkid /dev/sdb1
```

#### ステップ4: fstabエントリの追加

```bash
# UUIDを使用した設定（推奨）
# まずUUIDを確認
sudo blkid /dev/sdb1

# fstabに追加
echo "UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /data ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab

# デバイス名を使用した設定
echo "/dev/sdb1 /data ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab

# LVMボリュームの場合
echo "/dev/vg_data/lv_app /app xfs defaults,noatime,nodiratime 0 2" | sudo tee -a /etc/fstab

# tmpfsの場合
echo "tmpfs /app/tmp tmpfs size=2G,mode=1777 0 0" | sudo tee -a /etc/fstab

# バインドマウントの場合
echo "/data/shared /opt/app/shared none bind,rw 0 0" | sudo tee -a /etc/fstab
```

#### ステップ5: マウントの実行

```bash
# fstabの構文を確認
sudo mount -a -v --dry-run

# すべてのfstabエントリをマウント
sudo mount -a

# 特定のマウントポイントのみマウント
sudo mount /data

# マウント状態を確認
mount | grep /data
df -h /data
```

## 運用管理

### 基本操作

マウント状態の確認：
```bash
# すべてのマウントポイント
mount | column -t

# 特定のマウントポイント
mount | grep /data

# ディスク使用量を含む情報
df -hT

# マウントオプションの詳細
findmnt -t ext4,xfs
```

マウント/アンマウント操作：
```bash
# マウント
sudo mount /data

# アンマウント
sudo umount /data

# 強制アンマウント（使用中の場合）
sudo umount -l /data  # lazy unmount
sudo umount -f /data  # force unmount

# 再マウント（オプション変更時）
sudo mount -o remount,ro /data
```

### ログとモニタリング

```bash
# マウント関連のログ
sudo journalctl -xe | grep -i mount
sudo dmesg | grep -i mount

# ファイルシステムエラーの確認
sudo dmesg | grep -i "fs error"

# I/O統計の監視
iostat -x 1
iotop
```

### トラブルシューティング

#### 診断フロー

1. マウント状態の確認
   ```bash
   mount | grep /data
   systemctl status $(systemd-escape -p /data).mount
   ```

2. デバイスの可用性確認
   ```bash
   lsblk
   ls -la /dev/disk/by-uuid/
   ```

3. ファイルシステムの整合性確認
   ```bash
   sudo umount /data
   sudo fsck -n /dev/sdb1  # 読み取り専用チェック
   ```

#### よくある問題と対処方法

- **問題**: "mount: wrong fs type, bad option, bad superblock"
  - **対処**: ファイルシステムタイプを確認、必要なカーネルモジュールをロード

- **問題**: "mount: /data: device is busy"
  - **対処**: `lsof /data`で使用中のプロセスを確認し、停止してから再試行

- **問題**: 起動時にマウントが失敗する
  - **対処**: fstabオプションに`nofail`を追加、または`x-systemd.device-timeout`を設定

### メンテナンス

ファイルシステムチェック：
```bash
# アンマウントしてチェック
sudo umount /data
sudo fsck -y /dev/sdb1

# 次回起動時に強制チェック
sudo tune2fs -C 50 /dev/sdb1  # マウント回数を設定
sudo touch /forcefsck  # 次回起動時に全FSをチェック
```

パフォーマンスチューニング：
```bash
# ext4の予約ブロックを調整
sudo tune2fs -m 1 /dev/sdb1

# マウントオプションの最適化
sudo mount -o remount,noatime,nodiratime /data
```

## アンインストール（手動）

マウントを削除する手順：

```bash
# 1. アンマウント
sudo umount /data

# 2. fstabエントリを削除
sudo sed -i '/\/data/d' /etc/fstab

# または手動で編集
sudo nano /etc/fstab
# 該当行を削除

# 3. マウントポイントディレクトリを削除（オプション）
sudo rmdir /data  # 空の場合のみ
# または
sudo rm -rf /data  # 注意：データも削除される

# 4. 設定の確認
cat /etc/fstab
mount | grep /data
```

## 注意事項

- fstabの編集ミスはシステムの起動に影響する可能性があります
- 本番環境では変更前に必ずfstabのバックアップを作成してください
- `mount -a`実行前に`--dry-run`オプションで確認することを推奨
- ネットワークファイルシステムには`_netdev`オプションを追加してください
- 重要なデータは定期的にバックアップを取得してください