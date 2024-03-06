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

# Install arch-install-scripts
apt-get install -y arch-install-scripts

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
arch-chroot "${MOUNT_POINT}" locale-gen
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
arch-chroot "${MOUNT_POINT}" chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME_DIR}/.ssh"
arch-chroot "${MOUNT_POINT}" chmod u=rw,go= "${USER_HOME_DIR}/.ssh/authorized_keys"
echo "export LANG=${USER_LANG}" | tee -a "${MOUNT_POINT}${USER_HOME_DIR}/.bashrc" > /dev/null

export LANG="${LANG_BAK}"
