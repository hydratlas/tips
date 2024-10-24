# 初期設定
## 次回起動時にUEFI設定画面を表示する（管理者）
```bash
sudo systemctl reboot --firmware-setup
```

## GRUBの待ち時間をなくす（管理者）
```bash
sudo tee -a "/etc/default/grub" <<< "GRUB_RECORDFAIL_TIMEOUT=0" > /dev/null
```

## ノートパソコンのふたをしめてもサスペンドしないようにする（管理者）
```bash
sudo perl -p -i -e 's/^#?HandleLidSwitch=.+$/HandleLidSwitch=ignore/g;' /etc/systemd/logind.conf &&
sudo systemctl restart systemd-logind.service
```

## SSHサーバーのインストールと設定（管理者）
```bash
sudo apt-get install --no-install-recommends -y openssh-server &&
sudo mkdir -p "/etc/ssh/sshd_config.d" &&
sudo tee "/etc/ssh/sshd_config.d/90-local.conf" << EOS > /dev/null
PasswordAuthentication no
PermitRootLogin no
EOS
```
パスワードによるログイン、rootユーザーでのログインを禁止する設定。

## SSHサーバーの古い方式の禁止（管理者）
Includeで/etc/ssh/sshd_config.d/*.confが読み込まれているか確認。
```bash
grep -i Include /etc/ssh/sshd_config
```

読み込まれていないなら読み込むように追記。
```bash
sudo tee -a "/etc/ssh/sshd_config" <<< "Include /etc/ssh/sshd_config.d/*.conf" > /dev/null
```

```bash
sudo tee "/etc/ssh/sshd_config.d/91-local.conf" << EOS > /dev/null
Ciphers -*-cbc
KexAlgorithms -*-sha1
PubkeyAcceptedKeyTypes -ssh-rsa*,ssh-dss*
EOS

sudo sshd -T | grep -i -e PasswordAuthentication -e PermitRootLogin

sudo sshd -T | grep -i -e Ciphers -e MACs -e PubkeyAcceptedKeyTypes -e PubkeyAcceptedAlgorithms -e KexAlgorithms
```
古いタイプの方式を禁止する設定。PubkeyAcceptedKeyTypesはOpenSSH 8.5からPubkeyAcceptedAlgorithmsに名前が変わっている。Ubuntu 20.04は8.2、22.04は8.9。OpenSSH 8.5以降でもPubkeyAcceptedKeyTypesによる禁止設定は効果がある。

## mDNSのインストール（管理者）
LAN内にDNSサーバーがない場合、mDNSをインストールすると「ホスト名.local」でSSH接続できるようになる。mDNSがインストールされていない場合は以下でインストールできる。
```bash
sudo apt-get install --no-install-recommends -y avahi-daemon
```

## キーボード配列を日本語にする（管理者）
```bash
sudo perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"pc105\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"jp\"/g" "/etc/default/keyboard" &&
sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration
```

## ロケールをシステム全体ではC.UTF-8にした上で、ユーザー個別ではja_JP.UTF-8に設定可能にする（管理者）
```bash
sudo perl -p -i -e "s/^#? *C.UTF-8/C.UTF-8/g;s/^#? *ja_JP.UTF-8/ja_JP.UTF-8/g" "/etc/locale.gen" && sudo locale-gen &&
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

## systemd-timesyncdによるNTP (Network Time Protocol)の設定（管理者）
### 状況確認
```bash
systemctl status systemd-timesyncd.service
```

### NTPサーバーを最適化する
```bash
sudo perl -p -i -e 's/^NTP=.+$/NTP=time.cloudflare.com ntp.jst.mfeed.ad.jp time.windows.com/g' '/etc/systemd/timesyncd.conf'
```

### systemd-timesyncdを無効にする
仮想マシンのゲストの場合は、ホストで時計合わせをするため無効にする。
```bash
sudo systemctl disable --now systemd-timesyncd.service
```

## QEMUゲストエージェントをインストールする（管理者）
QEMU＝仮想マシンで、仮想マシンのゲストの場合にはインストールする。
```bash
sudo apt-get install --no-install-recommends -y qemu-guest-agent
```

## Nanoをインストールする（管理者）
```bash
sudo apt-get install --no-install-recommends -y nano
```

## sudoをパスワードなしで使えるようにする（管理者）
テスト機でのみ実施すること。
```bash
sudo tee "/etc/sudoers.d/90-adm" <<< "%sudo ALL=(ALL) NOPASSWD: ALL" > /dev/null
```

## SSHキーを生成（各ユーザー）
```bash
ssh-keygen -t rsa   -b 4096 -N '' -C '' -f "$HOME/.ssh/id_rsa" &&
ssh-keygen -t ecdsa  -b 521 -N '' -C '' -f "$HOME/.ssh/id_ecdsa" &&
ssh-keygen -t ed25519       -N '' -C '' -f "$HOME/.ssh/id_ed25519"
```

## Flatpakをインストール（管理者）
```bash
sudo apt-get install --no-install-recommends -y flatpak
```

## Flatpakでアプリケーションをインストール（各ユーザー）
```bash
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub org.gnome.TextEditor
```

## GUIアプリケーションのインストール
|Deb (Debian/Ubuntu)|Flathub|Snapcraft|
|:----|:----|:----|
|baobab|org.gnome.baobab| |
|celluloid|io.github.celluloid_player.Celluloid|celluloid|
|deja-dup|org.gnome.DejaDup| |
|evince|org.gnome.Evince|evince|
|font-viewer|org.gnome.font-viewer| |
|gimp|org.gimp.GIMP|gimp|
|gnome-calculator|org.gnome.Calculator|gnome-calculator|
|gnome-characters|org.gnome.Characters|gnome-characters|
|gnome-clocks|org.gnome.clocks|gnome-clocks|
|gnome-logs|org.gnome.Logs| |
|gnome-text-editor|org.gnome.TextEditor| |
|inkscape|org.inkscape.Inkscape|inkscape|
|libreoffice|org.libreoffice.LibreOffice|libreoffice|
|loupe|org.gnome.Loupe|loupe|
|meld|org.gnome.meld| |
|nemo-fileroller|org.gnome.FileRoller| |
|photoqt|org.photoqt.PhotoQt| |
|simple-scan|org.gnome.SimpleScan| |
|transmission|com.transmissionbt.Transmission|transmission|
|vlc|org.videolan.VLC|vlc|
| |com.discordapp.Discord|discord|
| |com.github.Eloston.UngoogledChromium|chromium|
| |com.vscodium.codium|codium|
| |io.dbeaver.DBeaverCommunity|dbeaver-ce|
| |md.obsidian.Obsidian|obsidian|
| |org.mozilla.firefox|firefox|
| |org.zotero.Zotero|zotero-snap|
| |us.zoom.Zoom|zoom-client|
