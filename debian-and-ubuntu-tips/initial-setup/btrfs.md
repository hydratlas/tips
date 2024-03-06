# Btrfs関係
## スクラブ・バランスタイマーの設定・確認
設定。
```
sudo apt-get install -y --no-install-recommends btrfsmaintenance &&
sudo perl -p -i -e 's/^OnCalendar=.+$/OnCalendar=fri/g;' /lib/systemd/system/btrfs-balance.timer &&
sudo perl -p -i -e 's/^OnCalendar=.+$/OnCalendar=sat/g;' /lib/systemd/system/btrfs-scrub.timer &&
sudo systemctl enable --now btrfs-balance.timer &&
sudo systemctl enable --now btrfs-scrub.timer
```

確認。
```
sudo systemctl status btrfs-balance.timer
sudo systemctl status btrfs-scrub.timer
```

## Snapperのインストールと設定・確認
インストールと設定。
```
sudo apt-get install -y --no-install-recommends snapper &&
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

確認。
```
sudo systemctl status snapper-timeline.timer
sudo systemctl status snapper-cleanup.timer

sudo btrfs subvolume list /
sudo snapper -c root list
```

## grub-btrfsのインストールと設定
インストールと設定。
```
sudo apt-get install -y --no-install-recommends gawk inotify-tools git make bzip2 &&
cd ~/ &&
git clone https://github.com/Antynea/grub-btrfs.git &&
cd grub-btrfs &&
sudo make install &&
cd ../ &&
rm -drf grub-btrfs &&
sudo systemctl enable --now grub-btrfsd.service
```

確認。
```
sudo systemctl status grub-btrfsd.service
```

## btrfs-compsizeのインストールと使用
Btrfsの圧縮機能でどの程度ファイルが圧縮されたのかを表示する。

インストール。
```
sudo apt-get install -y --no-install-recommends btrfs-compsize
```

表示。
```
sudo compsize -x /
```
