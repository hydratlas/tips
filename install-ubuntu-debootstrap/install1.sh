#!/bin/bash -eu
source ./install-config.sh
source ./install-common.sh
HOSTNAME="${1}"
PUBKEYURL="${2}"
diskname-to-diskpath "${3:-}" "${4:-}"

# Check
wget --spider "${PUBKEYURL}"

# Partitioning
function disk-partitioning () {
	wipefs --all "${1}"
	sgdisk \
		-Z \
		-n "0::${2}" -t 0:ef00 \
		-n "0::${3}" -t 0:8200 \
		-n "0::"     -t 0:8304 "${1}"
}
disk-partitioning "${DISK1_PATH}" "${EFI_END}" "${SWAP_END}"
if [ -e "${DISK2_PATH}" ]; then
	disk-partitioning "${DISK2_PATH}" "${EFI_END}" "${SWAP_END}"
fi

diskpath-to-partitionpath "${DISK1_PATH}" "${DISK2_PATH}"

# Formatting
mkfs.vfat -F 32 "${DISK1_EFI}"
mkswap "${DISK1_SWAP}"
if [ -e "${DISK2_PATH}" ]; then
	mkfs.vfat -F 32 "${DISK2_EFI}"
	mkswap "${DISK2_SWAP}"
fi
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	if [ -e "${DISK2_PATH}" ]; then
		mkfs.btrfs -f -d raid1 -m raid1 "${DISK1_ROOTFS}" "${DISK2_ROOTFS}"
	else
		mkfs.btrfs -f "${DISK1_ROOTFS}"
	fi
elif [ "ext4" = "${ROOT_FILESYSTEM}" ]; then
	mkfs.ext4 -F "${DISK1_ROOTFS}"
elif [ "xfs" = "${ROOT_FILESYSTEM}" ]; then
	mkfs.xfs -F "${DISK1_ROOTFS}"
fi

# Set UUIDs
get-filesystem-UUIDs

# Create Btrfs subvolumes
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS}" --mkdir "${MOUNT_POINT}"
	btrfs subvolume create "${MOUNT_POINT}/@"
	btrfs subvolume create "${MOUNT_POINT}/@root"
	btrfs subvolume create "${MOUNT_POINT}/@var_log"
	btrfs subvolume create "${MOUNT_POINT}/@snapshots"
	btrfs subvolume set-default "${MOUNT_POINT}/@"
	btrfs subvolume list "${MOUNT_POINT}" # confirmation
	umount "${MOUNT_POINT}"
fi

# Mount installation filesystem
mount-installfs

function install-distribution () {
	if [ "ubuntu" = "${DISTRIBUTION}" ]; then
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ubuntu-keyring
		local -r KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
	elif [ "debian" = "${DISTRIBUTION}" ]; then
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends debian-archive-keyring
		local -r KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"
	fi

	if [ "mmdebstrap" = "${INSTALLER}" ]; then
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mmdebstrap
		mmdebstrap --skip=check/empty --keyring="${KEYRING}" \
			--components="$(IFS=","; echo "${COMPONENTS[*]}")" --variant="${VARIANT}" --include="$(IFS=","; echo "${PREINSTALL_PACKAGES[*]}")" \
			"${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"
	elif [ "debootstrap" = "${DISTRIBUTION}" ]; then
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends debootstrap
		mkdir -p "${CACHE_DIR}"
		debootstrap --cache-dir="${CACHE_DIR}" --keyring="${KEYRING}" \
			--components="$(IFS=","; echo "${COMPONENTS[*]}")" --variant="${VARIANT}" --include="$(IFS=","; echo "${PREINSTALL_PACKAGES[*]}")" \
			"${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"
	fi
}

install-distribution

# Get snapshot
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	btrfs subvolume snapshot -r "${MOUNT_POINT}" "${MOUNT_POINT}/.snapshots/after-installation"
fi
