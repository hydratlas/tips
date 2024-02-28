# install-ubuntu-debootstrap
## 準備
```
git clone --depth=1 https://github.com/hydratlas/tips
cd tips/install-ubuntu-debootstrap
chmod a+x install*.sh
lsblk -f -e 7
```
「lsblk」によって、インストール先のsdXを確認し、次のコマンドの1個目および2個目の引数に指定する。

## インストール・再起動
```
sudo bash -eux install.sh ubuntu-machine https://github.com/<username>.keys sdX sdX
sudo shutdown -r now
```

## 再マウントによるトラブルシューティング
```
sudo bash -eux install-mount.sh sdX sdX
sudo apt install -y arch-install-scripts
sudo arch-chroot /mnt
```
