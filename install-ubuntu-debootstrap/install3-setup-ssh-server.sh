#!/bin/bash -eu
source ./install-config.sh

function setup-ssh-server () {
	DEBIAN_FRONTEND=noninteractive arch-chroot "${MOUNT_POINT}" apt-get install -y --no-install-recommends openssh-server
	tee "${MOUNT_POINT}/etc/ssh/ssh_config.d/20-local.conf" <<- EOS > /dev/null
	PasswordAuthentication no
	PermitRootLogin no
	EOS
	cat "${MOUNT_POINT}/etc/ssh/ssh_config.d/20-local.conf" # confirmation
}

setup-ssh-server