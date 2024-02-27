#!/bin/bash -eu

# Initialization
SUITE="${1}"
HOSTNAME="${2}"
USERNAME="${3}"
PUBKEY="$(cat "${4}")"
DISK1="/dev/${5}"
if [ -n "${6}" ]; then
  DISK2="/dev/${6}"
else
  DISK2=""
fi
BTRFS_OPTIONS="ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"
MOUNT_POINT="/mnt"

# Install arch-install-scripts
sudo apt-get install -y mmdebstrap arch-install-scripts
#sudo apt-get install -y debootstrap arch-install-scripts

# Partitioning
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
if [ -e "${DISK2}" ]; then
  partitioning "${DISK2}"
fi

# Formatting
mkfs.vfat -F 32 "${DISK1}1"
mkswap "${DISK1}2"
if [ -e "${DISK2}" ]; then
  mkfs.vfat -F 32 "${DISK2}1"
  mkswap "${DISK2}2"
fi
if [ -e "${DISK2}" ]; then
  mkfs.btrfs -f -d raid1 -m raid1 "${DISK1}3" "${DISK2}3"
else
  mkfs.btrfs -f "${DISK1}3"
fi

# Set UUIDs
ROOTFS_UUID="$(lsblk -dno UUID "${DISK1}3")"
EFI1_UUID="$(lsblk -dno UUID "${DISK1}1")"
SWAP1_UUID="$(lsblk -dno UUID "${DISK1}2")"
if [ -e "${DISK2}" ]; then
  EFI2_UUID="$(lsblk -dno UUID "${DISK2}1")"
  SWAP2_UUID="$(lsblk -dno UUID "${DISK2}2")"
fi

# Create subvolumes
mount "${DISK1}3" -o "defaults,${BTRFS_OPTIONS}" "${MOUNT_POINT}"
cd "${MOUNT_POINT}"
btrfs subvolume create "@"
btrfs subvolume create "@root"
btrfs subvolume create "@var_log"
btrfs subvolume create "@snapshots"
btrfs subvolume set-default "@"
cd /
umount "${MOUNT_POINT}"

# Mount Btrfs
mount "${DISK1}3" -o "defaults,${BTRFS_OPTIONS},subvol=@" "${MOUNT_POINT}"
mkdir -p "${MOUNT_POINT}/root"
mount "${DISK1}3" -o "defaults,${BTRFS_OPTIONS},subvol=@root" "${MOUNT_POINT}/root"
mkdir -p "${MOUNT_POINT}/var/log"
mount "${DISK1}3" -o "defaults,${BTRFS_OPTIONS},subvol=@var_log" "${MOUNT_POINT}/var/log"
mkdir -p "${MOUNT_POINT}/boot/efi"
mount "${DISK1}1" "${MOUNT_POINT}/boot/efi"
if [ -e "${DISK2}" ]; then
  mkdir -p "${MOUNT_POINT}/boot/efi2"
  mount "${DISK2}1" "${MOUNT_POINT}/boot/efi2"
fi

# Install
mmdebstrap --skip=check/empty --components="main restricted universe multiverse" "${SUITE}" "${MOUNT_POINT}" http://archive.ubuntu.com/ubuntu
#debootstrap "${SUITE}" "${MOUNT_POINT}"

# Configurate
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure tzdata
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure locales
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure keyboard-configuration

# Create sources.list
tee "${MOUNT_POINT}/etc/apt/sources.list" << EOF > /dev/null
deb http://archive.ubuntu.com/ubuntu/ ${SUITE} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${SUITE}-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ ${SUITE}-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ ${SUITE}-security main restricted universe multiverse
EOF

# Create fstab
FSTAB_BASE="/dev/disk/by-uuid/${ROOTFS_UUID} / btrfs defaults,${BTRFS_OPTIONS},subvol=@ 0 0
/dev/disk/by-uuid/${ROOTFS_UUID} /root btrfs defaults,${BTRFS_OPTIONS},subvol=@root 0 0
/dev/disk/by-uuid/${ROOTFS_UUID} /var/log btrfs defaults,${BTRFS_OPTIONS},subvol=@var_log 0 0
/dev/disk/by-uuid/${ROOTFS_UUID} /.snapshots btrfs defaults,${BTRFS_OPTIONS},subvol=@snapshots 0 0
"
FSTAB_DISK1="/dev/disk/by-uuid/${EFI1_UUID} /boot/efi vfat defaults,nofail,x-systemd.device-timeout=5 0 0
/dev/disk/by-uuid/${SWAP1_UUID} none swap sw,nofail,x-systemd.device-timeout=5 0 0
"
FSTAB="${FSTAB_BASE}${FSTAB_DISK1}"
if [ -e "${DISK2}" ]; then
  FSTAB_DISK2="/dev/disk/by-uuid/${EFI2_UUID} /boot/efi2 vfat defaults,nofail,x-systemd.device-timeout=5 0 0
/dev/disk/by-uuid/${SWAP2_UUID} none swap sw,nofail,x-systemd.device-timeout=5 0 0
"
  FSTAB="${FSTAB}${FSTAB_DISK2}"
fi
echo "$FSTAB" | tee "${MOUNT_POINT}/etc/fstab"

# Set Hostname
echo "${HOSTNAME}" | tee "${MOUNT_POINT}/etc/hostname" > /dev/null
echo "127.0.0.1 ${HOSTNAME}" | tee -a "${MOUNT_POINT}/etc/hosts" > /dev/null

# Create User
mkdir -p "${MOUNT_POINT}/home2/${USERNAME}"
arch-chroot "${MOUNT_POINT}" useradd --user-group --groups sudo --shell /bin/bash --create-home --home-dir "${MOUNT_POINT}/home2/${USERNAME}" "${USERNAME}"

# Configure SSH
mkdir "${MOUNT_POINT}/home2/${USERNAME}/.ssh"
echo "${PUBKEY}" | tee "${MOUNT_POINT}/home2/${USERNAME}/.ssh/authorized_keys" > /dev/null
arch-chroot "${MOUNT_POINT}" chown -R "${USERNAME}:${USERNAME}" "/home2/${USERNAME}/.ssh"
arch-chroot "${MOUNT_POINT}" chmod u=rw,go= "/home2/${USERNAME}/.ssh/authorized_keys"

# Install Packages
arch-chroot "${MOUNT_POINT}" apt-get update
arch-chroot "${MOUNT_POINT}" apt-get dist-upgrade -y
arch-chroot "${MOUNT_POINT}" apt-get install -y linux-{,image-,headers-}generic linux-firmware initramfs-tools efibootmgr shim-signed openssh-server

# Configure GRUB
tee "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded" << EOF > /dev/null
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
sudo chmod a+x "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded"

# Install GRUB
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure -u shim-signed
