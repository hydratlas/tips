# 初期設定
## ノートパソコンのふたをしめてもサスペンドしないようにする（管理者）
```
sudo perl -p -i -e 's/^#?HandleLidSwitch=.+$/HandleLidSwitch=ignore/g;' /etc/systemd/logind.conf &&
sudo systemctl restart systemd-logind.service
```

## キーボード配列を日本語109にする（管理者）
```
sudo perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"pc105\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"jp\"/g;s/^XKBVARIANT=.+\$/XKBVARIANT=\"OADG109A\"/g" "/etc/default/keyboard" &&
sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration
```

## ロケールをシステム全体ではC.UTF-8にした上で、ユーザー個別ではja_JP.UTF-8に設定可能にする（管理者）
```
sudo apt-get install -y language-pack-ja &&
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

## NTP (Network Time Protocol)の設定
```
sudo perl -p -i -e 's/^NTP=.+$/NTP=time.cloudflare.com ntp.jst.mfeed.ad.jp time.windows.com/g' '/etc/systemd/timesyncd.conf'
```

## QEMUゲストエージェントをインストールする（QEMU＝仮想マシン）
```
apt-get install -y --no-install-recommends qemu-guest-agent
```

## sudoをパスワードなしで使えるようにする（テスト機のみ）
```
sudo tee "/etc/sudoers.d/90-adm" <<< "%sudo ALL=(ALL) NOPASSWD: ALL" > /dev/null
```

## aptの取得先にミラーを設定する
### Ubuntu
#### Deb822-style Format
新しいDeb822-style Formatに対応している場合。
```
sudo tee "/etc/apt/sources.list.d/ubuntu.sources" <<- EOS > /dev/null &&
Types: deb
URIs: mirror+file:/etc/apt/ubuntu-mirrors.txt
Suites: $(lsb_release --short --codename) $(lsb_release --short --codename)-updates $(lsb_release --short --codename)-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu
Suites: $(lsb_release --short --codename)-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOS
cat "/etc/apt/sources.list.d/ubuntu.sources" && # confirmation
sudo tee "/etc/apt/ubuntu-mirrors.txt" <<- EOS > /dev/null &&
http://ftp.udx.icscoe.jp/Linux/ubuntu	priority:1
https://linux.yz.yamagata-u.ac.jp/ubuntu	priority:2
http://jp.archive.ubuntu.com/ubuntu
EOS
cat "/etc/apt/ubuntu-mirrors.txt" && # confirmation
if [ -f "/etc/apt/sources.list" ]; then
  sudo rm -f "/etc/apt/sources.list"
fi
sudo apt-get update
```

#### One-Line-Style Format
新しいDeb822-style Formatに対応していない場合。
```
sudo tee "/etc/apt/sources.list" <<- EOS > /dev/null &&
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename) main restricted universe multiverse
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename)-updates main restricted universe multiverse
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename)-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $(lsb_release --short --codename)-security main restricted universe multiverse
EOS
cat "/etc/apt/sources.list" && # confirmation
sudo tee "/etc/apt/mirrors.txt" <<- EOS > /dev/null &&
http://ftp.udx.icscoe.jp/Linux/ubuntu	priority:1
https://linux.yz.yamagata-u.ac.jp/ubuntu	priority:2
http://jp.archive.ubuntu.com/ubuntu
EOS
cat "/etc/apt/mirrors.txt" && # confirmation
sudo apt-get update
```

### Debian
#### Deb822-style Format
新しいDeb822-style Formatに対応している場合。
```
sudo tee "/etc/apt/sources.list.d/debian.sources" <<- EOS > /dev/null &&
Types: deb
URIs: mirror+file:/etc/apt/debian-mirrors.txt
Suites: $(lsb_release --short --codename) $(lsb_release --short --codename)-updates $(lsb_release --short --codename)-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: $(lsb_release --short --codename)-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOS
cat "/etc/apt/sources.list.d/debian.sources" && # confirmation
sudo tee "/etc/apt/debian-mirrors.txt" <<- EOS > /dev/null &&
http://ftp.jp.debian.org/debian	priority:1
https://debian-mirror.sakura.ne.jp/debian	priority:2
http://cdn.debian.or.jp/debian
EOS
cat "/etc/apt/debian-mirrors.txt" && # confirmation
if [ -f "/etc/apt/sources.list" ]; then
  sudo rm -f "/etc/apt/sources.list"
fi
sudo apt-get update
```

#### One-Line-Style Format
新しいDeb822-style Formatに対応していない場合。
```
sudo tee "/etc/apt/sources.list" <<- EOS > /dev/null &&
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename) main contrib non-free non-free-firmware
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename)-updates main contrib non-free non-free-firmware
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename)-backports main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $(lsb_release --short --codename)-security main contrib non-free non-free-firmware
EOS
cat "/etc/apt/sources.list" && # confirmation
sudo tee "/etc/apt/mirrors.txt" <<- EOS > /dev/null &&
http://ftp.jp.debian.org/debian	priority:1
https://debian-mirror.sakura.ne.jp/debian	priority:2
http://cdn.debian.or.jp/debian
EOS
cat "/etc/apt/mirrors.txt" && # confirmation
sudo apt-get update
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

## Cockpitをインストール（管理者）
### Cockpitをインストール
cockpit-pcpはメトリクスを収集・分析してくれるが、負荷がかかるので不要ならインストールしない。

#### 通常版
```
sudo apt-get install --no-install-recommends -y \
  cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-packagekit \
  cockpit-pcp
```

#### バックポート版（新しい）
```
sudo apt-get install --no-install-recommends -y -t "$(lsb_release --short --codename)-backports" \
  cockpit cockpit-ws cockpit-system cockpit-storaged cockpit-packagekit \
  cockpit-pcp
```

### Cockpitを起動
```
sudo systemctl enable --now cockpit.socket

# http://xxx.local:9090
```

## SSHキーを生成（ユーザー）
```
ssh-keygen -t rsa   -b 4096 -N '' -C '' -f "$HOME/.ssh/id_rsa"
ssh-keygen -t ecdsa  -b 521 -N '' -C '' -f "$HOME/.ssh/id_ecdsa"
ssh-keygen -t ed25519       -N '' -C '' -f "$HOME/.ssh/id_ed25519"
```
