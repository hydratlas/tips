# ネットワーク周り
## mDNSのインストール（管理者）
LAN内にDNSサーバーがない場合、mDNSをインストールすると「ホスト名.local」でSSH接続できるようになる。mDNSがインストールされていない場合は以下でインストールできる。
```bash
sudo apt-get install --no-install-recommends -y avahi-daemon
```

## systemd-timesyncdによるNTP (Network Time Protocol)の設定（管理者）
### 状況確認
```bash
systemctl status systemd-timesyncd.service
```

### NTPサーバーを最適化
```bash
sudo perl -p -i -e 's/^NTP=.+$/NTP=time.cloudflare.com ntp.jst.mfeed.ad.jp time.windows.com/g' '/etc/systemd/timesyncd.conf'
```

### systemd-timesyncdの無効化
仮想マシンのゲストの場合は、ホストで時計合わせをするため無効にする。
```bash
sudo systemctl disable --now systemd-timesyncd.service
```
