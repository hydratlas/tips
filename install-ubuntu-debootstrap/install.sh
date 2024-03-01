#!/bin/bash -eu
function disk-partitioning () {
	wipefs --all "${1}"
	sgdisk \
		-Z \
		-n "0::${2}" -t 0:ef00 \
		-n "0::${3}" -t 0:8200 \
		-n "0::"     -t 0:8304 "${1}"
}

function partitioning () {
	disk-partitioning "${DISK1_PATH}" "${EFI_END}" "${SWAP_END}"
	if [ -e "${DISK2_PATH}" ]; then
		disk-partitioning "${DISK2_PATH}" "${EFI_END}" "${SWAP_END}"
	fi

	disk-to-partition "${DISK1_PATH}" "${DISK2_PATH}"
}

function get-uuid () {
	local UUID="$(lsblk -dno UUID "${1}")"
	if [ -z "${UUID}" ]; then
		echo "Failed to get UUID of ${1}" 1>&2
		exit 1
	fi
	echo "${UUID}"
}

function pre-processing () {
	# Check
	wget --spider "${PUBKEYURL}"

	# Partitioning
	partitioning

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
	EFI1_UUID="$(get-uuid "${DISK1_EFI}")"
	SWAP1_UUID="$(get-uuid "${DISK1_SWAP}")"
	if [ -e "${DISK2_PATH}" ]; then
		EFI2_UUID="$(get-uuid "${DISK2_EFI}")"
		SWAP2_UUID="$(get-uuid "${DISK2_SWAP}")"
	fi
	ROOTFS_UUID="$(get-uuid "${DISK1_ROOTFS}")"

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
}

function processing () {
	# Install distribution
	#apt-get install -y mmdebstrap
	#mmdebstrap --skip=check/empty --components="main restricted universe multiverse" --variant=minbase --include="usrmerge" "${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"

	apt-get install -y debootstrap
	debootstrap --variant=minbase --include="usrmerge" "${SUITE}" "${MOUNT_POINT}" "${MIRROR1}"

	if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
		btrfs subvolume snapshot "${MOUNT_POINT}" "${MOUNT_POINT}/.snapshots/after-installation"
	fi
}

function install-packages () {
	local CANDIDATE_INSTALL_PACKAGES=()
	CANDIDATE_INSTALL_PACKAGES+=(${PACKAGES_TO_INSTALL[@]})
	local PACKAGE
	for PACKAGE in "${DEPENDENT_PACKAGES_TO_INSTALL[@]}"; do
		CANDIDATE_INSTALL_PACKAGES+=( $(apt-cache depends --important ubuntu-minimal | awk '/:/{print$2}') )
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
	
	arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends "${INSTALL_PACKAGES[@]}"
}

