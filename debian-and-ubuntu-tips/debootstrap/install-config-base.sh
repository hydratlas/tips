#!/bin/sh
# Storage
ROOT_FILESYSTEM="btrfs"
BTRFS_OPTIONS="defaults,ssd,noatime,space_cache=v2,discard=async,compress=zstd:1,degraded"
EXT4_OPTIONS="defaults,noatime"
XFS_OPTIONS="defaults,noatime"
MOUNT_POINT="/mnt"
EFI_END="256MiB"
SWAP_END="4GiB"

# Debootstrap
INSTALLER="mmdebstrap" # debootstrap
CACHE_DIR="/tmp/debootstrap"

# Base and Image
INSTALLATION_PACKAGES_FOR_BASE=( \
  init initramfs-tools zstd libpam-systemd systemd-timesyncd \
  apt console-setup locales tzdata keyboard-configuration \
  logrotate sudo unattended-upgrades needrestart \
  dmidecode efibootmgr fwupd iproute2 iputils-ping lsb-release pci.ids pciutils usb.ids usbutils \
  less bash-completion command-not-found nano whiptail \
)
INSTALLATION_PACKAGES_FOR_IMAGE=()
INSTALLATION_PACKAGES=()

# Firmware
IS_FIRMWARE_INSTALLATION=true
INSTALLATION_PACKAGES_FOR_FIRMWARE=(intel-microcode amd64-microcode)

# QEMU Guest
IS_QEMU_GUEST_INSTALLATION=false
INSTALLATION_PACKAGES_FOR_QEMU_GUEST=(qemu-guest-agent)

# GNOME
IS_GNOME_INSTALLATION=false
INSTALLATION_PACKAGES_FOR_GNOME=( \
  adwaita-icon-theme desktop-base gdm3 gnome-session gnome-shell \
  gnome-keyring seahorse libpam-gnome-keyring \
  gnome-control-center gnome-tweaks gnome-online-accounts gnome-shell-extension-manager \
  gnome-console nautilus xdg-user-dirs-gtk \
  gnome-software flatpak gnome-software-plugin-flatpak \
  gnome-system-monitor gnome-firmware power-profiles-daemon \
  gnome-bluetooth-3-common pipewire-audio sound-theme-freedesktop \
  system-config-printer-udev system-config-printer-common cups-pk-helper \
)

# SSH Server
IS_SSH_SERVER_INSTALLATION=true
INSTALLATION_PACKAGES_FOR_SSH_SERVER=(openssh-server)

# systemd-networkd
IS_SYSTEMD_NETWORKD_INSTALLATION=true
INSTALLATION_PACKAGES_FOR_SYSTEMD_NETWORKD=(systemd-resolved)
WOL="magic" # off
MDNS=true

# NetworkManager
IS_NETWORK_MANAGER_INSTALLATION=false
INSTALLATION_PACKAGES_FOR_NETWORK_MANAGER=(network-manager systemd-resolved)

# GRUB
IS_GRUB_INSTALLATION=true
GRUB_CMDLINE_LINUX_DEFAULT="" # quiet splash
GRUB_TIMEOUT=1
GRUB_DISABLE_OS_PROBER=true

# Basic Settings
INSTALLATION_LANG="C.UTF-8"
TIMEZONE="Etc/UTC"
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
INSTALLATION_PACKAGES=()

# User
USER_NAME="newuser"
USER_PASSWORD='$6$c5PYNsRGtx0k3Z7x$pXFVWhtOuh09YwflSBQfaM6zNf.gW4DwHP9GB7MF3gWNeRstY.8E3mQVO7aU1CFThZsBAZYSNuO1/5Pecsg3p0'
USER_HOME_DIR="/home/newuser"
USER_LANG="C.UTF-8"
USER_PUBKEYURL=""
USER_NO_SUDO_PASSWORD=false
