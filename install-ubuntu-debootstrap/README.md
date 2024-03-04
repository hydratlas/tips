# install-ubuntu-debootstrap
## ツールのセットアップ
### ダウンロード
```
cd ~/ &&
git clone --depth=1 https://github.com/hydratlas/tips &&
cd tips/install-ubuntu-debootstrap &&
chmod a+x install*.sh &&
mv install-config.sample.sh install-config.sh
```

### ハッシュ化されたパスワードの生成
```
openssl passwd -6 "ubuntu"
```

### 設定の変更
```
nano install-config.sh
```

## インストール
### インストールするストレージの特定
```
lsblk -f -e 7
```

### インストール
「lsblk」によって、インストール先のsdXを確認し、次のコマンドの1個目および2個目の引数に指定する。
```
sudo bash -eux install1.sh <hostname> https://github.com/<username>.keys <sdX> <sdX>
sudo bash -eux install2.sh <hostname> https://github.com/<username>.keys <sdX> <sdX>
```

### インストールされたパッケージの確認
```
sudo arch-chroot /mnt dpkg --get-selections | grep -v deinstall | awk '{print$1}'
```

### debconfの確認
```
cat /mnt/var/cache/debconf/config.dat
```

### debootstrap実行直後に戻す（Btrfsの場合のみ）
```
sudo umount -R /mnt

sudo mount -o subvolid=5 /dev/<sdX0> /mnt &&
sudo btrfs subvolume set-default /mnt &&
sudo btrfs subvolume delete /mnt/@ &&
sudo btrfs subvolume snapshot /mnt/@snapshots/after-installation /mnt/@ &&
sudo btrfs subvolume set-default /mnt/@ &&
sudo umount /mnt

sudo bash -eux install-mount.sh sdX sdX
```

## 後処理
### ツールの削除
```
cd ~/ &&
rm -drf tips
```

### debootstrap実行直後のスナップショットを削除（Btrfsの場合のみ）
```
sudo btrfs subvolume delete /mnt/.snapshots/after-installation
```

### アンマウント
再起動するなら飛ばしてよい。
```
sudo umount -R /mnt
```

### 再起動
```
sudo shutdown -r now
```

### 再起動後に再度マウント
```
cd tips/install-ubuntu-debootstrap &&
sudo bash -eux install-mount.sh <sdX> <sdX>
```

## その他、起動後の追加設定（オプション）
### パッケージのアップデート通知
SSHログイン時のメッセージ(MOTD)でパッケージのアップデート通知を表示する。MOTDの仕組み上、システム全体のロケールでメッセージが生成されるようである。これをインストールすると依存関係でubuntu-advantage-toolsもインストールされる。ubuntu-advantage-toolsはUbuntu Proの広告という側面もある。
```
sudo apt-get install -y --no-install-recommends update-notifier-common
```

### 各種ツールのインストール
```
sudo apt-get install -y --no-install-recommends \
  bzip2 curl gdisk git make nano perl rsync wget \
  htop lshw lsof mc moreutils psmisc time uuid-runtime zstd
```
- htop: htop
- lshw: lshw
- lsof: lsof
- mc: Midnight Commander (file manager)
- moreutils: Unix tools
- psmisc: killall
- time: time
- uuid-runtime: uuidgen
- zstd: zstd