function post-processing () {
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
	local LANG_BAK="${LANG}"
	export LANG="${INSTALLATION_LANG}"

	# Configure locale
	arch-chroot "${MOUNT_POINT}" locale-gen "${INSTALLATION_LANG}"
	echo "LANG=\"${INSTALLATION_LANG}\"" | tee "${MOUNT_POINT}/etc/default/locale" > /dev/null
	cat "${MOUNT_POINT}/etc/default/locale" # confirmation
	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive locales

	# Configure time zone
	local TIMEZONE="${TIMEZONE_AREA}/${TIMEZONE_ZONE}"
	echo "${TIMEZONE}" | tee "${MOUNT_POINT}/etc/timezone" > /dev/null
 	cat "${MOUNT_POINT}/etc/timezone" # confirmation
 	arch-chroot "${MOUNT_POINT}" ln -sf "/usr/share/zoneinfo/${TIMEZONE}" "/etc/localtime"
	arch-chroot "${MOUNT_POINT}" readlink "/etc/localtime" # confirmation
	echo "tzdata tzdata/Areas select ${TIMEZONE_AREA}" | arch-chroot "${MOUNT_POINT}" debconf-set-selections &&
	echo "tzdata tzdata/Zones/${TIMEZONE_AREA} select ${TIMEZONE_ZONE}" | arch-chroot "${MOUNT_POINT}" debconf-set-selections &&
	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive tzdata

	# Configure keyboard
	perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"${XKBMODEL}\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"${XKBLAYOUT}\"/g" "${MOUNT_POINT}/etc/default/keyboard"
	cat "${MOUNT_POINT}/etc/default/keyboard" # confirmation
	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive keyboard-configuration

	# Create sources.list
	tee "${MOUNT_POINT}/etc/apt/sources.list" <<- EOS > /dev/null
	deb mirror+file:/etc/apt/mirrors.txt ${SUITE} main restricted universe multiverse
	deb mirror+file:/etc/apt/mirrors.txt ${SUITE}-updates main restricted universe multiverse
	deb mirror+file:/etc/apt/mirrors.txt ${SUITE}-backports main restricted universe multiverse
	deb http://security.ubuntu.com/ubuntu ${SUITE}-security main restricted universe multiverse
	EOS
	cat "${MOUNT_POINT}/etc/apt/sources.list" # confirmation

	tee "${MOUNT_POINT}/etc/apt/mirrors.txt" <<- EOS > /dev/null
	${MIRROR1}	priority:1
	${MIRROR2}	priority:2
	${MIRROR3}
	EOS
	cat "${MOUNT_POINT}/etc/apt/mirrors.txt" # confirmation

	# Install packages
	arch-chroot "${MOUNT_POINT}" apt-get update
	arch-chroot "${MOUNT_POINT}" apt-get dist-upgrade -y
 	install-packages

	if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
		arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends btrfs-progs
	fi
	if [ "xfs" = "${ROOT_FILESYSTEM}" ]; then
		arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends xfsprogs
	fi

	# Set Hostname
	echo "${HOSTNAME}" | tee "${MOUNT_POINT}/etc/hostname" > /dev/null
	cat "${MOUNT_POINT}/etc/hostname" # confirmation
	echo "127.0.0.1 ${HOSTNAME}" | tee -a "${MOUNT_POINT}/etc/hosts" > /dev/null
	cat "${MOUNT_POINT}/etc/hosts" # confirmation

	# Network setup
	arch-chroot "${MOUNT_POINT}" systemctl enable systemd-networkd

	tee "${MOUNT_POINT}/etc/systemd/network/20-wired.network" <<- EOS > /dev/null
	[Match]
	Name=en*

	[Network]
	DHCP=yes
	EOS
	cat "${MOUNT_POINT}/etc/systemd/network/20-wired.network" # confirmation

	# Create User
	arch-chroot "${MOUNT_POINT}" useradd --password "${USER_PASSWORD}" --user-group --groups sudo --shell /bin/bash --create-home --home-dir "${USER_HOME_DIR}" "${USER_NAME}"

	# Install SSH server
	arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends openssh-server

	mkdir -p "${MOUNT_POINT}${USER_HOME_DIR}/.ssh"
	wget -O "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/authorized_keys" "${PUBKEYURL}"
	cat "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/authorized_keys" # confirmation
	arch-chroot "${MOUNT_POINT}" chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME_DIR}/.ssh"
	arch-chroot "${MOUNT_POINT}" chmod u=rw,go= "${USER_HOME_DIR}/.ssh/authorized_keys"

	# Install GRUB
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --recheck --no-nvram

	if [ -e "${DISK2_PATH}" ]; then
		ESPs="${DISK1_EFI}, ${DISK2_EFI}"
	else
		ESPs="${DISK1_EFI}"
	fi
	echo "grub-efi grub-efi/install_devices multiselect ${ESPs}" | arch-chroot "${MOUNT_POINT}" debconf-set-selections

	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive shim-signed

	if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
		tee "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded" <<- EOF > /dev/null
		#!/bin/sh
		. "\$pkgdatadir/grub-mkconfig_lib"
		TITLE="\$(echo "\${GRUB_DISTRIBUTOR} (rootflags=degraded)" | grub_quote)"
		cat << EOS
		menuentry '\$TITLE' {
		  search --no-floppy --fs-uuid --set=root ${ROOTFS_UUID}
		  linux /@/boot/vmlinuz root=UUID=${ROOTFS_UUID} ro rootflags=subvol=@,degraded \${GRUB_CMDLINE_LINUX} \${GRUB_CMDLINE_LINUX_DEFAULT}
		  initrd /@/boot/initrd.img
		}
		EOS
		EOF
		chmod a+x "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded"

		cat "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded" # confirmation
	fi

	arch-chroot "${MOUNT_POINT}" update-grub

	export LANG="${LANG_BAK}"
}

DISK1="${3:-}"
DISK2="${4:-}"
source ./install-config.sh
source ./install-common.sh
HOSTNAME="${1}"
PUBKEYURL="${2}"
diskname-to-diskpath "${DISK1}" "${DISK2}"

pre-processing
processing
post-processing
