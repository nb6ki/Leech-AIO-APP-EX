#!/bin/bash

DATE_TIME() {
    date +"%m/%d %H:%M:%S"
}

UPLOAD_MODE="$(grep ^pyload-download-finished-upload-mode /mnt/data/config/script.conf | cut -d= -f2-)"
DELETE_EMPTY_DIR="$(grep ^delete-empty-dir /mnt/data/config/script.conf | cut -d= -f2-)"
DRIVE_NAME="$(grep ^drive-name /mnt/data/config/script.conf | cut -d= -f2-)"
PYLOAD_DOWNLOAD_DIR="$(grep ^'.*folder storage_folder' /workdir/.pyload/settings/pyload.cfg | cut -d= -f2- | sed "s/\r$//")"

DRIVE_NAME_AUTO="$(sed -n '1p' /mnt/data/config/rclone.conf | sed "s/.*\[//g;s/\].*//g;s/\r$//")"
if [ "${DRIVE_NAME}" = "auto" ]; then
    DRIVENAME=${DRIVE_NAME_AUTO}
else
    DRIVENAME=${DRIVE_NAME}
fi

GLOBAL_DRIVE_DIR="$(grep ^drive-dir /mnt/data/config/script.conf | cut -d= -f2-)"
PYLOAD_DRIVE_DIR="$(grep ^pyload-drive-dir /mnt/data/config/script.conf | cut -d= -f2-)"

if [ "${PYLOAD_DRIVE_DIR}" = "" ]; then
    DRIVE_DIR=${GLOBAL_DRIVE_DIR}/pyload
else
    DRIVE_DIR=${PYLOAD_DRIVE_DIR}
fi

FILE_PATH=$(echo $3 | sed 's:[^/]*$::')
DEST_PATH_SUFFIX="${FILE_PATH#"${PYLOAD_DOWNLOAD_DIR%/}"}"
REMOTE_PATH="${DRIVENAME}:${DRIVE_DIR}${DEST_PATH_SUFFIX}"

if [ "${UPLOAD_MODE}" = "disable" ]; then
    echo "$(DATE_TIME) [INFO] Auto-upload to Rclone remote disabled"
else
    curl -s -u ${GLOBAL_USER}:${GLOBAL_PASSWORD} -H "Content-Type: application/json" -f -X POST -d '{"srcFs":"'"${FILE_PATH}"'","srcRemote":"'"$2"'","dstFs":"'"${REMOTE_PATH}"'","dstRemote":"'"$2"'","_async":"true"}' 'localhost:61802/operations/'${UPLOAD_MODE}'file'
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -eq 0 ]; then
        echo "$(DATE_TIME) [INFO] Successfully send job to rclone: $3 -> ${REMOTE_PATH}"
    else
        echo "$(DATE_TIME) [ERROR] Failed to send job to rclone: $3"
    fi
fi

if [[ "${DELETE_EMPTY_DIR}" = "true" ]]; then
    find /mnt/data/pyload_downloads -depth -mindepth 1 -type d -empty -exec rm -vrf {} \; 2>/dev/null
fi