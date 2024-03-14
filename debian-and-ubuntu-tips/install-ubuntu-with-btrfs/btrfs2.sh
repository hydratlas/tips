#!/bin/bash -eu

# ディスク
DISK1="/dev/${1}"
if [ -n "${2:-}" ]; then
  DISK2="/dev/${2}"
else
  DISK2=""
fi

# Btrfsオプション
BTRFS_OPTIONS="ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"

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
if [ -e "${DISK2}" ]; then
  EFI2_UUID="$(lsblk -dno UUID $EFI2_PART)"
  SWAP2_UUID="$(lsblk -dno UUID $SWAP2_PART)"
fi

# アンマウント
umount /target/boot/efi
umount -l /target

# マウント
MOUNT_POINT="/mnt"
mount "/dev/disk/by-uuid/$ROOTFS_UUID" -o "$BTRFS_OPTIONS" "${MOUNT_POINT}"
cd "${MOUNT_POINT}"

# 圧縮
btrfs filesystem defragment -r -czstd .

# 各サブボリュームを作成
btrfs subvolume snapshot . @
btrfs subvolume create @home
btrfs subvolume create @root
btrfs subvolume create @var_log
btrfs subvolume create @snapshots

# @サブボリュームをデフォルト（GRUBがブートしようとする）に変更
btrfs subvolume set-default @

# 作成したサブボリュームにファイルをコピー
cp -RT --reflink=always home/ @home/
cp -RT --reflink=always root/ @root/
cp -RT --reflink=always var/log/ @var_log/

# ルートボリュームからファイルを削除
find . -mindepth 1 -maxdepth 1 \( -type d -or -type l \) -not -iname "@*" -exec rm -dr "{}" +

# @サブボリュームから別のサブボリュームと重複するファイルを削除
find @/home -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +
find @/root -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +
find @/var/log -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +

# RAID1化
if [ -e "${DISK2}" ]; then
  btrfs device add -f "$ROOTFS2_PART" .
  btrfs balance start -mconvert=raid1 -dconvert=raid1 .
fi
#btrfs balance start -mconvert=raid1,soft -dconvert=raid1,soft --bg / # 1台で運用した後に修復する場合

# fstabを作成
FSTAB_ARRAY=()
FSTAB_ARRAY+=("/dev/disk/by-uuid/$ROOTFS_UUID / btrfs defaults,subvol=@,$BTRFS_OPTIONS 0 0")
FSTAB_ARRAY+=("/dev/disk/by-uuid/$ROOTFS_UUID /home btrfs defaults,subvol=@home,$BTRFS_OPTIONS 0 0")
FSTAB_ARRAY+=("/dev/disk/by-uuid/$ROOTFS_UUID /root btrfs defaults,subvol=@root,$BTRFS_OPTIONS 0 0")
FSTAB_ARRAY+=("/dev/disk/by-uuid/$ROOTFS_UUID /var/log btrfs defaults,subvol=@var_log,$BTRFS_OPTIONS 0 0")
FSTAB_ARRAY+=("/dev/disk/by-uuid/$ROOTFS_UUID /.snapshots btrfs defaults,subvol=@snapshots,$BTRFS_OPTIONS 0 0")
FSTAB_ARRAY+=("/dev/disk/by-uuid/$EFI1_UUID /boot/efi vfat defaults,nofail,x-systemd.device-timeout=5 0 0")
FSTAB_ARRAY+=("/dev/disk/by-uuid/$SWAP1_UUID none swap sw,nofail,x-systemd.device-timeout=5 0 0")
if [ -e "${DISK2}" ]; then
  FSTAB_ARRAY+=("/dev/disk/by-uuid/$EFI2_UUID /boot/efi2 vfat defaults,nofail,x-systemd.device-timeout=5 0 0")
  FSTAB_ARRAY+=("/dev/disk/by-uuid/$SWAP2_UUID none swap sw,nofail,x-systemd.device-timeout=5 0 0")
fi
printf -v FSTAB_STR "%s\n" "${FSTAB_ARRAY[@]}"
tee @/etc/fstab <<< "$FSTAB_STR" > /dev/null

# GRUB設定の変更
tee @/etc/grub.d/19_linux_rootflags_degraded << EOF > /dev/null
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

chmod a+x @/etc/grub.d/19_linux_rootflags_degraded

# いったんアンマウント
cd /
umount -l "${MOUNT_POINT}"

# マウント
mount "$ROOTFS1_PART" -o "subvol=@,$BTRFS_OPTIONS" "${MOUNT_POINT}"
mount "$ROOTFS1_PART" -o "subvol=@var_log,$BTRFS_OPTIONS" "${MOUNT_POINT}/var/log"
mount "$EFI1_PART" "${MOUNT_POINT}/boot/efi"
if [ -e "${DISK2}" ]; then
  mkdir "${MOUNT_POINT}/boot/efi2"
  mount "$EFI2_PART" "${MOUNT_POINT}/boot/efi2"
fi

# GRUB・ESPを更新
DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y arch-install-scripts
arch-chroot "${MOUNT_POINT}" /bin/bash -eux -- << EOS
update-grub
dpkg-reconfigure --frontend noninteractive shim-signed
EOS
