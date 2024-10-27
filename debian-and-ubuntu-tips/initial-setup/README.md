# 初期設定
## キーボード配列を日本語にする（管理者）
```bash
sudo perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"pc105\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"jp\"/g" "/etc/default/keyboard" &&
sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration
```

## ロケールをシステム全体ではC.UTF-8にした上で、ユーザー個別ではja_JP.UTF-8に設定可能にする（管理者）
```bash
sudo perl -p -i -e "s/^#? *C.UTF-8/C.UTF-8/g;s/^#? *ja_JP.UTF-8/ja_JP.UTF-8/g" "/etc/locale.gen" &&
sudo locale-gen &&
sudo localectl set-locale LANG=C.UTF-8 &&
sudo dpkg-reconfigure --frontend noninteractive locales
```

### 補足
「localectl set-locale」に代えて、/etc/default/localeに書き込んでもよい（おそらくlocalectlはこの処理のラッパーとなっている）。
```bash
sudo tee "/etc/default/locale" <<< "LANG=C.UTF-8" > /dev/null

cat "/etc/default/locale" # confirmation
```

## ロケールをログインしているユーザー個別でja_JP.UTF-8に設定する（各ユーザー）
```bash
tee -a "~/.bashrc" << "export LANG=ja_JP.UTF-8" > /dev/null &&
source ~/.bashrc
```

## タイムゾーンをAsia/Tokyoにする（管理者）
```bash
sudo timedatectl set-timezone Asia/Tokyo &&
sudo dpkg-reconfigure --frontend noninteractive tzdata

timedatectl status # confirmation
```

### 補足
設定の場所は3つある。
```bash
sudo tee "/etc/timezone" <<< "Asia/Tokyo" > /dev/null
cat "/etc/timezone" # confirmation

sudo ln -sf "/usr/share/zoneinfo/Asia/Tokyo" "/etc/localtime"
readlink "/etc/localtime" # confirmation

sudo debconf-set-selections <<< "tzdata tzdata/Areas select Asia" &&
sudo debconf-set-selections <<< "tzdata tzdata/Zones/Asia select Tokyo"
```
このうち、「dpkg-reconfigure tzdata」の実行時に参照されているのは「/etc/localtime」だけである。そして、「timedatectl set-timezone」は「/etc/localtime」を書き換える。その上で「dpkg-reconfigure tzdata」を実行すれば、「/etc/timezone」を書き換えてくれる。

## 管理者ユーザーを追加（管理者）
```bash
sudo useradd -u <uid> -U -G adm,cdrom,sudo,dip,plugdev,lpadmin,sambashare,root \
  -p "$(openssl passwd -6 "<password>")" -s /bin/bash -m <username>
```

## ユーザー・グループを削除（管理者）
```bash
sudo userdel -r <username> # rオプションでホームディレクトリーも削除

sudo groupdel <username>
```

## sudoをパスワードなしで使えるようにする（管理者）
テスト機でのみ実施すること。
```bash
sudo tee "/etc/sudoers.d/90-adm" <<< "%sudo ALL=(ALL) NOPASSWD: ALL" > /dev/null
```

## Nanoをインストールする（管理者）
```bash
sudo apt-get install --no-install-recommends -y nano
```
