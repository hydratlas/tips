#!/bin/sh
# Suite and Packages (Ubuntu 23.10 Mantic Minotaur)
readonly DISTRIBUTION="ubuntu"
readonly SUITE="mantic"
readonly COMPONENTS=(main restricted universe multiverse)
readonly VARIANT="minbase"
readonly PACKAGES_TO_INSTALL=( \
  linux-generic intel-microcode amd64-microcode \
  libpam-systemd systemd-timesyncd \
  e2fsprogs-l10n logrotate needrestart unattended-upgrades \
  dmidecode efibootmgr fwupd pci.ids pciutils usb.ids usbutils \
  bash-completion command-not-found landscape-common \
  language-pack-ja \
  )
readonly DEPENDENT_PACKAGES_TO_INSTALL=(ubuntu-minimal)

readonly PACKAGES_NOT_INSTALL=( \
  netplan.io ubuntu-advantage-tools \
  dhcpcd-base kbd netbase netcat-openbsd vim-tiny \
  )
# dhcpcd-base: DHCP client daemon
# kbd: Linux keyboard tools
# netbase: Network configuration tools
# netcat-openbsd: Network tools
# vim-tiny: Vim in compact version

readonly MIRROR1="http://ftp.udx.icscoe.jp/Linux/ubuntu/"
readonly MIRROR2="https://linux.yz.yamagata-u.ac.jp/ubuntu/"
readonly MIRROR3="http://jp.archive.ubuntu.com/ubuntu/"
readonly MIRROR_SECURITY="http://security.ubuntu.com/ubuntu"

# Suite and Packages (Debian 12 Bookworm)
#readonly DISTRIBUTION="debian"
#readonly SUITE="bookworm"
#readonly COMPONENTS=(main contrib non-free non-free-firmware)
#readonly VARIANT=""
#readonly PACKAGES_TO_INSTALL=( \
#  linux-image-amd64 firmware-linux intel-microcode amd64-microcode \
#  libpam-systemd systemd-timesyncd \
#  e2fsprogs-l10n logrotate needrestart unattended-upgrades \
#  dmidecode efibootmgr fwupd pci.ids pciutils usb.ids usbutils \
#  bash-completion command-not-found \
#  task-japanese
#  )
#readonly DEPENDENT_PACKAGES_TO_INSTALL=()
#readonly PACKAGES_NOT_INSTALL=()
#readonly MIRROR1="http://ftp.jp.debian.org/debian/"
#readonly MIRROR2="https://debian-mirror.sakura.ne.jp/debian/"
#readonly MIRROR3="http://cdn.debian.or.jp/debian/"
#readonly MIRROR_SECURITY="http://security.debian.org/debian-security"

# Preinstall packages
readonly PREINSTALL_PACKAGES=(apt console-setup locales tzdata keyboard-configuration)
 
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

# Basic Settings
readonly INSTALLATION_LANG="C.UTF-8"
readonly TIMEZONE="Asia/Tokyo"
readonly XKBMODEL="pc105"
readonly XKBLAYOUT="jp"
readonly XKBVARIANT="OADG109A"

# GRUB
readonly GRUB_CMDLINE_LINUX_DEFAULT=""
#readonly GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"

# User
readonly USER_NAME="ubuntu"
readonly USER_PASSWORD='$6$LMqzniAEoBSSS4gu$mMmV91M3oXrIpYCxIM2AlgvjxUWH2OPmLptPkttULMYMRCaJsfYxSiIySVM1q/K/mJVrAXnNNQEK9PTciP2Oe.'
readonly USER_HOME_DIR="/home2/ubuntu"
readonly USER_LANG="ja_JP.UTF-8"

# systemd-networkd
readonly WOL="magic"
#readonly WOL="off"
readonly MDNS=true
