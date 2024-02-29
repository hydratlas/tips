#!/bin/bash -eu
if [ -n "${1}" ]; then
	DISK1="${1}"
else
	DISK1=""
fi
if [ -n "${2}" ]; then
	DISK2="${2}"
else
	DISK2=""
fi

source ./install-config.sh
source ./install-common.sh
diskname-to-diskpath "${DISK1}" "${DISK2}"
disk-to-partition "${DISK1_PATH}" "${DISK2_PATH}"
mount-installfs
