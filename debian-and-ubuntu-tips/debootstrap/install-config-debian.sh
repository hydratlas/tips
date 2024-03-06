#!/bin/sh
readonly SUITE="bookworm"
readonly COMPONENTS=(main contrib non-free non-free-firmware)
readonly VARIANT="minbase"

readonly PACKAGES_TO_INSTALL_FIRST=(apt console-setup locales tzdata keyboard-configuration)
readonly PACKAGES_TO_INSTALL=( \
  linux-image-amd64 firmware-linux intel-microcode amd64-microcode \
  initramfs-tools zstd libpam-systemd systemd-timesyncd \
  e2fsprogs-l10n logrotate needrestart sudo unattended-upgrades \
  dmidecode efibootmgr fwupd pci.ids pciutils usb.ids usbutils \
  bash-completion command-not-found nano \
  task-japanese \
  )
readonly DEPENDENT_PACKAGES_TO_INSTALL=()
readonly PACKAGES_NOT_INSTALL=()

readonly MIRROR1="http://ftp.jp.debian.org/debian"
readonly MIRROR2="https://debian-mirror.sakura.ne.jp/debian"
readonly MIRROR3="http://cdn.debian.or.jp/debian"
readonly MIRROR_SECURITY="http://security.debian.org/debian-security"
readonly ARCHIVE_KEYRING_PACKAGE="debian-archive-keyring"
readonly ARCHIVE_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
