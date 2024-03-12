#!/bin/bash -eu
source "${1}"
readonly HOSTNAME="${2}"
source ./install-common.sh
diskname-to-diskpath "${3}" "${4:-}"
diskpath-to-partitionpath "${DISK1_PATH}" "${DISK2_PATH}"
get-filesystem-UUIDs

function install2 () {
	# Temporarily set language
	LANG_BAK="${LANG}"
	export LANG="${INSTALLATION_LANG}"

	# Configure locale
	PERL_SCRIPT=$(cat <<- EOS
	s/^#? *${INSTALLATION_LANG}/${INSTALLATION_LANG}/g;
	s/^#? *${USER_LANG}/${USER_LANG}/g;
	EOS
	)
	perl -p -i -e "${PERL_SCRIPT}" "${MOUNT_POINT}/etc/locale.gen"
	echo "LANG=${INSTALLATION_LANG}" | tee "${MOUNT_POINT}/etc/default/locale" > /dev/null
	cat "${MOUNT_POINT}/etc/default/locale" # confirmation

	# Configure time zone
	ln -sf "/usr/share/zoneinfo/${TIMEZONE}" "${MOUNT_POINT}/etc/localtime"
	readlink "/etc/localtime" # confirmation

	# Configure keyboard
	PERL_SCRIPT=$(cat <<- EOS
	s/^XKBMODEL=.+\$/XKBMODEL=\"${XKBMODEL}\"/g;
	s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"${XKBLAYOUT}\"/g;
	s/^XKBVARIANT=.+\$/XKBVARIANT=\"${XKBVARIANT}\"/g;
	EOS
	)
	perl -p -i -e "${PERL_SCRIPT}" "${MOUNT_POINT}/etc/default/keyboard"
	cat "${MOUNT_POINT}/etc/default/keyboard" # confirmation

	# arch-chroot
	arch-chroot "${MOUNT_POINT}" /bin/bash -eux -- <<- EOS
	locale-gen &&
	dpkg-reconfigure --frontend noninteractive locales
	dpkg-reconfigure --frontend noninteractive tzdata
	dpkg-reconfigure --frontend noninteractive keyboard-configuration
	EOS

	# Set hostname
	echo "${HOSTNAME}" | tee "${MOUNT_POINT}/etc/hostname" > /dev/null
	cat "${MOUNT_POINT}/etc/hostname" # confirmation
	echo "127.0.0.1 ${HOSTNAME}" | tee -a "${MOUNT_POINT}/etc/hosts" > /dev/null
	cat "${MOUNT_POINT}/etc/hosts" # confirmation

	# Create user
	arch-chroot "${MOUNT_POINT}" /bin/bash -eux -- <<- EOS
	passwd -l root
	useradd --password '${USER_PASSWORD}' --user-group --groups sudo --shell /bin/bash \
		--create-home --home-dir "${USER_HOME_DIR}" "${USER_NAME}"
	EOS
	mkdir -p "${MOUNT_POINT}${USER_HOME_DIR}/.ssh"
	wget -O "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/authorized_keys" "${PUBKEYURL}"
	chmod u=rw,go= "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/authorized_keys"
	cat "${MOUNT_POINT}${USER_HOME_DIR}/.ssh/authorized_keys" # confirmation
	arch-chroot "${MOUNT_POINT}" chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME_DIR}"
	echo "export LANG=${USER_LANG}" | tee -a "${MOUNT_POINT}${USER_HOME_DIR}/.bashrc" > /dev/null

	# Other installations
	if "${IS_SSH_SERVER_INSTALLATION}"; then
		setup-ssh-server
	fi
	if "${IS_SYSTEMD_NETWORKD_INSTALLATION}"; then
		setup-systemd-networkd
	fi
	if "${IS_GRUB_INSTALLATION}"; then
		setup-grub
	fi

	export LANG="${LANG_BAK}"
}
install2
