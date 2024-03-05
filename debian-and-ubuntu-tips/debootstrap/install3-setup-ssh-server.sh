#!/bin/bash -eu
DISTRIBUTION="${1}"
HOSTNAME="${2}"
PUBKEYURL="${3}"
source ./install-config.sh
source ./install-common.sh
diskname-to-diskpath "${4:-}" "${5:-}"

function setup-ssh-server () {
	arch-chroot "${MOUNT_POINT}" apt-get update
	DEBIAN_FRONTEND=noninteractive arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends openssh-server
	tee "${MOUNT_POINT}/etc/ssh/ssh_config.d/20-local.conf" <<- EOS > /dev/null
	PasswordAuthentication no
	PermitRootLogin no
	EOS
	cat "${MOUNT_POINT}/etc/ssh/ssh_config.d/20-local.conf" # confirmation
}

LANG_BAK="${LANG}"
export LANG="${INSTALLATION_LANG}"

setup-ssh-server

export LANG="${LANG_BAK}"
