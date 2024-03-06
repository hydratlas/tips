# debootstrapでインストール
debootstrapでDebianをインストールすると、vmlinuzおよびinitrd.imgのシンボリックリンクが、/bootではなく/に作られる。

## ツールのセットアップ
### ダウンロード
```
cd ~/ &&
git clone --depth=1 git@github.com:hydratlas/tips.git &&
cd tips/debian-and-ubuntu-tips/debootstrap
```

### ハッシュ化されたパスワードの生成
```
openssl passwd -6 "newuser"
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
sudo bash -eux install1.sh <distribution> <hostname> https://github.com/<username>.keys <sdX> <sdX>
sudo bash -eux install2.sh <distribution> <hostname> https://github.com/<username>.keys <sdX> <sdX>
sudo bash -eux install3-setup-grub.sh             <distribution> <hostname> https://github.com/<username>.keys <sdX> <sdX>
sudo bash -eux install3-setup-ssh-server.sh       <distribution> <hostname> https://github.com/<username>.keys <sdX> <sdX>
sudo bash -eux install3-setup-systemd-networkd.sh <distribution> <hostname> https://github.com/<username>.keys <sdX> <sdX>
```

## トラブルシューティング
### インストールされたパッケージの確認
```
sudo arch-chroot /mnt dpkg --get-selections | grep -v deinstall | awk '{print$1}'
```

### パッケージの検索
```
apt-cache search --names-only linux-image
```

### パッケージの依存関係の確認
```
sudo arch-chroot /mnt apt-cache depends <name>
sudo arch-chroot /mnt apt-cache rdepends <name>
```

### debconfの確認
```
cat /mnt/var/cache/debconf/config.dat
```

### EFIシステムパーティションの確認
```
ls -la /mnt/boot/efi/EFI
ls -la /mnt/boot/efi2/EFI
```
efi2/EFIはdebianの場合は空である。

### NVRAMに保存されたブートエントリーの確認
```
sudo efibootmgr -v
```

### NVRAMに保存されたブートエントリーを削除
```
sudo efibootmgr -b 1234 -B
```

### debootstrap実行直後に戻す（Btrfsの場合のみ）
```
sudo umount -R /mnt

sudo mount -o subvolid=5 /dev/<sdXY> /mnt &&
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
cd tips/tips/debian-and-ubuntu-tips/debootstrap &&
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
  bzip2 curl gdisk git make perl rsync wget \
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

### 2つ目のEFIシステムパーティションにブートローダーをインストール（Debian）（未検証）
KVM上でなぜかブートせず、動作を検証できていない。
```
EFI_PATH="/boot/efi2" &&
DISTRIBUTOR="$(lsb_release -i -s 2> /dev/null || echo Debian)" &&
ROOT_UUID="$(findmnt --target / --output UUID --noheadings)" &&
sudo apt-get install -y --no-install-recommends wget unzip efibootmgr &&
wget -O "refind.zip" https://sourceforge.net/projects/refind/files/latest/download &&
unzip "refind.zip" -d refind &&
cd refind/refind-bin-*/refind &&
sudo mkdir -p "${EFI_PATH}/EFI/BOOT/drivers_x64" &&
sudo cp refind_x64.efi "${EFI_PATH}/EFI/BOOT/bootx64.efi" &&
sudo cp drivers_x64/btrfs_x64.efi "${EFI_PATH}/EFI/BOOT/drivers_x64/btrfs_x64.efi" &&
sudo tee "${EFI_PATH}/EFI/BOOT/refind.conf" <<- EOS > /dev/null &&
timeout 2
use_nvram false
textonly
scanfor internal,external,optical,manual
menuentry "${DISTRIBUTOR}" {
  volume   "${DISTRIBUTOR}"
  loader   /@/vmlinuz-linux
  initrd   /@/initrd.img
  options "root=UUID=${ROOT_UUID} ro rootflags=subvol=@"
  submenuentry "rootflags=degraded" {
    options "root=UUID=${ROOT_UUID} ro rootflags=subvol=@,degraded"
  }
}
EOS
cat "${EFI_PATH}/EFI/BOOT/refind.conf" && # confirmation
ESP_DEV="$(findmnt --target "${EFI_PATH}" --output SOURCE --noheadings)" &&
ESP_DISK="${ESP_DEV:0:-1}" &&
ESP_PART="${ESP_DEV: -1}" && # A space is required before the minus sign.
sudo efibootmgr -q --create --disk "${ESP_DISK}" --part "${ESP_PART}" \
  --loader /EFI/BOOT/bootx64.efi --label "${DISTRIBUTOR} (rEFInd Boot Manager)" --unicode &&
sudo efibootmgr -v
```
