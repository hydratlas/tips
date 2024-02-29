# install-ubuntu-debootstrap
## ツールの配置
```
cd ~/ &&
git clone --depth=1 https://github.com/hydratlas/tips &&
cd tips/install-ubuntu-debootstrap &&
chmod a+x install*.sh
lsblk -f -e 7

```

## インストール
「lsblk」によって、インストール先のsdXを確認し、次のコマンドの1個目および2個目の引数に指定する。
```
sudo bash -eux install.sh ubuntu-machine https://github.com/<username>.keys sdX sdX
```

### トラブルシューティング時のマウント
```
sudo bash -eux install-mount.sh sdX sdX

sudo apt install -y arch-install-scripts &&
sudo arch-chroot /mnt
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
