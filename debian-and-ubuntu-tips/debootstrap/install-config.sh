#!/bin/sh
if [ "ubuntu" = "${DISTRIBUTION}" ]; then
  source ./install-config-ubuntu.sh
elif [ "debian" = "${DISTRIBUTION}" ]; then
  source ./install-config-debian.sh
fi

# Storage
readonly ROOT_FILESYSTEM="btrfs"
readonly BTRFS_OPTIONS="defaults,ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"
readonly EXT4_OPTIONS="defaults,noatime"
readonly XFS_OPTIONS="defaults,noatime"
readonly MOUNT_POINT="/mnt"
readonly EFI_END="256MiB"
readonly SWAP_END="4GiB"

# Sebootstrap
#readonly INSTALLER="mmdebstrap"
readonly INSTALLER="debootstrap"
readonly CACHE_DIR="/tmp/debootstrap"

# Basic Settings
readonly INSTALLATION_LANG="C.UTF-8"
readonly TIMEZONE="Asia/Tokyo"
readonly XKBMODEL="pc105"
readonly XKBLAYOUT="jp"
readonly XKBVARIANT="OADG109A"

# GRUB
readonly GRUB_CMDLINE_LINUX_DEFAULT=""
#readonly GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
readonly GRUB_TIMEOUT=2
readonly GRUB_DISABLE_OS_PROBER=true

# User
readonly USER_NAME="newuser"
readonly USER_PASSWORD='$6$c5PYNsRGtx0k3Z7x$pXFVWhtOuh09YwflSBQfaM6zNf.gW4DwHP9GB7MF3gWNeRstY.8E3mQVO7aU1CFThZsBAZYSNuO1/5Pecsg3p0'
readonly USER_HOME_DIR="/home2/newuser"
readonly USER_LANG="ja_JP.UTF-8"

# systemd-networkd
readonly WOL="magic"
#readonly WOL="off"
readonly MDNS=true
