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

function setup-grub-on-ubuntu () {
	arch-chroot "${MOUNT_POINT}" apt-get update
	DEBIAN_FRONTEND=noninteractive arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends shim-signed
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --recheck --no-nvram

	adding-entries-to-grub

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
	arch-chroot "${MOUNT_POINT}" apt-get update
	DEBIAN_FRONTEND=noninteractive arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends grub-efi-amd64 grub-efi-amd64-signed shim-signed
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --recheck --no-nvram

	adding-entries-to-grub

	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive grub-efi-amd64
	arch-chroot "${MOUNT_POINT}" update-grub
}
function adding-entries-to-grub () {
	PERL_SCRIPT=$(cat <<- EOS
	s/^#?GRUB_CMDLINE_LINUX_DEFAULT=.*\$/GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUB_CMDLINE_LINUX_DEFAULT}\"/g;
	s/^#?GRUB_TIMEOUT=.*\$/GRUB_TIMEOUT=\"${GRUB_TIMEOUT}\"/g;
	s/^#?GRUB_DISABLE_OS_PROBER=.*\$/GRUB_DISABLE_OS_PROBER=\"${GRUB_DISABLE_OS_PROBER}\"/g;
	EOS
	)
	perl -p -i -e "${PERL_SCRIPT}" "${MOUNT_POINT}/etc/default/grub"
	echo "GRUB_RECORDFAIL_TIMEOUT=${GRUB_TIMEOUT}" | tee -a "${MOUNT_POINT}/etc/default/grub" > /dev/null
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
}

LANG_BAK="${LANG}"
export LANG="${INSTALLATION_LANG}"

if [ "ubuntu" = "${DISTRIBUTION}" ]; then
	setup-grub-on-ubuntu
elif [ "debian" = "${DISTRIBUTION}" ]; then
	setup-grub-on-debian
fi

export LANG="${LANG_BAK}"
