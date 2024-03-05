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

function diskpath-to-partitionpath () {
  if [ -e "${1}" ]; then
    DISK1_EFI="${1}1"
    DISK1_SWAP="${1}2"
    DISK1_ROOTFS="${1}3"
  else
    DISK1_EFI=""
    DISK1_SWAP=""
    DISK1_ROOTFS=""
  fi
  if [ -e "${2}" ]; then
    DISK2_EFI="${2}1"
    DISK2_SWAP="${2}2"
    DISK2_ROOTFS="${2}3"
  else
    DISK2_EFI=""
    DISK2_SWAP=""
    DISK2_ROOTFS=""
  fi
}

function get-fs-UUID () {
  local UUID="$(lsblk -dno UUID "${1}")"
  if [ -z "${UUID}" ]; then
    echo "Failed to get UUID of ${1}" 1>&2
    exit 1
  fi
  echo "${UUID}"
}

function get-filesystem-UUIDs () {
  EFI1_UUID="$(get-fs-UUID "${DISK1_EFI}")"
  SWAP1_UUID="$(get-fs-UUID "${DISK1_SWAP}")"
  if [ -e "${DISK2_PATH}" ]; then
    EFI2_UUID="$(get-fs-UUID "${DISK2_EFI}")"
    SWAP2_UUID="$(get-fs-UUID "${DISK2_SWAP}")"
  fi
  ROOTFS_UUID="$(get-fs-UUID "${DISK1_ROOTFS}")"
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

function create-source-list-for-one-line-style () {
	tee "${MOUNT_POINT}/etc/apt/sources.list" <<- EOS > /dev/null
	deb mirror+file:/etc/apt/mirrors.txt ${SUITE} $(IFS=" "; echo "${COMPONENTS[*]}")
	deb mirror+file:/etc/apt/mirrors.txt ${SUITE}-updates $(IFS=" "; echo "${COMPONENTS[*]}")
	deb mirror+file:/etc/apt/mirrors.txt ${SUITE}-backports $(IFS=" "; echo "${COMPONENTS[*]}")
	deb ${MIRROR_SECURITY} ${SUITE}-security $(IFS=" "; echo "${COMPONENTS[*]}")
	EOS
	cat "${MOUNT_POINT}/etc/apt/sources.list" # confirmation

	tee "${MOUNT_POINT}/etc/apt/mirrors.txt" <<- EOS > /dev/null
	${MIRROR1}	priority:1
	${MIRROR2}	priority:2
	${MIRROR3}
	EOS
	cat "${MOUNT_POINT}/etc/apt/mirrors.txt" # confirmation
}

function create-source-list-for-deb822-style () {
	tee "${MOUNT_POINT}/etc/apt/sources.list.d/${DISTRIBUTION}.sources" <<- EOS > /dev/null
	Types: deb
	URIs: mirror+file:/etc/apt/${DISTRIBUTION}-mirrors.txt
	Suites: $(lsb_release --short --codename) $(lsb_release --short --codename)-updates $(lsb_release --short --codename)-backports
	Components: $(IFS=" "; echo "${COMPONENTS[*]}")
	Signed-By: ${ARCHIVE_KEYRING}
	
	Types: deb
	URIs: ${MIRROR_SECURITY}
	Suites: $(lsb_release --short --codename)-security
	Components: $(IFS=" "; echo "${COMPONENTS[*]}")
	Signed-By: ${ARCHIVE_KEYRING}
	EOS
	cat "${MOUNT_POINT}/etc/apt/sources.list.d/ubuntu.sources" && # confirmation

	tee "${MOUNT_POINT}/etc/apt/${DISTRIBUTION}-mirrors.txt" <<- EOS > /dev/null
	${MIRROR1}	priority:1
	${MIRROR2}	priority:2
	${MIRROR3}
	EOS
	cat "${MOUNT_POINT}/etc/apt/${DISTRIBUTION}-mirrors.txt" # confirmation

	if [ -f "${MOUNT_POINT}/etc/apt/sources.list" ]; then
		rm "${MOUNT_POINT}/etc/apt/sources.list"
	fi
}
