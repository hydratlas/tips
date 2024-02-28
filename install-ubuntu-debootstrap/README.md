```
wget https://raw.githubusercontent.com/hydratlas/tips/main/install-ubuntu-debootstrap/install.sh
wget https://raw.githubusercontent.com/hydratlas/tips/main/install-ubuntu-debootstrap/install.conf
chmod a+x install.sh
chmod a+x install.conf
lsblk -f -e 7 # インストール先のsdXがなにかを確認し、1個目および2個目の引数に指定する
nano install.conf
sudo bash -eux install.sh sdX sdX
sudo shutdown -r now
```
