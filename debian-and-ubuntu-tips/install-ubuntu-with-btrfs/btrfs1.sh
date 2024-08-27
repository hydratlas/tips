#!/bin/bash -eu

# ディスク
DISK="/dev/$1"

# フォーマット
wipefs --all "$DISK"
sgdisk \
  -Z \
  -n 0::256MiB -t 0:ef00 \
  -n 0::4GiB   -t 0:8200 \
  -n 0::       -t 0:8304 "$DISK"

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
