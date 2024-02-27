#!/bin/bash -eu

# initialization
SUITE="$1"
HOSTNAME="$2"
USERNAME="$3"
PUBKEY="$(cat "$4")"
DISK1="/dev/$5"
DISK2="/dev/$6"
BTRFS_OPTIONS="defaults,ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"
MOUNT_POINT="/mnt"

# install tools
sudo apt-get install -y debootstrap arch-install-scripts

# partitioning
function partitioning () {
  DISK="$1"
  wipefs --all "${DISK}"
  sgdisk \
    -Z \
    -n 0::256MiB -t 0:ef00 \
    -n 0::4GiB   -t 0:8200 \
    -n 0::       -t 0:fd00 "${DISK}"
}

partitioning "${DISK1}"
partitioning "${DISK2}"

# formatting
mkfs.vfat -F 32 "${DISK1}1"
mkfs.vfat -F 32 "${DISK2}1"
mkswap "${DISK1}2"
mkswap "${DISK2}2"
mkfs.btrfs -d raid1 -m raid1 "${DISK1}3" "${DISK2}3"

# set UUIDs
EFI1_UUID="$(lsblk -dno UUID "${DISK1}1")"
EFI2_UUID="$(lsblk -dno UUID "${DISK2}1")"
SWAP1_UUID="$(lsblk -dno UUID "${DISK1}2")"
SWAP2_UUID="$(lsblk -dno UUID "${DISK2}2")"
ROOTFS_UUID="$(lsblk -dno UUID "${DISK1}3")"

# create subvolumes
mount "${DISK1}3" -o "$BTRFS_OPTIONS" "${MOUNT_POINT}"
cd "${MOUNT_POINT}"
btrfs subvolume create "@"
btrfs subvolume create "@root"
btrfs subvolume create "@var_log"
btrfs subvolume create "@snapshots"
btrfs subvolume set-default "@"
cd /
umount "${MOUNT_POINT}"

mount "${DISK1}3" -o "subvol=@,$BTRFS_OPTIONS" "${MOUNT_POINT}"
mkdir -p "${MOUNT_POINT}/root"
mount "${DISK1}3" -o "subvol=@root,$BTRFS_OPTIONS" "${MOUNT_POINT}/root"
mkdir -p "${MOUNT_POINT}/var/log"
mount "${DISK1}3" -o "subvol=@var_log,$BTRFS_OPTIONS" "${MOUNT_POINT}/var/log"
mkdir -p "${MOUNT_POINT}/boot/efi"
mount "${DISK1}1" "${MOUNT_POINT}/boot/efi"
mkdir -p "${MOUNT_POINT}/boot/efi2"
mount "${DISK2}1" "${MOUNT_POINT}/boot/efi2"

debootstrap "${SUITE}" "${MOUNT_POINT}"

tee "${MOUNT_POINT}/etc/apt/sources.list" << EOF > /dev/null
deb http://archive.ubuntu.com/ubuntu/ ${SUITE} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${SUITE}-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${SUITE}-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ ${SUITE}-security main restricted universe multiverse
EOF

echo "${HOSTNAME}" | tee "${MOUNT_POINT}/etc/hostname" > /dev/null
echo "127.0.0.1 ${HOSTNAME}" | tee -a "${MOUNT_POINT}/etc/hosts" > /dev/null

mkdir "${MOUNT_POINT}/home2"
arch-chroot "${MOUNT_POINT}" useradd --user-group --groups sudo --shell /bin/bash --create-home --base-dir "${MOUNT_POINT}/home2" "${USERNAME}"

mkdir "${MOUNT_POINT}/home2/${USERNAME}/.ssh"
echo "${PUBKEY}" | tee "${MOUNT_POINT}/home2/${USERNAME}/.ssh/authorized_keys" > /dev/null
arch-chroot "${MOUNT_POINT}" chown -R "${USERNAME}:${USERNAME}" "/home2/${USERNAME}/.ssh"
arch-chroot "${MOUNT_POINT}" chmod u=rw,go= "/home2/${USERNAME}/.ssh/authorized_keys"
