# Btrfs関係（すべて管理者）
## スクラブ・バランスのタイマーの設定・確認
スクラブはデータの整合性をチェックする。バランスはデータの再配置を行う。ともに定期的に実行すべきもののため、Systemdのタイマーを設定する。
```
sudo apt-get install --no-install-recommends -y btrfsmaintenance &&
sudo mkdir -p /etc/systemd/system/btrfs-balance.timer.d &&
sudo mkdir -p /etc/systemd/system/btrfs-scrub.timer.d &&
sudo tee "/etc/systemd/system/btrfs-balance.timer.d/schedule.conf" << EOS > /dev/null &&
[Timer]
OnCalendar=fri
EOS
sudo tee "/etc/systemd/system/btrfs-scrub.timer.d/schedule.conf" << EOS > /dev/null &&
[Timer]
OnCalendar=sat
EOS
sudo systemctl daemon-reload &&
sudo systemctl enable --now btrfs-balance.timer &&
sudo systemctl enable --now btrfs-scrub.timer
```

確認。
```
sudo systemctl status btrfs-balance.timer
sudo systemctl status btrfs-scrub.timer
```

## Snapperのインストールと設定・確認
定期的にスナップショットを取得して、誤操作などからファイルを復旧できるようにする。この場合は`/.snapshots`にスナップショットが保存される。
```
sudo apt-get install --no-install-recommends -y snapper &&
sudo umount /.snapshots &&
sudo rm -d /.snapshots &&
sudo snapper -c root create-config / &&
sudo btrfs subvolume delete /.snapshots &&
sudo mkdir -p /.snapshots &&
sudo mount -a &&
sudo perl -p -i -e 's/^TIMELINE_LIMIT_YEARLY=.+$/TIMELINE_LIMIT_YEARLY="0"/g;' /etc/snapper/configs/root &&
sudo systemctl enable --now snapper-timeline.timer &&
sudo systemctl enable --now snapper-cleanup.timer
```

/homeディレクトリーでもスナップショットを保存する場合の追加設定。この場合は`/home/.snapshots`にスナップショットが保存される。
```
sudo snapper -c home create-config /home &&
sudo perl -p -i -e 's/^TIMELINE_LIMIT_YEARLY=.+$/TIMELINE_LIMIT_YEARLY="0"/g;' /etc/snapper/configs/home
```

確認。
```
sudo systemctl status snapper-timeline.timer
sudo systemctl status snapper-cleanup.timer

sudo btrfs subvolume list /
sudo snapper -c root list
```

## grub-btrfsのインストールと設定
スナップショットから起動できるようにする。なんらかの理由で起動ができなくなったとき、助かる可能性が上がる。
```
sudo apt-get install --no-install-recommends -y gawk inotify-tools git make bzip2 &&
cd ~/ &&
git clone --depth=1 https://github.com/Antynea/grub-btrfs.git &&
cd grub-btrfs && # git checkout xxxxxxx
sudo make install &&
sudo update-grub &&
cd ../ &&
rm -drf grub-btrfs &&
sudo systemctl enable --now grub-btrfsd.service
```
最新版で不具合がある場合は、git checkout xxxxxxxを挿入する。

確認。
```
sudo systemctl status grub-btrfsd.service
```

## btrfs-compsizeのインストールと使用
Btrfsの圧縮機能でどの程度ファイルが圧縮されたのかを表示する。

インストール。
```
sudo apt-get install --no-install-recommends -y btrfs-compsize
```

表示。
```
sudo compsize -x /
```
