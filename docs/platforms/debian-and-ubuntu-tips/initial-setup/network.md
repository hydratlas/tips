# ネットワーク周り（すべて管理者）
## mDNSのインストール
LAN内にDNSサーバーがない場合、mDNSをインストールすると「ホスト名.local」でSSH接続できるようになる。mDNSがインストールされていない場合は以下でインストールできる。
```sh
sudo apt-get install --no-install-recommends -y avahi-daemon
```

## systemd-timesyncdによるNTP (Network Time Protocol)の設定
### 状況確認
```sh
systemctl status systemd-timesyncd.service
```

### NTPサーバーを最適化
```sh
sudo perl -pi -e 's/^NTP=.+$/NTP=time.cloudflare.com ntp.jst.mfeed.ad.jp time.windows.com/g' '/etc/systemd/timesyncd.conf'
```

### systemd-timesyncdの無効化
仮想マシンのゲストの場合は、ホストで時計合わせをするため無効にする。
```sh
sudo systemctl disable --now systemd-timesyncd.service
```

## NetworkManagerをコマンドで変更
### 現在のコネクションを確認
```sh
nmcli connection show
```

### 現在のIPアドレス設定を確認
```sh
nmcli connection show "Wired connection 1"
```

### IPアドレスを変更
```sh
sudo nmcli connection modify "Wired connection 1" ipv4.addresses "xxx.xxx.xxx.xxx/24, xxx.xxx.xxx.xxx/24"
```

### 再起動
```sh
sudo reboot
```
