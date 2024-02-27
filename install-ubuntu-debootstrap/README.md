```
wget https://raw.githubusercontent.com/hydratlas/tips/main/install-ubuntu-debootstrap/install.sh
chmod a+x install.sh
lsblk -f -e 7 # インストール先のsdXがなにかを確認し、1個目および2個目の引数に指定する
sudo bash -x install.sh sdX sdX
sudo shutdown -r now
```
