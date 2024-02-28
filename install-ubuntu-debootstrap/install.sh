#!/bin/bash -eu

source ./install.conf
HOSTNAME="${1}"
PUBKEYURL="${2}"
if [ -n "${3}" ]; then
  DISK1="/dev/${3}"
else
  DISK1=""
fi
if [ -n "${4}" ]; then
  DISK2="/dev/${4}"
else
  DISK2=""
fi

# Install arch-install-scripts
sudo apt-get install -y mmdebstrap arch-install-scripts
#sudo apt-get install -y debootstrap arch-install-scripts

# Partitioning
function partitioning () {
  wipefs --all "${1}"
  sgdisk \
    -Z \
    -n "0::${2}" -t 0:ef00 \
    -n "0::${3}" -t 0:8200 \
    -n "0::"     -t 0:fd00 "${1}"
}

partitioning "${DISK1}" "${EFI_END}" "${SWAP_END}"
if [ -e "${DISK2}" ]; then
  partitioning "${DISK2}" "${EFI_END}" "${SWAP_END}"
fi

DISK1_EFI="${DISK1}1"
DISK1_SWAP="${DISK1}2"
DISK1_ROOTFS="${DISK1}3"
if [ -e "${DISK2}" ]; then
  DISK2_EFI="${DISK2}1"
  DISK2_SWAP="${DISK2}2"
  DISK2_ROOTFS="${DISK2}3"
fi

# Formatting
mkfs.vfat -F 32 "${DISK1_EFI}"
mkswap "${DISK1_SWAP}"
if [ -e "${DISK2}" ]; then
  mkfs.vfat -F 32 "${DISK2_EFI}"
  mkswap "${DISK2_SWAP}"
fi
if [ -e "${DISK2}" ]; then
  mkfs.btrfs -f -d raid1 -m raid1 "${DISK1_ROOTFS}" "${DISK2_ROOTFS}"
else
  mkfs.btrfs -f "${DISK1_ROOTFS}"
fi

# Set UUIDs
ROOTFS_UUID="$(lsblk -dno UUID "${DISK1_ROOTFS}")"
EFI1_UUID="$(lsblk -dno UUID "${DISK1_EFI}")"
SWAP1_UUID="$(lsblk -dno UUID "${DISK1_SWAP}")"
if [ -e "${DISK2}" ]; then
  EFI2_UUID="$(lsblk -dno UUID "${DISK2_EFI}")"
  SWAP2_UUID="$(lsblk -dno UUID "${DISK2_SWAP}")"
fi

# Create subvolumes
mkdir -p "${MOUNT_POINT}"
mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS}" "${MOUNT_POINT}"
cd "${MOUNT_POINT}"
btrfs subvolume create "@"
btrfs subvolume create "@root"
btrfs subvolume create "@var_log"
btrfs subvolume create "@snapshots"
btrfs subvolume set-default "@"
cd /
umount "${MOUNT_POINT}"

# Mount Btrfs
mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@" "${MOUNT_POINT}"
mkdir -p "${MOUNT_POINT}/root"
mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@root" "${MOUNT_POINT}/root"
mkdir -p "${MOUNT_POINT}/var/log"
mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@var_log" "${MOUNT_POINT}/var/log"
mkdir -p "${MOUNT_POINT}/boot/efi"
mount "${DISK1_EFI}" "${MOUNT_POINT}/boot/efi"
if [ -e "${DISK2}" ]; then
  mkdir -p "${MOUNT_POINT}/boot/efi2"
  mount "${DISK2_EFI}" "${MOUNT_POINT}/boot/efi2"
fi

# Install
mmdebstrap --skip=check/empty --components="main restricted universe multiverse" "${SUITE}" "${MOUNT_POINT}" "${MIRROR}"
#debootstrap "${SUITE}" "${MOUNT_POINT}" "${MIRROR}"

# Configurate
ln -sf "${MOUNT_POINT}/usr/share/zoneinfo/${TZ}" "${MOUNT_POINT}/etc/localtime"
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive tzdata

locale-gen "C.UTF-8"
echo 'LANG="C.UTF-8"' | tee "${MOUNT_POINT}/etc/default/locale" > /dev/null
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive locales

perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"${XKBMODEL}\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"${XKBLAYOUT}\"/g" "${MOUNT_POINT}/etc/default/keyboard"
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive keyboard-configuration

# Create sources.list
tee "${MOUNT_POINT}/etc/apt/sources.list" << EOF > /dev/null
deb ${MIRROR} ${SUITE} main restricted universe multiverse
deb ${MIRROR} ${SUITE}-updates main restricted universe multiverse
deb ${MIRROR} ${SUITE}-backports main restricted universe multiverse
deb ${MIRROR} ${SUITE}-security main restricted universe multiverse
EOF

# Create fstab
FSTAB_BASE="/dev/disk/by-uuid/${ROOTFS_UUID} / btrfs ${BTRFS_OPTIONS},subvol=@ 0 0
/dev/disk/by-uuid/${ROOTFS_UUID} /root btrfs ${BTRFS_OPTIONS},subvol=@root 0 0
/dev/disk/by-uuid/${ROOTFS_UUID} /var/log btrfs ${BTRFS_OPTIONS},subvol=@var_log 0 0
/dev/disk/by-uuid/${ROOTFS_UUID} /.snapshots btrfs ${BTRFS_OPTIONS},subvol=@snapshots 0 0
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
echo "$FSTAB" | tee "${MOUNT_POINT}/etc/fstab" > /dev/null

# Set Hostname
echo "${HOSTNAME}" | tee "${MOUNT_POINT}/etc/hostname" > /dev/null
echo "127.0.0.1 ${HOSTNAME}" | tee -a "${MOUNT_POINT}/etc/hosts" > /dev/null

# Create User
mkdir -p "${MOUNT_POINT}/home2/${USERNAME}"
arch-chroot "${MOUNT_POINT}" useradd --user-group --groups sudo --shell /bin/bash --create-home --home-dir "${MOUNT_POINT}/home2/${USERNAME}" "${USERNAME}"

# Configure SSH
mkdir "${MOUNT_POINT}/home2/${USERNAME}/.ssh"
wget -O "${MOUNT_POINT}/home2/${USERNAME}/.ssh/authorized_keys" "${PUBKEYURL}"
arch-chroot "${MOUNT_POINT}" chown -R "${USERNAME}:${USERNAME}" "/home2/${USERNAME}/.ssh"
arch-chroot "${MOUNT_POINT}" chmod u=rw,go= "/home2/${USERNAME}/.ssh/authorized_keys"

# Install Packages
arch-chroot "${MOUNT_POINT}" apt-get update
arch-chroot "${MOUNT_POINT}" apt-get dist-upgrade -y
arch-chroot "${MOUNT_POINT}" apt-get install -y linux-{,image-,headers-}generic linux-firmware initramfs-tools efibootmgr shim-signed openssh-server nano

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
if [ -e "${DISK2}" ]; then
  ESPs="${DISK1_EFI}, ${DISK2_EFI}"
else
  ESPs="${DISK1_EFI}"
fi

DEBCONF_EFI="Name: grub-efi/install_devices
Template: grub-efi/install_devices
Value: ${ESPs}
Owners: grub-common, grub-efi-amd64, grub-pc
Flags: seen
Variables:
 CHOICES = 
 RAW_CHOICES = 

"
echo "$DEBCONF_EFI" | tee -a "${MOUNT_POINT}/var/cache/debconf/config.dat"

arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi
arch-chroot "${MOUNT_POINT}" update-grub
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive shim-signed
