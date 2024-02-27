# initialization
DISK1="/dev/$1"
DISK2="/dev/$2"
BTRFS_OPTIONS="defaults,ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"
MOUNT_POINT="/mnt"

#!/bin/bash -eu

# install tools
sudo apt-get install -y debootstrap arch-install-scripts

# partitioning
function partitioning () {
  DISK="$1"
  sudo wipefs --all "${DISK}"
  sudo sgdisk \
    -Z \
    -n 0::256MiB -t 0:ef00 \
    -n 0::4GiB   -t 0:8200 \
    -n 0::       -t 0:fd00 "${DISK}"
}

partitioning "${DISK1}"
partitioning "${DISK2}"

# formatting
sudo mkfs.vfat -F 32 "${DISK1}1"
sudo mkfs.vfat -F 32 "${DISK2}1"
sudo mkswap "${DISK1}2"
sudo mkswap "${DISK2}2"
sudo mkfs.btrfs -d raid1 -m raid1 "${DISK1}3" "${DISK2}3"

# set UUIDs
EFI1_UUID="$(lsblk -dno UUID "${DISK1}1")"
EFI2_UUID="$(lsblk -dno UUID "${DISK2}1")"
SWAP1_UUID="$(lsblk -dno UUID "${DISK1}2")"
SWAP2_UUID="$(lsblk -dno UUID "${DISK2}2")"
ROOTFS_UUID="$(lsblk -dno UUID "${DISK1}3")"

# create subvolumes
sudo mount "${DISK1}3" -o "$BTRFS_OPTIONS" "${MOUNT_POINT}"
cd "${MOUNT_POINT}"
sudo btrfs subvolume create "@"
sudo btrfs subvolume create "@root"
sudo btrfs subvolume create "@var_log"
sudo btrfs subvolume create "@snapshots"
sudo btrfs subvolume set-default "@"
cd /
sudo umount "${MOUNT_POINT}"

sudo mount "${DISK1}3" -o "subvol=@,$BTRFS_OPTIONS" "${MOUNT_POINT}"
sudo mkdir -p "${MOUNT_POINT}/root"
sudo mount "${DISK1}3" -o "subvol=@root,$BTRFS_OPTIONS" "${MOUNT_POINT}/root"
sudo mkdir -p "${MOUNT_POINT}/var/log"
sudo mount "${DISK1}3" -o "subvol=@var_log,$BTRFS_OPTIONS" "${MOUNT_POINT}/var/log"
sudo mkdir -p "${MOUNT_POINT}/boot/efi"
sudo mount "${DISK1}1" "${MOUNT_POINT}/boot/efi"
sudo mkdir -p "${MOUNT_POINT}/boot/efi2"
sudo mount "${DISK2}1" "${MOUNT_POINT}/boot/efi2"

sudo debootstrap jammy "${MOUNT_POINT}"
