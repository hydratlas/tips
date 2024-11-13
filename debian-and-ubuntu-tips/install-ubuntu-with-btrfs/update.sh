#!/bin/bash
set -eux

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

source "${SCRIPT_DIR}/scripts/initialize.sh" "${2}" "${3:-}"
source "${SCRIPT_DIR}/scripts/common.sh"

# インストーラーによるマウントがない場合、新しいインストールのbtrfsをデフォルトのマウントポイントでマウント
if [ -z "${TARGET}" ]; then
  export TARGET="/target"
  mount "/dev/${1}" -o "${BTRFS_OPTIONS}" "${TARGET}"
fi
cd "${TARGET}"

# 新しいインストールからスナップショットを所得
TMP_SNAPSHOT_NAME="$(date '+%Y%m%dT%H%M%S%z')_tmp"
btrfs subvolume snapshot . "${TMP_SNAPSHOT_NAME}"

# 新しいインストールから既存のインストールの@配下のサブボリュームと重複するファイルを削除
mkdir -p "${TMP_SNAPSHOT_NAME}/home"
find "${TMP_SNAPSHOT_NAME}/home" -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +
mkdir -p "${TMP_SNAPSHOT_NAME}/root"
find "${TMP_SNAPSHOT_NAME}/root" -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +
mkdir -p "${TMP_SNAPSHOT_NAME}/var/log"
find "${TMP_SNAPSHOT_NAME}/var/log" -mindepth 1 -maxdepth 1 -exec rm -dr "{}" +

# 既存のインストールのbtrfsを/からマウント
mount "/dev/disk/by-uuid/${ROOTFS_UUID}" -o "subvol=/,${BTRFS_OPTIONS}" "${MOUNT_POINT}"
cd "${MOUNT_POINT}"

# 既存のインストールの@サブボリュームを確認
if [ ! -e "${DEFAULT_SUBVOLUME_NAME}" ]; then
  echo "Error: ${DEFAULT_SUBVOLUME_NAME} Subvolume not found." 1>&2
  exit 1
fi

# 新しいインストールから既存のインストールへ転送
NEW_SNAPSHOT_NAME="$(date '+%Y%m%dT%H%M%S%z')_new"
btrfs subvolume snapshot -r "${TARGET}/${TMP_SNAPSHOT_NAME}" "${TARGET}/${NEW_SNAPSHOT_NAME}" # 新しいインストールのスナップショットを読み取り専用で作る
btrfs subvolume delete "${TARGET}/${TMP_SNAPSHOT_NAME}" # 転送元の書き込み可能なスナップショットを削除
btrfs send "${TARGET}/${NEW_SNAPSHOT_NAME}" | btrfs receive . # 読み取り専用のスナップショットを転送
btrfs subvolume delete "${TARGET}/${NEW_SNAPSHOT_NAME}" # 転送元の読み取り専用のスナップショットを削除

# @snapshotsサブボリュームがなければ
if [ ! -e "${SNAPSHOTS_SUBVOLUME_NAME}" ]; then
  # サブボリューム作成
  btrfs subvolume create "${SNAPSHOTS_SUBVOLUME_NAME}"
fi

# 既存の@サブボリュームの退避
OLD_SNAPSHOT_NAME="$(date '+%Y%m%dT%H%M%S%z')"
btrfs subvolume snapshot "${DEFAULT_SUBVOLUME_NAME}" "${SNAPSHOTS_SUBVOLUME_NAME}/${OLD_SNAPSHOT_NAME}"
btrfs subvolume set-default .
btrfs subvolume delete "${DEFAULT_SUBVOLUME_NAME}"

# 新しい@サブボリュームのリネーム
btrfs subvolume snapshot "${NEW_SNAPSHOT_NAME}" "${DEFAULT_SUBVOLUME_NAME}" # 新しいスナップショットを作ることによってリネーム
btrfs subvolume delete "${NEW_SNAPSHOT_NAME}" # リネーム前のスナップショットを削除

# @サブボリュームをデフォルト（GRUBがブートしようとする）に変更
btrfs subvolume set-default "${DEFAULT_SUBVOLUME_NAME}"

# fstabをコピー
cp -p "${SNAPSHOTS_SUBVOLUME_NAME}/${OLD_SNAPSHOT_NAME}/etc/fstab" "${DEFAULT_SUBVOLUME_NAME}/etc/fstab"

# 退避した既存の@サブボリュームから起動できるようにする
## fstabの修正
sed -i "s|subvol=${DEFAULT_SUBVOLUME_NAME},|subvol=${SNAPSHOTS_SUBVOLUME_NAME}/${OLD_SNAPSHOT_NAME},|g" "${SNAPSHOTS_SUBVOLUME_NAME}/${OLD_SNAPSHOT_NAME}/etc/fstab"

## GRUBメニューエントリーの作成
CREATE_SNAPSHOT_BOOT "${DEFAULT_SUBVOLUME_NAME}" "${SNAPSHOTS_SUBVOLUME_NAME}/${OLD_SNAPSHOT_NAME}"

# 縮退起動をサポート
CREATE_DEGRADED_BOOT "${DEFAULT_SUBVOLUME_NAME}"

# btrfsの/からのマウントをアンマウント
cd /
umount -l "${MOUNT_POINT}"

"$SCRIPT_DIR/scripts/finalize.sh"
