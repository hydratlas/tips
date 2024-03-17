# 初期設定
## ノートパソコンのふたをしめてもサスペンドしないようにする（管理者）
```
sudo perl -p -i -e 's/^#?HandleLidSwitch=.+$/HandleLidSwitch=ignore/g;' /etc/systemd/logind.conf &&
sudo systemctl restart systemd-logind.service
```

## SSHサーバーのインストールと設定（管理者）
```
sudo apt-get install --no-install-recommends -y openssh-server &&
sudo tee "${MOUNT_POINT}/etc/ssh/ssh_config.d/20-local.conf" << EOS > /dev/null
PasswordAuthentication no
PermitRootLogin no
EOS
```
パスワードによるログインと、rootユーザーでのログインを禁止する設定。

## mDNSのインストール（管理者）
LAN内にDNSサーバーがない場合、mDNSをインストールすると「ホスト名.local」でSSH接続できるようになる。mDNSがインストールされていない場合は以下でインストールできる。
```
sudo apt-get install -y --no-install-recommends avahi-daemon
```

## キーボード配列を日本語109にする（管理者）
```
sudo perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"pc105\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"jp\"/g;s/^XKBVARIANT=.+\$/XKBVARIANT=\"OADG109A\"/g" "/etc/default/keyboard" &&
sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration
```

## ロケールをシステム全体ではC.UTF-8にした上で、ユーザー個別ではja_JP.UTF-8に設定可能にする（管理者）
```
sudo perl -p -i -e "s/^#? *C.UTF-8/C.UTF-8/g;s/^#? *ja_JP.UTF-8/ja_JP.UTF-8/g" "/etc/locale.gen" && sudo locale-gen &&
sudo localectl set-locale LANG=C.UTF-8 &&
sudo dpkg-reconfigure --frontend noninteractive locales
```

### 補足
「localectl set-locale」に代えて、/etc/default/localeに書き込んでもよい（おそらくlocalectlはこの処理のラッパーとなっている）。
```
echo "LANG=C.UTF-8" | sudo tee "/etc/default/locale" > /dev/null
cat "/etc/default/locale" # confirmation
```

## ロケールをログインしているユーザー個別でja_JP.UTF-8に設定する（ユーザー）
```
tee -a "~/.bashrc" << "export LANG=ja_JP.UTF-8" > /dev/null &&
source ~/.bashrc
```

## タイムゾーンをAsia/Tokyoにする（管理者）
```
sudo timedatectl set-timezone Asia/Tokyo &&
sudo dpkg-reconfigure --frontend noninteractive tzdata

timedatectl status # confirmation
```

### 補足
設定の場所は3つある。
```
echo "Asia/Tokyo" | sudo tee "/etc/timezone" > /dev/null
cat "/etc/timezone" # confirmation

sudo ln -sf "/usr/share/zoneinfo/Asia/Tokyo" "/etc/localtime"
readlink "/etc/localtime" # confirmation

echo "tzdata tzdata/Areas select Asia" | sudo debconf-set-selections &&
echo "tzdata tzdata/Zones/Asia select Tokyo" | sudo debconf-set-selections
```
このうち、「dpkg-reconfigure tzdata」の実行時に参照されているのは「/etc/localtime」だけである。そして、「timedatectl set-timezone」は「/etc/localtime」を書き換える。その上で「dpkg-reconfigure tzdata」を実行すれば、「/etc/timezone」を書き換えてくれる。

## systemd-timesyncdによるNTP (Network Time Protocol)の設定（管理者）
### NTPサーバーを最適化する（一般）
```
sudo perl -p -i -e 's/^NTP=.+$/NTP=time.cloudflare.com ntp.jst.mfeed.ad.jp time.windows.com/g' '/etc/systemd/timesyncd.conf'
```

### systemd-timesyncdを無効にする（仮想マシンゲスト）
```
sudo systemctl disable --now systemd-timesyncd.service
```

## QEMUゲストエージェントをインストールする（管理者）
QEMU＝仮想マシン。
```
sudo apt-get install -y --no-install-recommends qemu-guest-agent
```

## sudoをパスワードなしで使えるようにする（管理者）
テスト機でのみ実施すること。
```
sudo tee "/etc/sudoers.d/90-adm" <<< "%sudo ALL=(ALL) NOPASSWD: ALL" > /dev/null
```

## Flatpakをインストール（管理者）
```
sudo apt-get install --no-install-recommends -y flatpak
```

## Flatpakでアプリケーションをインストール（ユーザー）
```
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub org.gnome.TextEditor
```

## SSHキーを生成（ユーザー）
```
ssh-keygen -t rsa   -b 4096 -N '' -C '' -f "$HOME/.ssh/id_rsa"
ssh-keygen -t ecdsa  -b 521 -N '' -C '' -f "$HOME/.ssh/id_ecdsa"
ssh-keygen -t ed25519       -N '' -C '' -f "$HOME/.ssh/id_ed25519"
```
