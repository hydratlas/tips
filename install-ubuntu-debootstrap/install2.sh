#!/bin/bash -eu
DISTRIBUTION="${1}"
HOSTNAME="${2}"
PUBKEYURL="${3}"
source ./install-config.sh
source ./install-common.sh
diskname-to-diskpath "${4:-}" "${5:-}"

diskpath-to-partitionpath "${DISK1_PATH}" "${DISK2_PATH}"

# Set UUIDs
get-filesystem-UUIDs

# Create fstab
FSTAB_ARRAY=()
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	FSTAB_ARRAY+=("/dev/disk/by-uuid/${ROOTFS_UUID} / btrfs ${BTRFS_OPTIONS},subvol=@ 0 0")
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

# Install arch-install-scripts
apt-get install -y arch-install-scripts

# Temporarily set language
LANG_BAK="${LANG}"
export LANG="${INSTALLATION_LANG}"

# Configure locale
arch-chroot "${MOUNT_POINT}" locale-gen "${INSTALLATION_LANG}"
if [ "${INSTALLATION_LANG}" != "${USER_LANG}" ]; then
	arch-chroot "${MOUNT_POINT}" locale-gen "${USER_LANG}"
fi
echo "LANG=${INSTALLATION_LANG}" | sudo tee "${MOUNT_POINT}/etc/default/locale" > /dev/null
cat "${MOUNT_POINT}/etc/default/locale" # confirmation
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive locales

# Configure time zone
arch-chroot "${MOUNT_POINT}" ln -sf "/usr/share/zoneinfo/${TIMEZONE}" "/etc/localtime"
readlink "/etc/localtime" # confirmation
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive tzdata

# Configure keyboard
perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"${XKBMODEL}\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"${XKBLAYOUT}\"/g;s/^XKBVARIANT=.+\$/XKBVARIANT=\"${XKBVARIANT}\"/g" "${MOUNT_POINT}/etc/default/keyboard"
cat "${MOUNT_POINT}/etc/default/keyboard" # confirmation
arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive keyboard-configuration

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
	sudo tee "${MOUNT_POINT}/etc/apt/sources.list.d/${DISTRIBUTION}.sources" << EOS > /dev/null &&
	Types: deb
	URIs: mirror+file:/etc/apt/sources.list.d/${DISTRIBUTION}-mirrors.txt
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
	sudo tee "${MOUNT_POINT}/etc/apt/sources.list.d/${DISTRIBUTION}-mirrors.txt" && << EOS > /dev/null
	${MIRROR1}	priority:1
	${MIRROR2}	priority:2
	${MIRROR3}
	EOS
	cat "${MOUNT_POINT}/etc/apt/sources.list.d/${DISTRIBUTION}-mirrors.txt" # confirmation
}
create-source-list-for-deb822-style

# Install packages
function install-packages () {
	local CANDIDATE_INSTALL_PACKAGES=()
	CANDIDATE_INSTALL_PACKAGES+=(${PACKAGES_TO_INSTALL[@]})
	local PACKAGE
	for PACKAGE in "${DEPENDENT_PACKAGES_TO_INSTALL[@]}"; do
		CANDIDATE_INSTALL_PACKAGES+=( $(apt-cache depends --important ${PACKAGE} | awk '/:/{print$2}') )
	done

	local INSTALL_PACKAGES=()
	for PACKAGE in "${CANDIDATE_INSTALL_PACKAGES[@]}"; do
		local INSTALL=true
		local NOT_INSTALL
		for NOT_INSTALL in "${PACKAGES_NOT_INSTALL[@]}"; do
			if [[ "$PACKAGE" == "$NOT_INSTALL" ]]; then
				INSTALL=false
				break
			fi
		done
		if $INSTALL; then
			INSTALL_PACKAGES+=("$PACKAGE")
		fi
	done
	
	DEBIAN_FRONTEND=noninteractive arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends $(IFS=" "; echo "${INSTALL_PACKAGES[*]} ${1:-}")
}

arch-chroot "${MOUNT_POINT}" apt-get update
DEBIAN_FRONTEND=noninteractive arch-chroot "${MOUNT_POINT}" apt-get dist-upgrade -y
ADD_PACKAGES=""
if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
	ADD_PACKAGES="${ADD_PACKAGES} btrfs-progs"
fi
if [ "xfs" = "${ROOT_FILESYSTEM}" ]; then
	ADD_PACKAGES="${ADD_PACKAGES} xfsprogs"
fi
install-packages "${ADD_PACKAGES}"

# Set Hostname
echo "${HOSTNAME}" | tee "${MOUNT_POINT}/etc/hostname" > /dev/null
cat "${MOUNT_POINT}/etc/hostname" # confirmation
echo "127.0.0.1 ${HOSTNAME}" | tee -a "${MOUNT_POINT}/etc/hosts" > /dev/null
cat "${MOUNT_POINT}/etc/hosts" # confirmation

# Create user
arch-chroot "${MOUNT_POINT}" useradd --password "${USER_PASSWORD}" --user-group --groups sudo --shell /bin/bash --create-home --home-dir "${USER_HOME_DIR}" "${USER_NAME}"
mkdir -p "${MOUNT_POINT}${USER_HOME_DIR}/.ssh"
wget -O "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/authorized_keys" "${PUBKEYURL}"
cat "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/authorized_keys" # confirmation
ssh-keygen -t ed25519 -N '' -C '' -f "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/id_ed25519"
arch-chroot "${MOUNT_POINT}" chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME_DIR}/.ssh"
arch-chroot "${MOUNT_POINT}" chmod u=rw,go= "${USER_HOME_DIR}/.ssh/authorized_keys"
echo "export LANG=${USER_LANG}" | tee -a "${MOUNT_POINT}${USER_HOME_DIR}/.bashrc" > /dev/null

export LANG="${LANG_BAK}"
