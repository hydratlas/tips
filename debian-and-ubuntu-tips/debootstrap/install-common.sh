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
		mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@home" --mkdir "${MOUNT_POINT}/home"
		mount "${DISK1_ROOTFS}" -o "${BTRFS_OPTIONS},subvol=@home2" --mkdir "${MOUNT_POINT}/home2"
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

# GRUB
function setup-grub () {
	if [ "ubuntu" = "${DISTRIBUTION}" ]; then
		setup-grub-on-ubuntu
	elif [ "debian" = "${DISTRIBUTION}" ]; then
		setup-grub-on-debian
	fi
	efibootmgr -v
}
function setup-grub-on-ubuntu () {
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --no-nvram

	adding-entries-to-grub "/@/boot/vmlinuz" "/@/boot/initrd.img"
	arch-chroot "${MOUNT_POINT}" update-grub

	if [ -e "${DISK2_PATH}" ]; then
		local -r ESPs="${DISK1_EFI}, ${DISK2_EFI}"
	else
		local -r ESPs="${DISK1_EFI}"
	fi
	echo "grub-efi grub-efi/install_devices multiselect ${ESPs}" | arch-chroot "${MOUNT_POINT}" debconf-set-selections
	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive shim-signed
	arch-chroot "${MOUNT_POINT}" update-grub
}
function setup-grub-on-debian () {
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --no-nvram

	adding-entries-to-grub "/@/boot/vmlinuz" "/@/boot/initrd.img" # /etc/kernel-img.conf link_in_boot = yes
	arch-chroot "${MOUNT_POINT}" update-grub

	if [ -e "${DISK2_PATH}" ]; then
		create-second-esp-entry
	fi

	echo "grub-efi-amd64 grub2/force_efi_extra_removable boolean true" | arch-chroot "${MOUNT_POINT}" debconf-set-selections 
	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive grub-efi-amd64
	arch-chroot "${MOUNT_POINT}" update-grub
}
function adding-entries-to-grub () {
	local -r LINUX_PATH="${1}"
	local -r INITRD_PATH="${2}"
	local -r PERL_SCRIPT=$(cat <<- EOS
	s/^#?GRUB_CMDLINE_LINUX_DEFAULT=.*\$/GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUB_CMDLINE_LINUX_DEFAULT}\"/g;
	s/^#?GRUB_TIMEOUT=.*\$/GRUB_TIMEOUT=${GRUB_TIMEOUT}/g;
	s/^#?GRUB_DISABLE_OS_PROBER=.*\$/GRUB_DISABLE_OS_PROBER=${GRUB_DISABLE_OS_PROBER}/g;
	EOS
	)
	perl -p -i -e "${PERL_SCRIPT}" "${MOUNT_POINT}/etc/default/grub"
	echo "GRUB_RECORDFAIL_TIMEOUT=${GRUB_TIMEOUT}" | tee -a "${MOUNT_POINT}/etc/default/grub" > /dev/null
	if [ "btrfs" = "${ROOT_FILESYSTEM}" ]; then
		mkdir -p "${MOUNT_POINT}/etc/grub.d"
		tee "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded" <<- EOF > /dev/null
		#!/bin/sh
		. "\$pkgdatadir/grub-mkconfig_lib"
		TITLE="\$(echo "\${GRUB_DISTRIBUTOR} (rootflags=degraded)" | grub_quote)"
		cat << EOS
		menuentry '\$TITLE' {
			search --no-floppy --fs-uuid --set=root ${ROOTFS_UUID}
			linux ${LINUX_PATH} root=UUID=${ROOTFS_UUID} ro rootflags=subvol=@,degraded \${GRUB_CMDLINE_LINUX} \${GRUB_CMDLINE_LINUX_DEFAULT}
			initrd ${INITRD_PATH}
		}
		EOS
		EOF
		chmod a+x "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded"

		cat "${MOUNT_POINT}/etc/grub.d/19_linux_rootflags_degraded" # confirmation
	fi
}
function create-second-esp-entry () {
	local -r DISTRIBUTOR="$(arch-chroot "${MOUNT_POINT}" lsb_release -i -s 2> /dev/null || echo Debian)"
	local -r ENTRY_LABEL="${DISTRIBUTOR} (Second EFI system partition)"
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi2 --removable --no-nvram
	local -r DISK2_EFI_PART="${DISK2_EFI: -1}" && # A space is required before the minus sign.
	local -r PATTERN="^Boot([0-9A-F]+)\* (.+)$" &&
	efibootmgr | while read LINE; do
		if [[ ${LINE} =~ $PATTERN ]]; then
			if [[ "${ENTRY_LABEL}" == "${BASH_REMATCH[2]}" ]]; then
				efibootmgr -b "${BASH_REMATCH[1]}" -B
			fi
		fi
	done

	arch-chroot "${MOUNT_POINT}" efibootmgr --quiet --create-only --disk "${DISK2_PATH}" --part "${DISK2_EFI_PART}" \
		--loader /EFI/BOOT/bootx64.efi --label "${ENTRY_LABEL}" --unicode 
}

# SSH server
function setup-ssh-server () {
	tee "${MOUNT_POINT}/etc/ssh/ssh_config.d/20-local.conf" <<- EOS > /dev/null
	PasswordAuthentication no
	PermitRootLogin no
	EOS
	cat "${MOUNT_POINT}/etc/ssh/ssh_config.d/20-local.conf" # confirmation
}

# systemd-networkd
function setup-systemd-networkd () {
	if ${MDNS}; then
		local -r MDNS_STR="yes"
	else
		local -r MDNS_STR="no"
	fi

	arch-chroot "${MOUNT_POINT}" systemctl enable systemd-networkd.service

	# Configure basic settings
	tee "${MOUNT_POINT}/etc/systemd/network/20-wired.network" <<- EOS > /dev/null
	[Match]
	Name=en*

	[Network]
	DHCP=yes
	MulticastDNS=${MDNS_STR}
	EOS
	cat "${MOUNT_POINT}/etc/systemd/network/20-wired.network" # confirmation

	# Configure Wake On LAN
	tee "${MOUNT_POINT}/etc/systemd/network/50-wired.link" <<- EOS > /dev/null
	[Match]
	OriginalName=*

	[Link]
	WakeOnLan=${WOL}
	EOS
	cat "${MOUNT_POINT}/etc/systemd/network/50-wired.link" # confirmation

	perl -p -i -e "s/^#?MulticastDNS=.*\$/MulticastDNS=${MDNS_STR}/g" "${MOUNT_POINT}/etc/systemd/resolved.conf"

	# If one interface can be connected, it will start without waiting.
	mkdir -p "${MOUNT_POINT}/etc/systemd/system/systemd-networkd-wait-online.service.d"
	tee "${MOUNT_POINT}/etc/systemd/system/systemd-networkd-wait-online.service.d/wait-for-only-one-interface.conf" <<- EOS > /dev/null
	[Service]
	ExecStart=
	ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any
	EOS
	cat "${MOUNT_POINT}/etc/systemd/system/systemd-networkd-wait-online.service.d/wait-for-only-one-interface.conf" # confirmation
}
