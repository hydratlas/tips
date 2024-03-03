#!/bin/sh
readonly SUITE="mantic"

# Storage
readonly ROOT_FILESYSTEM="btrfs"
readonly BTRFS_OPTIONS="defaults,ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"
readonly EXT4_OPTIONS="defaults,noatime"
readonly XFS_OPTIONS="defaults,noatime"
readonly MOUNT_POINT="/mnt"
readonly EFI_END="256MiB"
readonly SWAP_END="4GiB"

# Sebootstrap
readonly INSTALLER="mmdebstrap"
#readonly INSTALLER="debootstrap"
readonly CACHE_DIR="/tmp/debootstrap"
readonly MIRROR1="http://ftp.udx.icscoe.jp/Linux/ubuntu/"
readonly MIRROR2="http://jp.archive.ubuntu.com/ubuntu/"
readonly MIRROR3="http://archive.ubuntu.com/ubuntu/"

# Basic Settings
readonly INSTALLATION_LANG="C.UTF-8"
readonly TIMEZONE="Asia/Tokyo"
readonly XKBMODEL="pc105"
readonly XKBLAYOUT="jp"
readonly XKBVARIANT="OADG109A"

# GRUB
readonly GRUB_CMDLINE_LINUX_DEFAULT=""
#readonly GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"

# Packages
readonly PACKAGES_TO_INSTALL=( \
  initramfs-tools linux-firmware linux-generic shim-signed \
  libpam-systemd systemd-resolved systemd-timesyncd \
  e2fsprogs-l10n logrotate needrestart unattended-upgrades \
  dmidecode efibootmgr fwupd gdisk htop lshw lsof pci.ids pciutils usb.ids usbutils \
  bzip2 curl git make moreutils nano perl psmisc rsync time uuid-runtime wget zstd \
  bash-completion command-not-found landscape-common \
  language-pack-ja \
  )
readonly DEPENDENT_PACKAGES_TO_INSTALL=(ubuntu-minimal)
readonly PACKAGES_NOT_INSTALL=(eject netplan.io ubuntu-advantage-tools vim-tiny)

# User
readonly USER_NAME="ubuntu"
readonly USER_PASSWORD='$6$LMqzniAEoBSSS4gu$mMmV91M3oXrIpYCxIM2AlgvjxUWH2OPmLptPkttULMYMRCaJsfYxSiIySVM1q/K/mJVrAXnNNQEK9PTciP2Oe.'
readonly USER_HOME_DIR="/home2/ubuntu"
readonly USER_LANG="ja_JP.UTF-8"

# systemd-networkd
readonly WOL="magic"
#readonly WOL="off"
readonly MDNS=true
