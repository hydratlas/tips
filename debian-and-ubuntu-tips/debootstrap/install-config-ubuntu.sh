#!/bin/sh
readonly SUITE="mantic"
readonly COMPONENTS=(main restricted universe multiverse)
readonly VARIANT="minbase"

readonly PACKAGES_TO_INSTALL_FIRST=(apt console-setup locales tzdata keyboard-configuration)
readonly PACKAGES_TO_INSTALL=( \
  linux-generic linux-firmware language-pack-ja landscape-common \
  intel-microcode amd64-microcode init initramfs-tools zstd libpam-systemd systemd-timesyncd \
  logrotate needrestart sudo unattended-upgrades \
  dmidecode efibootmgr fwupd iproute2 iputils-ping lsb-release pci.ids pciutils usb.ids usbutils \
  less bash-completion command-not-found nano whiptail \
  )
readonly DEPENDENT_PACKAGES_TO_INSTALL=() # ubuntu-minimal
readonly PACKAGES_NOT_INSTALL=( \
  netplan.io ubuntu-advantage-tools \
  dhcpcd-base kbd netbase netcat-openbsd vim-tiny \
  )
  # dhcpcd-base: DHCP client daemon
  # kbd: Linux keyboard tools
  # netbase: Network configuration tools
  # netcat-openbsd: Network tools
  # vim-tiny: Vim in compact version

readonly MIRROR1="http://ftp.udx.icscoe.jp/Linux/ubuntu"
readonly ARCHIVE_KEYRING_PACKAGE="ubuntu-keyring"
readonly ARCHIVE_KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
