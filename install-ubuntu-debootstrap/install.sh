#!/bin/bash -eu
function disk-partitioning () {
	wipefs --all "${1}"
	sgdisk \
		-Z \
		-n "0::${2}" -t 0:ef00 \
		-n "0::${3}" -t 0:8200 \
		-n "0::"     -t 0:fd00 "${1}"
}

function partitioning () {
	disk-partitioning "${DISK1}" "${EFI_END}" "${SWAP_END}"
	if [ -e "${DISK2}" ]; then
		disk-partitioning "${DISK2}" "${EFI_END}" "${SWAP_END}"
	fi

	disk-to-partition "${DISK1}" "${DISK2}"
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
	if [ -e "${DISK2}" ]; then
		mkfs.vfat -F 32 "${DISK2_EFI}"
		mkswap "${DISK2_SWAP}"
		mkfs.btrfs -f -d raid1 -m raid1 "${DISK1_ROOTFS}" "${DISK2_ROOTFS}"
	else
		mkfs.btrfs -f "${DISK1_ROOTFS}"
	fi

	# Set UUIDs
	EFI1_UUID="$(get-uuid "${DISK1_EFI}")"
	SWAP1_UUID="$(get-uuid "${DISK1_SWAP}")"
	if [ -e "${DISK2}" ]; then
		EFI2_UUID="$(get-uuid "${DISK2_EFI}")"
		SWAP2_UUID="$(get-uuid "${DISK2_SWAP}")"
	fi
	ROOTFS_UUID="$(get-uuid "${DISK1_ROOTFS}")"

	# Create subvolumes
	mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS}" --mkdir "${MOUNT_POINT}"
	btrfs subvolume create "${MOUNT_POINT}/@"
	btrfs subvolume create "${MOUNT_POINT}/@root"
	btrfs subvolume create "${MOUNT_POINT}/@var_log"
	btrfs subvolume create "${MOUNT_POINT}/@snapshots"
	btrfs subvolume set-default "${MOUNT_POINT}/@"
	btrfs subvolume list "${MOUNT_POINT}" # confirmation
	umount "${MOUNT_POINT}"

	# Mount Btrfs
	mount-installfs
}

function processing () {
	# Install distribution
	#apt-get install -y mmdebstrap
	#mmdebstrap --skip=check/empty --components="main restricted universe multiverse" "${SUITE}" "${MOUNT_POINT}" "${INSTALLATION_MIRROR}"

	apt-get install -y debootstrap
	debootstrap "${SUITE}" "${MOUNT_POINT}" "${INSTALLATION_MIRROR}"

	btrfs subvolume snapshot "${MOUNT_POINT}" "${MOUNT_POINT}/.snapshots/after-installation"
}

function post-processing () {
	local LANG_BAK="${LANG}"
	export LANG="${INSTALLATION_LANG}"

	# Install arch-install-scripts
	apt-get install -y arch-install-scripts

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
	deb ${PERMANENT_MIRROR} ${SUITE} main restricted universe multiverse
	deb ${PERMANENT_MIRROR} ${SUITE}-updates main restricted universe multiverse
	deb ${PERMANENT_MIRROR} ${SUITE}-backports main restricted universe multiverse
	deb http://security.ubuntu.com/ubuntu ${SUITE}-security main restricted universe multiverse
	EOS

	# Create fstab
	FSTAB_BASE=`cat <<- EOS
	/dev/disk/by-uuid/${ROOTFS_UUID} / btrfs ${BTRFS_OPTIONS},subvol=@ 0 0
	/dev/disk/by-uuid/${ROOTFS_UUID} /root btrfs ${BTRFS_OPTIONS},subvol=@root 0 0
	/dev/disk/by-uuid/${ROOTFS_UUID} /var/log btrfs ${BTRFS_OPTIONS},subvol=@var_log 0 0
	/dev/disk/by-uuid/${ROOTFS_UUID} /.snapshots btrfs ${BTRFS_OPTIONS},subvol=@snapshots 0 0
	EOS`
	FSTAB_DISK1=`cat <<- EOS
	/dev/disk/by-uuid/${EFI1_UUID} /boot/efi vfat defaults,nofail,x-systemd.device-timeout=5 0 0
	/dev/disk/by-uuid/${SWAP1_UUID} none swap sw,nofail,x-systemd.device-timeout=5 0 0
	EOS`
	FSTAB="${FSTAB_BASE}${FSTAB_DISK1}"
	if [ -e "${DISK2}" ]; then
		FSTAB_DISK2=`cat <<- EOS
		/dev/disk/by-uuid/${EFI2_UUID} /boot/efi2 vfat defaults,nofail,x-systemd.device-timeout=5 0 0
		/dev/disk/by-uuid/${SWAP2_UUID} none swap sw,nofail,x-systemd.device-timeout=5 0 0
		EOS`
		FSTAB="${FSTAB}${FSTAB_DISK2}"
	fi
	echo "$FSTAB" | tee "${MOUNT_POINT}/etc/fstab" > /dev/null

	# Set Hostname
	echo "${HOSTNAME}" | tee "${MOUNT_POINT}/etc/hostname" > /dev/null
	echo "127.0.0.1 ${HOSTNAME}" | tee -a "${MOUNT_POINT}/etc/hosts" > /dev/null

	# Create User
	mkdir -p "${MOUNT_POINT}/home2/${USERNAME}"
	arch-chroot "${MOUNT_POINT}" useradd --user-group --groups sudo --shell /bin/bash --create-home --home-dir "${MOUNT_POINT}/home2/${USERNAME}" "${USERNAME}"

	# Configure SSH
	mkdir "${MOUNT_POINT}/home2/${USERNAME}/.ssh"
	wget -O "${MOUNT_POINT}/home2/${USERNAME}/.ssh/authorized_keys" "${PUBKEYURL}"
	arch-chroot "${MOUNT_POINT}" chown -R "${USERNAME}:${USERNAME}" "/home2/${USERNAME}/.ssh"
	arch-chroot "${MOUNT_POINT}" chmod u=rw,go= "/home2/${USERNAME}/.ssh/authorized_keys"

	# Install Packages
	arch-chroot "${MOUNT_POINT}" apt-get update
	arch-chroot "${MOUNT_POINT}" apt-get dist-upgrade -y
	arch-chroot "${MOUNT_POINT}" apt-get install -y linux-{,image-,headers-}generic linux-firmware initramfs-tools efibootmgr shim-signed openssh-server nano

	# Install GRUB
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --recheck

	if [ -e "${DISK2}" ]; then
		ESPs="${DISK1_EFI}, ${DISK2_EFI}"
	else
		ESPs="${DISK1_EFI}"
	fi
	echo "grub-efi grub-efi/install_devices multiselect ${ESPs}" | arch-chroot "${MOUNT_POINT}" debconf-set-selections

	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive shim-signed

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

	arch-chroot "${MOUNT_POINT}" update-grub

	export LANG="${LANG_BAK}"
}

source ./install-config.sh
source ./install-common.sh
HOSTNAME="${1}"
PUBKEYURL="${2}"
diskname-to-diskpath "${3}" "${4}"

pre-processing
processing
post-processing
