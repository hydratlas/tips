#!/bin/bash -eu
function diskname-to-diskpath () {
	if [ -n "${1}" ]; then
		DISK1="/dev/${1}"
	else
		DISK1=""
	fi
	if [ -n "${2}" ]; then
		DISK2="/dev/${2}"
	else
		DISK2=""
	fi
}

function disk-to-partition () {
	if [ -e "${1}" ]; then
		DISK1_EFI="${1}1"
		DISK1_SWAP="${1}2"
		DISK1_ROOTFS="${1}3"
	fi
	if [ -e "${2}" ]; then
		DISK2_EFI="${2}1"
		DISK2_SWAP="${2}2"
		DISK2_ROOTFS="${2}3"
	fi
}

function mount-installfs () {
	if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
		mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@" --mkdir "${MOUNT_POINT}"
		mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@root" --mkdir "${MOUNT_POINT}/root"
		mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@var_log" --mkdir "${MOUNT_POINT}/var/log"
		mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@snapshots" --mkdir "${MOUNT_POINT}/.snapshots"
	else
		mount "${DISK1_ROOTFS}" -o "${EXT4_OPTIONS}" --mkdir "${MOUNT_POINT}"
	fi

	mount "${DISK1_EFI}" --mkdir "${MOUNT_POINT}/boot/efi"
	if [ -e "${DISK2}" ]; then
		mount "${DISK2_EFI}" --mkdir "${MOUNT_POINT}/boot/efi2"
	fi
}
