#!/bin/bash

# Set a fixed value
EMMC_NAME=$(lsblk | grep -oE '(mmcblk[0-9])' | sort | uniq)
FIRMWARE_DOWNLOAD_PATH="/mnt/${EMMC_NAME}p4"
TMP_CHECK_DIR="/tmp/amlogic"
AMLOGIC_SOC_FILE="/etc/flippy-openwrt-release"
START_LOG="${TMP_CHECK_DIR}/amlogic_check_firmware.log"
LOG_FILE="${TMP_CHECK_DIR}/amlogic.log"
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
[[ -d ${TMP_CHECK_DIR} ]] || mkdir -p ${TMP_CHECK_DIR}

# Log function
tolog() {
    echo -e "${1}" >$START_LOG
    echo -e "${LOGTIME} ${1}" >>$LOG_FILE
    [[ -z "${2}" ]] || exit 1
}

    # 01. Query local version information
    tolog "01. 查询本地固件版本信息"
    CURRENT_KERNEL_V=$(ls /lib/modules/  2>/dev/null | grep -oE '^[1-9].[0-9]{1,2}.[0-9]+')
    tolog "01.01 当前版本: ${CURRENT_KERNEL_V}"
    MAIN_LINE_VER=$(echo "${CURRENT_KERNEL_V}" | cut -d '.' -f1)
    MAIN_LINE_MAJ=$(echo "${CURRENT_KERNEL_V}" | cut -d '.' -f2)
    MAIN_LINE_VERSION="${MAIN_LINE_VER}.${MAIN_LINE_MAJ}"
    sleep 3

    # 02. Download server version documentation
    tolog "02. 查询远程服务器固件版本信息."
    SERVER_FIRMWARE_URL=$(uci get amlogic.config.amlogic_firmware_repo 2>/dev/null)
    [[ ! -z "${SERVER_FIRMWARE_URL}" ]] || tolog "02.01 固件仓库地址设置错误!" "1"
    RELEASES_TAG_KEYWORDS=$(uci get amlogic.config.amlogic_firmware_tag 2>/dev/null)
    [[ ! -z "${RELEASES_TAG_KEYWORDS}" ]] || tolog "02.02 固件标签关键字设置错误!" "1"
    FIRMWARE_SUFFIX=$(uci get amlogic.config.amlogic_firmware_suffix 2>/dev/null)
    [[ ! -z "${FIRMWARE_SUFFIX}" ]] || tolog "02.03 固件文件后缀设置错误!" "1"

    # 03. Version comparison
    tolog "03. 对比版本信息"
    source ${AMLOGIC_SOC_FILE} 2>/dev/null
    SOC=${SOC}
    [[ ! -z "${SOC}" ]] || tolog "03.01 服务器版本不是最新！" "1"
    tolog "03.02 固件下载中，请稍候 ..."

    # Delete other residual firmware files
    rm -f ${FIRMWARE_DOWNLOAD_PATH}/*${FIRMWARE_SUFFIX} && sync
    rm -f ${FIRMWARE_DOWNLOAD_PATH}/*.img && sync

    FIRMWARE_DOWNLOAD_URL="https:.*${RELEASES_TAG_KEYWORDS}.*${SOC}.*${MAIN_LINE_VERSION}.*${FIRMWARE_SUFFIX}"

    FIRMWARE_RELEASES_PATH=$(curl -s "https://api.github.com/repos/${SERVER_FIRMWARE_URL}/releases" | grep "browser_download_url" | grep -o "${FIRMWARE_DOWNLOAD_URL}" | head -n 1)
    FIRMWARE_DOWNLOAD_NAME="openwrt_${SOC}_k${MAIN_LINE_VERSION}_update${FIRMWARE_SUFFIX}"
    wget -c "${FIRMWARE_RELEASES_PATH}" -O "${FIRMWARE_DOWNLOAD_PATH}/${FIRMWARE_DOWNLOAD_NAME}" >/dev/null 2>&1 && sync
    if [[ "$?" -eq "0" && -s "${FIRMWARE_DOWNLOAD_PATH}/${FIRMWARE_DOWNLOAD_NAME}" ]]; then
        tolog "03.03 ${FIRMWARE_DOWNLOAD_NAME} 下载完成"
    else
        tolog "03.04 下载出错！" "1"
    fi
    sleep 3

    tolog "04 固件下载完成, 你可以点击update升级"
    sleep 3

    #echo '<a href="javascript:;" onclick="return amlogic_update(this, '"'${FIRMWARE_DOWNLOAD_NAME}'"')">Update</a>' >$START_LOG
    tolog '<input type="button" class="cbi-button cbi-button-reload" value="Update" onclick="return amlogic_update(this, '"'${FIRMWARE_DOWNLOAD_NAME}'"')"/>'

    exit 0

