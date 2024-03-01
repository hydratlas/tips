#!/bin/bash -eu

# ディスク
DISK="/dev/$1"

# フォーマット
sudo wipefs --all "$DISK"
sudo sgdisk \
  -Z \
  -n 0::256MiB -t 0:ef00 \
  -n 0::4GiB   -t 0:8200 \
  -n 0::       -t 0:8304 "$DISK"

sudo mkfs.vfat -F 32 "${DISK}1"
sudo mkswap "${DISK}2"
