#!/bin/bash

# Set a fixed value
TMP_CHECK_DIR="/tmp/amlogic"
START_LOG="${TMP_CHECK_DIR}/amlogic_check_plugin.log"
LOG_FILE="${TMP_CHECK_DIR}/amlogic.log"
LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
[[ -d ${TMP_CHECK_DIR} ]] || mkdir -p ${TMP_CHECK_DIR}
rm -f ${TMP_CHECK_DIR}/*.ipk && sync

# Log function
tolog() {
    echo -e "${1}" >$START_LOG
    echo -e "${LOGTIME} ${1}" >>$LOG_FILE
    [[ -z "${2}" ]] || exit 1
}

    # 01. Query local version information
    tolog "01. 检查本地插件版本信息"
    CURRENT_PLUGIN_V="$(opkg list-installed | grep 'luci-app-amlogic' | awk '{print $3}')"
    tolog "01.01 当前版本: ${CURRENT_PLUGIN_V}"
    sleep 3

    # 02. Check the version on the server
    tolog "02. 检查远程服务器插件版本信息"
    SERVER_PLUGIN_VERSION=$(curl -i -s "https://api.github.com/repos/ophub/luci-app-amlogic/releases" | grep "tag_name" | head -n 1 | grep -oE "[0-9]{1,3}.[0-9]{1,3}-[0-9]+")
    [ -n "${SERVER_PLUGIN_VERSION}" ] || tolog "02.01 Failed to get the version on the server." "1"
    tolog "02.02 当前版本: ${CURRENT_PLUGIN_V}, 服务器最新版本: ${CURRENT_PLUGIN_V}"
    sleep 3

    if [[ "${CURRENT_PLUGIN_V}" == "${SERVER_PLUGIN_VERSION}" ]]; then
        tolog "02.03 插件已经是最新，无需升级" "1"
        sleep 5
        tolog ""
    else
        tolog "02.03 插件已经是最新，无需升级"

    fi

    exit 0

