#!/bin/bash -eu
source ./install-config.sh
source ./install-common.sh
HOSTNAME="${1}"
PUBKEYURL="${2}"
diskname-to-diskpath "${3:-}" "${4:-}"

# Check
wget --spider "${PUBKEYURL}"

# Partitioning
function disk-partitioning () {
  wipefs --all "${1}"
  sgdisk \
    -Z \
    -n "0::${2}" -t 0:ef00 \
    -n "0::${3}" -t 0:8200 \
    -n "0::"     -t 0:8304 "${1}"
}
disk-partitioning "${DISK1_PATH}" "${EFI_END}" "${SWAP_END}"
if [ -e "${DISK2_PATH}" ]; then
  disk-partitioning "${DISK2_PATH}" "${EFI_END}" "${SWAP_END}"
fi

diskpath-to-partitionpath "${DISK1_PATH}" "${DISK2_PATH}"

# Formatting
mkfs.vfat -F 32 "${DISK1_EFI}"
mkswap "${DISK1_SWAP}"
if [ -e "${DISK2_PATH}" ]; then
  mkfs.vfat -F 32 "${DISK2_EFI}"
  mkswap "${DISK2_SWAP}"
fi
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
  if [ -e "${DISK2_PATH}" ]; then
    mkfs.btrfs -f -d raid1 -m raid1 "${DISK1_ROOTFS}" "${DISK2_ROOTFS}"
  else
    mkfs.btrfs -f "${DISK1_ROOTFS}"
  fi
elif [ "ext4" = "${ROOT_FILESYSTEM}" ]; then
  mkfs.ext4 -F "${DISK1_ROOTFS}"
elif [ "xfs" = "${ROOT_FILESYSTEM}" ]; then
  mkfs.xfs -F "${DISK1_ROOTFS}"
fi

# Set UUIDs
get-filesystem-UUIDs

# Create Btrfs subvolumes
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
  mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS}" --mkdir "${MOUNT_POINT}"
  btrfs subvolume create "${MOUNT_POINT}/@"
  btrfs subvolume create "${MOUNT_POINT}/@root"
  btrfs subvolume create "${MOUNT_POINT}/@var_log"
  btrfs subvolume create "${MOUNT_POINT}/@snapshots"
  btrfs subvolume set-default "${MOUNT_POINT}/@"
  btrfs subvolume list "${MOUNT_POINT}" # confirmation
  umount "${MOUNT_POINT}"
fi

# Mount installation filesystem
mount-installfs

# Install distribution
COMPONENTS="main,restricted,universe,multiverse"
VARIANT="minbase"
INCLUDE_PKGS="apt,console-setup,locales,tzdata,keyboard-configuration"
if [ "mmdebstrap" = "${INSTALLER}" ]; then
  apt-get install -y mmdebstrap
  mmdebstrap --skip=check/empty --components="${COMPONENTS}" --variant="${VARIANT}" --include="${INCLUDE_PKGS}" \
    "${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"
else
  apt-get install -y debootstrap
  mkdir -p "${CACHE_DIR}"
  debootstrap --components="${COMPONENTS}" --variant="${VARIANT}" --include="${INCLUDE_PKGS}" \
    --cache-dir="${CACHE_DIR}" \
    "${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"
fi

# Get snapshot
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
  btrfs subvolume snapshot "${MOUNT_POINT}" "${MOUNT_POINT}/.snapshots/after-installation"
fi
