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
KEYS=( \
  'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x790bc7277767219c42c86f933b4fe6acc0b21f32' \
    # Ubuntu Archive Automatic Signing Key (2012)
  'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xf6ecb3762474eda9d21b7022871920d1991bc93c' \
    # Ubuntu Archive Automatic Signing Key (2018)
  )
# SecurityTeam/FAQ - Ubuntu Wiki
# https://wiki.ubuntu.com/SecurityTeam/FAQ

# Base and Image
INSTALLATION_PACKAGES_FOR_BASE+=()
INSTALLATION_PACKAGES_FOR_IMAGE=(linux-image-amd64)

# Firmware
INSTALLATION_PACKAGES_FOR_FIRMWARE+=(firmware-linux fwupd-amd64-signed)

# systemd-timesyncd
FallbackNTP="0.debian.pool.ntp.org 1.debian.pool.ntp.org 2.debian.pool.ntp.org 3.debian.pool.ntp.org"

# GRUB
INSTALLATION_PACKAGES_FOR_GRUB+=(grub-efi-amd64 grub-efi-amd64-signed shim-signed)
