#!/bin/bash -eu
source ./install-config.sh
source ./install-common.sh
diskname-to-diskpath "${1}" "${2}"
disk-to-partition "${DISK1}" "${DISK2}"
mount-installfs
