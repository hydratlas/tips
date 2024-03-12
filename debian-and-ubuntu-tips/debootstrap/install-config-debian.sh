#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
source "${SCRIPT_DIR}/install-config-base.sh"

# Base
DISTRIBUTION="debian"
SUITE="bookworm"
COMPONENTS=(main contrib non-free non-free-firmware)
VARIANT="minbase"

# Packages
MIRROR1="http://ftp.jp.debian.org/debian"
ARCHIVE_KEYRING_PACKAGE="debian-archive-keyring"
ARCHIVE_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"

# Base and Image
INSTALLATION_PACKAGES_FOR_BASE+=()
INSTALLATION_PACKAGES_FOR_IMAGE=(linux-image-amd64)

# Firmware
INSTALLATION_PACKAGES_FOR_FIRMWARE+=(firmware-linux)

# GRUB
INSTALLATION_PACKAGES_FOR_GRUB+=(grub-efi-amd64 grub-efi-amd64-signed shim-signed)
