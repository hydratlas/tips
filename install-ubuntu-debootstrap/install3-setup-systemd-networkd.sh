#!/bin/bash -eu
source ./install-config.sh

function setup-systemd-networkd () {
	if ${MDNS}; then
		local -r MDNS_STR="yes"
	else
		local -r MDNS_STR="no"
	fi

	arch-chroot "${MOUNT_POINT}" systemctl enable systemd-networkd

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
	Name=en*

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
}

setup-systemd-networkd
