#!/bin/sh
readonly PUBKEYURL=""

# Base
#readonly DISTRIBUTION="ubuntu"
#readonly SUITE="mantic"
#readonly COMPONENTS=(main restricted universe multiverse)
#readonly VARIANT="minbase"

# Base
readonly DISTRIBUTION="debian"
readonly SUITE="bookworm"
readonly COMPONENTS=(main contrib non-free non-free-firmware)
readonly VARIANT="minbase"

# Packages
#readonly INSTALLATION_PACKAGES=( \
#  linux-generic linux-firmware language-pack-ja landscape-common \
#  intel-microcode amd64-microcode init initramfs-tools zstd libpam-systemd systemd-timesyncd \
#  apt console-setup locales tzdata keyboard-configuration \
#  logrotate sudo unattended-upgrades needrestart \
#  dmidecode efibootmgr fwupd iproute2 iputils-ping lsb-release pci.ids pciutils usb.ids usbutils \
#  less bash-completion command-not-found nano whiptail \
#  )
#readonly INSTALLATION_PACKAGES_FOR_SSH_SERVER=(openssh-server)
#readonly INSTALLATION_PACKAGES_FOR_SYSTEMD_NETWORKD=(systemd-resolved)
#readonly INSTALLATION_PACKAGES_FOR_GRUB=(shim-signed)
#readonly MIRROR1="http://ftp.udx.icscoe.jp/Linux/ubuntu"
#readonly ARCHIVE_KEYRING_PACKAGE="ubuntu-keyring"
#readonly ARCHIVE_KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

# Packages
readonly INSTALLATION_PACKAGES=( \
  linux-image-amd64 firmware-linux task-japanese \
  intel-microcode amd64-microcode init initramfs-tools zstd libpam-systemd systemd-timesyncd \
  apt console-setup locales tzdata keyboard-configuration \
  logrotate sudo unattended-upgrades needrestart \
  dmidecode efibootmgr fwupd iproute2 iputils-ping lsb-release pci.ids pciutils usb.ids usbutils \
  less bash-completion command-not-found nano whiptail \
  )
readonly INSTALLATION_PACKAGES_FOR_SSH_SERVER=(openssh-server)
readonly INSTALLATION_PACKAGES_FOR_SYSTEMD_NETWORKD=(systemd-resolved)
readonly INSTALLATION_PACKAGES_FOR_GRUB=(grub-efi-amd64 grub-efi-amd64-signed shim-signed)
readonly MIRROR1="http://ftp.jp.debian.org/debian"
readonly ARCHIVE_KEYRING_PACKAGE="debian-archive-keyring"
readonly ARCHIVE_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"

# Storage
readonly ROOT_FILESYSTEM="btrfs"
readonly BTRFS_OPTIONS="defaults,ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"
readonly EXT4_OPTIONS="defaults,noatime"
readonly XFS_OPTIONS="defaults,noatime"
readonly MOUNT_POINT="/mnt"
readonly EFI_END="256MiB"
readonly SWAP_END="4GiB"

# Debootstrap
readonly INSTALLER="mmdebstrap" # debootstrap
readonly CACHE_DIR="/tmp/debootstrap"

# Basic Settings
readonly INSTALLATION_LANG="C.UTF-8"
readonly TIMEZONE="Asia/Tokyo"
readonly XKBMODEL="pc105"
readonly XKBLAYOUT="jp"
readonly XKBVARIANT="OADG109A"

# User
readonly USER_NAME="newuser"
readonly USER_PASSWORD='$6$c5PYNsRGtx0k3Z7x$pXFVWhtOuh09YwflSBQfaM6zNf.gW4DwHP9GB7MF3gWNeRstY.8E3mQVO7aU1CFThZsBAZYSNuO1/5Pecsg3p0'
readonly USER_HOME_DIR="/home2/newuser"
readonly USER_LANG="ja_JP.UTF-8"

# SSH Server
readonly IS_SSH_SERVER_INSTALLATION=true

# systemd-networkd
readonly IS_SYSTEMD_NETWORKD_INSTALLATION=true
readonly WOL="magic" # off
readonly MDNS=true

# GRUB
readonly IS_GRUB_INSTALLATION=true
readonly GRUB_CMDLINE_LINUX_DEFAULT="" # quiet splash
readonly GRUB_TIMEOUT=2
readonly GRUB_DISABLE_OS_PROBER=true
