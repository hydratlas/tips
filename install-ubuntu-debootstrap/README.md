```
git clone --depth=1 https://github.com/hydratlas/tips
cd tips/install-ubuntu-debootstrap
chmod a+x install*.sh
lsblk -f -e 7 # インストール先のsdXがなにかを確認し、1個目および2個目の引数に指定する
sudo bash -eux install.sh ubuntu-machine https://github.com/<username>.keys sdX sdX
sudo shutdown -r now
```
