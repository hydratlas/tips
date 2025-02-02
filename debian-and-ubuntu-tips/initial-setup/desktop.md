# デスクトップ（Ubuntu）を設定
## 各種アプリをインストール（管理者）
```sh
sudo apt install -y meld inkscape dconf-editor grsync nautilus-image-converter keepassxc transmission-gtk &&
sudo apt install -y libreoffice libreoffice-l10n-ja &&
sudo snap install chromium gimp discord &&
sudo snap install codium --classic
```

## 各ディレクトリを英語化（各ユーザー）
```sh
LC_ALL=C xdg-user-dirs-gtk-update --force
```

## dash-to-dockの設定（各ユーザー）
```sh
gsettings set org.gnome.shell.extensions.dash-to-dock click-action 'minimize-or-previews'
  # クリックしたとき、現在表示中であれば最小化、表示中でなければプレビュー
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false # ドックにマウントドライブを表示しない
gsettings set org.gnome.shell.extensions.dash-to-dock show-ttash false # ドックにゴミ箱を表示しない
```

## desktopの設定（各ユーザー）
```sh
gsettings set org.gnome.desktop.screensaver lock-enabled false # スクリーンセーバー復帰後にロックしない
gsettings set org.gnome.desktop.interface clock-show-weekday true # 日付に曜日を表示
gsettings set org.gnome.desktop.input-sources mru-sources "[('ibus', 'mozc-jp'), ('xkb', 'jp')]" # mozcを優先
```

## nautilusの設定（各ユーザー）
```sh
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' # リストビュー表示
gsettings set org.gnome.nautilus.preferences search-view 'list-view' # リストビュー表示
gsettings set org.gnome.nautilus.list-view default-zoom-level 'small' # ファイルリストを小さく表示
gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'detailed_type', 'size', 'date_modified_with_time', 'owner', 'group', 'permissions']" # アクセス権などを表示
```

## geditの設定（各ユーザー）
```sh
gsettings set org.gnome.gedit.preferences.editor display-line-numbers true # 行番号表示
gsettings set org.gnome.gedit.preferences.print print-font-body-pango 'Monospace 11' # フォント変更
gsettings set org.gnome.gedit.preferences.print print-font-header-pango 'Monospace 11' # フォント変更
gsettings set org.gnome.gedit.preferences.print print-font-numbers-pango 'Monospace 11' # フォント変更
gsettings set org.gnome.gedit.preferences.print print-header false # ヘッダーを印刷しない
```

## Zedのインストール（各ユーザー）
```sh
wget -q -O - https://zed.dev/install.sh | sh 
```

設定に以下の行を追加する。
```json
  "buffer_font_family": "Noto Sans Mono CJK JP",
  "autosave": {
    "after_delay": {
      "milliseconds": 1000
    }
  },
```

## Geanyのインストール（管理者）
```sh
sudo apt install -yq geany
```

## Geanyの設定（各ユーザー）
```sh
mkdir "$HOME/.config/geany" &&
cat << EOF > "$HOME/.config/geany/geany.conf"
[geany]
pref_main_load_session=false
show_white_space=true
show_line_endings=true
sidebar_visible=false
msgwindow_visible=false

[search]
replace_regexp=true
EOF
```

## AppImage
### AppImageLauncherのインストール（管理者）
まず必要なパッケージをインストールする。
```sh
sudo apt install -y libfuse2t64
```

その上で[Releases · TheAssassin/AppImageLauncher](https://github.com/TheAssassin/AppImageLauncher/releases)からdebをダウンロードする（Ubuntu 24.04ではPPAが動かない）。そしてアプリセンターで開いてインストールする。

### Joplinの修正（各ユーザー）
JoplinのAppImageをAppImageLauncherからインストールして、アイコンファイルの指定が間違っている点を修正する。
```sh
find "$HOME/.local/share/applications" -name "*-Joplin.desktop" -exec perl -i -pe "s/^(Icon=.+)_joplin\$/\$1_\\@joplinapp-desktop/g" "{}" \;
```

### アイコン修正一般（各ユーザー）
AppImageLauncherが生成するdesktopファイルでStartupWMClassがないか、適切に設定されていないために、Dash to Dockでアイコンが表示されないことがある。

まずxpropコマンドでWM Classを調べる。
```sh
xprop WM_CLASS
```

その上で、desktopファイルを探す。
```sh
cd "$HOME/.local/share/applications" &&
ls -la
```

開いて、編集する（DB Browser for SQLiteの場合）。
```sh
nano appimagekit_dc17fe06dff3ad37a6b1ca1900ec4a18-DB_Browser_for_SQLite.desktop
```
```
[Desktop Entry]
...
StartupWMClass=DB Browser for SQLite
```

開いて、編集する（PhotoQtの場合）。
```sh
nano appimagekit_a804665a6765821784bd9f1084748dbf-PhotoQt.desktop
```
```
[Desktop Entry]
...
StartupWMClass=PhotoQt
```

## Rcloneのインストール（管理者）
```sh
wget -O rclone.deb https://downloads.rclone.org/rclone-current-linux-amd64.deb &&
sudo dpkg -i rclone.deb &&
rm rclone.deb
```

## Flatpakのインストール（管理者）
```sh
sudo apt-get install --no-install-recommends -y flatpak
```

## Flatpakでアプリケーションをインストール（各ユーザー）
```sh
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

## Remmina
「設定」→「RDP」→「キーボードレイアウト」に「00000411 – Japanese」を設定する。

## Firefox
```sh
wget -O firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=ja" &&
sudo tar -xjf firefox.tar.bz2 -C /opt/ &&
rm firefox.tar.bz2 &&
sudo tee "/usr/share/applications/firefox-mozilla.desktop" > /dev/null << EOS
[Desktop Entry]
Name=Firefox (Mozilla)
Exec=/opt/firefox/firefox
StartupWMClass=firefox
Terminal=false
Type=Application
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
EOS
```
 