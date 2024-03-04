#!/bin/bash -eu
source ./install-config.sh

function setup-grub () {
	DEBIAN_FRONTEND=noninteractive arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends shim-signed
	arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory=/boot/efi --recheck --no-nvram

	if [ -e "${DISK2_PATH}" ]; then
		ESPs="${DISK1_EFI}, ${DISK2_EFI}"
	else
		ESPs="${DISK1_EFI}"
	fi
	echo "grub-efi grub-efi/install_devices multiselect ${ESPs}" | arch-chroot "${MOUNT_POINT}" debconf-set-selections

	arch-chroot "${MOUNT_POINT}" dpkg-reconfigure --frontend noninteractive shim-signed

	perl -p -i -e "s/^#?GRUB_CMDLINE_LINUX_DEFAULT=.*\$/GRUB_CMDLINE_LINUX_DEFAULT=\"${GRUB_CMDLINE_LINUX_DEFAULT}\"/g" "${MOUNT_POINT}/etc/default/grub"
	echo "GRUB_RECORDFAIL_TIMEOUT=0" | tee -a "${MOUNT_POINT}/etc/default/grub" > /dev/null

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

setup-grub