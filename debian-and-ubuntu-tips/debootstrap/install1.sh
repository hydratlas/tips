#!/bin/bash -eu
DISTRIBUTION="${1}"
HOSTNAME="${2}"
PUBKEYURL="${3}"
source ./install-config.sh
source ./install-common.sh
diskname-to-diskpath "${4:-}" "${5:-}"

if [ "mmdebstrap" = "${INSTALLER}" ]; then
	P="mmdebstrap"
elif [ "debootstrap" = "${INSTALLER}" ]; then
	P="debootstrap"
fi
P="${P} efibootmgr gdisk wget"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${P}

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
mkswap "${DISK1_SWAP}"
mkfs.vfat -F 32 "${DISK1_EFI}"
mkswap "${DISK1_SWAP}" # The UUID cannot be read without formatting it twice.
if [ -e "${DISK2_PATH}" ]; then
	mkswap "${DISK2_SWAP}"
	mkfs.vfat -F 32 "${DISK2_EFI}"
	mkswap "${DISK2_SWAP}" # The UUID cannot be read without formatting it twice.
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
	mkfs.xfs -f "${DISK1_ROOTFS}"
fi

# Create Btrfs subvolumes
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS}" --mkdir "${MOUNT_POINT}"
	btrfs subvolume create "${MOUNT_POINT}/@"
	btrfs subvolume create "${MOUNT_POINT}/@home"
	btrfs subvolume create "${MOUNT_POINT}/@home2"
	btrfs subvolume create "${MOUNT_POINT}/@root"
	btrfs subvolume create "${MOUNT_POINT}/@var_log"
	btrfs subvolume create "${MOUNT_POINT}/@snapshots"
	btrfs subvolume set-default "${MOUNT_POINT}/@"
	btrfs subvolume list "${MOUNT_POINT}" # confirmation
	umount "${MOUNT_POINT}"
fi

# Set UUIDs
get-filesystem-UUIDs

# Mount installation filesystem
mount-installfs

function install-distribution () {
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ${ARCHIVE_KEYRING_PACKAGE}

	local PACKAGES=()
	PACKAGES+=(${PACKAGES_TO_INSTALL_FIRST[@]})
	PACKAGES+=(${PACKAGES_TO_INSTALL[@]})
	if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
		PACKAGES+=(btrfs-progs)
	fi
	if [ "xfs" = "${ROOT_FILESYSTEM}" ]; then
		PACKAGES+=(xfsprogs)
	fi

	if [ "mmdebstrap" = "${INSTALLER}" ]; then
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mmdebstrap
		mmdebstrap --skip=check/empty --keyring="${ARCHIVE_KEYRING}" \
			--components="$(IFS=","; echo "${COMPONENTS[*]}")" --variant="${VARIANT}" --include="$(IFS=","; echo "${PACKAGES[*]}")" \
			"${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"
	elif [ "debootstrap" = "${INSTALLER}" ]; then
		DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends debootstrap
		mkdir -p "${CACHE_DIR}"
		if [ "standard" = "${VARIANT}" ]; then
			debootstrap --cache-dir="${CACHE_DIR}" --keyring="${ARCHIVE_KEYRING}" \
				--components="$(IFS=","; echo "${COMPONENTS[*]}")" --include="$(IFS=","; echo "${PACKAGES[*]}")" \
				"${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"
		else
			debootstrap --cache-dir="${CACHE_DIR}" --keyring="${ARCHIVE_KEYRING}" --variant="${VARIANT}" \
				--components="$(IFS=","; echo "${COMPONENTS[*]}")" --include="$(IFS=","; echo "${PACKAGES[*]}")" \
				"${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"
		fi
	fi
}

install-distribution

# Create fstab
FSTAB_ARRAY=()
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} / btrfs ${BTRFS_OPTIONS},subvol=@ 0 0")
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} /home btrfs ${BTRFS_OPTIONS},subvol=@home 0 0")
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} /home2 btrfs ${BTRFS_OPTIONS},subvol=@home2 0 0")
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} /root btrfs ${BTRFS_OPTIONS},subvol=@root 0 0")
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} /var/log btrfs ${BTRFS_OPTIONS},subvol=@var_log 0 0")
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} /.snapshots btrfs ${BTRFS_OPTIONS},subvol=@snapshots 0 0")
elif [ "ext4" = "${ROOT_FILESYSTEM}" ]; then
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} / ext4 ${EXT4_OPTIONS} 0 0")
elif [ "xfs" = "${ROOT_FILESYSTEM}" ]; then
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} / xfs ${XFS_OPTIONS} 0 0")
fi

FSTAB_ARRAY+=("/dev/disk/by-uuid/${EFI1_UUID} /boot/efi vfat defaults,nofail,x-systemd.device-timeout=5 0 0")
FSTAB_ARRAY+=("/dev/disk/by-uuid/${SWAP1_UUID} none swap sw,nofail,x-systemd.device-timeout=5 0 0")

if [ -e "${DISK2_PATH}" ]; then
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${EFI2_UUID} /boot/efi2 vfat defaults,nofail,x-systemd.device-timeout=5 0 0")
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${SWAP2_UUID} none swap sw,nofail,x-systemd.device-timeout=5 0 0")
fi
printf "%s\n" "${FSTAB_ARRAY[@]}" | tee "${MOUNT_POINT}/etc/fstab" > /dev/null
cat "${MOUNT_POINT}/etc/fstab" # confirmation

# Create kernel-img.conf
tee "${MOUNT_POINT}/etc/kernel-img.conf" <<- EOS > /dev/null
do_symlinks = yes
do_bootloader = no
do_initrd = yes
link_in_boot = yes
EOS

# Get snapshot
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	btrfs subvolume snapshot -r "${MOUNT_POINT}" "${MOUNT_POINT}/.snapshots/after-installation"
fi
