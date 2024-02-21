#!/bin/bash -eu

# ディスク
DISK1="/dev/$1"
DISK2="/dev/$2"

# Btrfsオプション
BTRFS_OPTIONS="ssd,noatime,discard=async,compress=zstd:1,degraded"

# パーティション
EFI1_PART="${DISK1}1"
SWAP1_PART="${DISK1}2"
ROOTFS1_PART="${DISK1}3"
EFI2_PART="${DISK2}1"
SWAP2_PART="${DISK2}2"
ROOTFS2_PART="${DISK2}3"

# UUIDを取得
EFI1_UUID="$(lsblk -dno UUID $EFI1_PART)"
SWAP1_UUID="$(lsblk -dno UUID $SWAP1_PART)"
ROOTFS_UUID="$(lsblk -dno UUID $ROOTFS1_PART)"
EFI2_UUID="$(lsblk -dno UUID $EFI2_PART)"
SWAP2_UUID="$(lsblk -dno UUID $SWAP2_PART)"

# アンマウント
sudo umount /target/boot/efi
sudo umount -l /target

# マウント
sudo mount "/dev/disk/by-uuid/$ROOTFS_UUID" -o "$BTRFS_OPTIONS" /mnt
cd /mnt

# 圧縮
sudo btrfs filesystem defragment -r -czstd .

# 各サブボリュームを作成
sudo btrfs subvolume snapshot . @
sudo btrfs subvolume create @root
sudo btrfs subvolume create @var_log
sudo btrfs subvolume create @snapshots

# @サブボリュームをデフォルト（GRUBがブートしようとする）に変更
sudo btrfs subvolume set-default @

# 作成したサブボリュームにファイルをコピー
sudo cp -RT --reflink=always root/ @root/
sudo cp -RT --reflink=always var/log/ @var_log/

# ルートボリュームからファイルを削除
sudo find . -mindepth 1 -maxdepth 1 \( -type d -or -type l \) -not -iname "@*" -exec rm -dr "{}" +

# @サブボリュームから別のサブボリュームと重複するファイルを削除
sudo find @/root -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +
sudo find @/var/log -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +

# RAID1化
sudo btrfs device add -f "$ROOTFS2_PART" .
sudo btrfs balance start -mconvert=raid1 -dconvert=raid1 .

#sudo btrfs balance start -mconvert=raid1,soft -dconvert=raid1,soft --bg / # 1台で運用した後に修復する場合

# fstabでBtrfsファイルシステムのマウントを次のように編集（「Ctrl + K」で行カット、「Ctrl + U」で行ペースト）
sudo tee @/etc/fstab << EOF >/dev/null
/dev/disk/by-uuid/$EFI1_UUID /boot/efi vfat defaults,nofail,x-systemd.device-timeout=5 0 0
/dev/disk/by-uuid/$EFI2_UUID /boot/efi2 vfat defaults,nofail,x-systemd.device-timeout=5 0 0
/dev/disk/by-uuid/$ROOTFS_UUID / btrfs defaults,subvol=@,$BTRFS_OPTIONS 0 0
/dev/disk/by-uuid/$ROOTFS_UUID /root btrfs defaults,subvol=@root,$BTRFS_OPTIONS 0 0
/dev/disk/by-uuid/$ROOTFS_UUID /var/log btrfs defaults,subvol=@var_log,$BTRFS_OPTIONS 0 0
/dev/disk/by-uuid/$ROOTFS_UUID /.snapshots btrfs defaults,subvol=@snapshots,$BTRFS_OPTIONS 0 0
/dev/disk/by-uuid/$SWAP1_UUID none swap sw,nofail,x-systemd.device-timeout=5 0 0
/dev/disk/by-uuid/$SWAP2_UUID none swap sw,nofail,x-systemd.device-timeout=5 0 0
EOF

# GRUB設定の変更
sudo tee @/etc/grub.d/19_linux_rootflags_degraded << EOF >/dev/null
#!/bin/sh
. "\$pkgdatadir/grub-mkconfig_lib"
TITLE="\$(echo "\${GRUB_DISTRIBUTOR} (rootflags=degraded)" | grub_quote)"
cat << EOS
menuentry '\$TITLE' {
  search --no-floppy --fs-uuid --set=root ${ROOTFS_UUID}
  linux /@/boot/vmlinuz root=UUID=${ROOTFS_UUID} ro rootflags=subvol=@,degraded \${GRUB_CMDLINE_LINUX} \${GRUB_CMDLINE_LINUX_DEFAULT}
  initrd /@/boot/initrd.img
}
EOS
EOF

sudo chmod a+x @/etc/grub.d/19_linux_rootflags_degraded

# いったんアンマウント
cd ../
sudo umount -l /mnt

# マウント
sudo mount "$ROOTFS1_PART" -o "subvol=@,$BTRFS_OPTIONS" /mnt
sudo mount "$ROOTFS1_PART" -o "subvol=@var_log,$BTRFS_OPTIONS" /mnt/var/log
sudo mount "$EFI1_PART" /mnt/boot/efi
sudo mkdir /mnt/boot/efi2
sudo mount "$EFI2_PART" /mnt/boot/efi2

# GRUB・ESPを更新
sudo apt-get install -y arch-install-scripts
sudo arch-chroot /mnt update-grub
sudo arch-chroot /mnt dpkg-reconfigure -u shim-signed
