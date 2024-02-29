# install-ubuntu-debootstrap
## 準備
```
cd ~/ &&
git clone --depth=1 https://github.com/hydratlas/tips &&
cd tips/install-ubuntu-debootstrap &&
chmod a+x install*.sh
```

## インストール
「lsblk」によって、インストール先のsdXを確認し、次のコマンドの1個目および2個目の引数に指定する。
```
lsblk -f -e 7

sudo bash -eux install.sh ubuntu-machine https://github.com/<username>.keys sdX sdX
```

## トラブルシューティング
### ツールの削除・アンマウント
```
cd ~/ &&
rm -drf tips &&
sudo umount -r /mnt
```

### マウント
```
lsblk -f -e 7

sudo bash -eux install-mount.sh sdX sdX

sudo apt install -y arch-install-scripts &&
sudo arch-chroot /mnt
```

## 再起動
```
sudo shutdown -r now
```
