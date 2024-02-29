#!/bin/bash -eu
function diskname-to-diskpath () {
	if [ -n "${1}" ]; then
		DISK1_PATH="/dev/${1}"
	else
		DISK1_PATH=""
	fi
	if [ -n "${2}" ]; then
		DISK2_PATH="/dev/${2}"
	else
		DISK2_PATH=""
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
	elif [ "ext4" = "${ROOT_FILESYSTEM}" ]; then
		mount "${DISK1_ROOTFS}" -o "${EXT4_OPTIONS}" --mkdir "${MOUNT_POINT}"
	elif [ "xfs" = "${ROOT_FILESYSTEM}" ]; then
		mount "${DISK1_ROOTFS}" -o "${XFS_OPTIONS}" --mkdir "${MOUNT_POINT}"
	fi

	if [ -e "${DISK1_PATH}" ]; then
		mount "${DISK1_EFI}" --mkdir "${MOUNT_POINT}/boot/efi"
	fi
	if [ -e "${DISK2_PATH}" ]; then
		mount "${DISK2_EFI}" --mkdir "${MOUNT_POINT}/boot/efi2"
	fi
}
