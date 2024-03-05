#!/bin/bash -eu
DISK1="${1:-}"
DISK2="${2:-}"

source ./install-config.sh
source ./install-common.sh
diskname-to-diskpath "${DISK1}" "${DISK2}"
diskpath-to-partitionpath "${DISK1_PATH}" "${DISK2_PATH}"

mount-installfs
