#!/bin/sh
readonly SUITE="mantic"
readonly COMPONENTS=(main restricted universe multiverse)
readonly VARIANT="minbase"

readonly PACKAGES_TO_INSTALL=( \
  linux-generic linux-firmware intel-microcode amd64-microcode \
  initramfs-tools libpam-systemd systemd-timesyncd \
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
  dhcpcd-base: DHCP client daemon
  # kbd: Linux keyboard tools
  # netbase: Network configuration tools
  # netcat-openbsd: Network tools
  # vim-tiny: Vim in compact version

readonly MIRROR1="http://ftp.udx.icscoe.jp/Linux/ubuntu/"
readonly MIRROR2="https://linux.yz.yamagata-u.ac.jp/ubuntu/"
readonly MIRROR3="http://jp.archive.ubuntu.com/ubuntu/"
readonly MIRROR_SECURITY="http://security.ubuntu.com/ubuntu"
readonly ARCHIVE_KEYRING_PACKAGE="ubuntu-keyring"
readonly ARCHIVE_KEYRING_PACKAGE="debian-archive-keyring"
readonly ARCHIVE_KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

