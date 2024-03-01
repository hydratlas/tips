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
sudo bash -eux install.sh ubuntu-machine https://github.com/<username>.keys sdX sdX
```

### インストールされたパッケージの確認
```
sudo arch-chroot /mnt dpkg --get-selections | grep -v deinstall | awk '{print$1}'
```

### debootstrap実行直後に戻す
```
sudo umount -R /mnt

sudo mount -o subvolid=5 /dev/sdX3 /mnt &&
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
sudo bash -eux install-mount.sh sdX sdX
```
