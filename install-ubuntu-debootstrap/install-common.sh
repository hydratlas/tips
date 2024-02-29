#!/bin/bash -eu
function diskname-to-disk () {
  if [ -n "${1}" ]; then
    DISK1="/dev/${1}"
  else
    DISK1=""
  fi
  if [ -n "${2}" ]; then
    DISK2="/dev/${2}"
  else
    DISK2=""
  fi
}

function disk-to-partition () {
  DISK1_EFI="${1}1"
  DISK1_SWAP="${1}2"
  DISK1_ROOTFS="${1}3"
  if [ -e "${2}" ]; then
    DISK2_EFI="${2}1"
    DISK2_SWAP="${2}2"
    DISK2_ROOTFS="${2}3"
  fi
}

function mount-installfs () {
  mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@" "${MOUNT_POINT}"
  mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@root" "${MOUNT_POINT}/root"
  mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@var_log" "${MOUNT_POINT}/var/log"
  mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@snapshots" "${MOUNT_POINT}/.snapshots"

  mkdir -p "${MOUNT_POINT}/boot/efi"
  mount "${DISK1_EFI}" "${MOUNT_POINT}/boot/efi"
  if [ -e "${DISK2}" ]; then
    mkdir -p "${MOUNT_POINT}/boot/efi2"
    mount "${DISK2_EFI}" "${MOUNT_POINT}/boot/efi2"
  fi
}
