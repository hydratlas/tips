#!/bin/bash
set -eux

DISK="/dev/${1}"
ESP="${2:-512MiB}" # Debian requires 512 MiB.
SWAP="${3:-4GiB}"

# フォーマット
wipefs --all "$DISK"
sgdisk \
  -Z \
  -n "0::${ESP}" -t "0:ef00" \
  -n "0::${SWAP}"   -t "0:8200" \
  -n "0::"       -t "0:8304" "$DISK"

if [ -e "${DISK}1" ]; then
  mkfs.vfat -F 32 "${DISK}1"
else
  mkfs.vfat -F 32 "${DISK}p1"
fi

if [ -e "${DISK}2" ]; then
  mkswap "${DISK}2"
else
  mkswap "${DISK}p2"
fi
