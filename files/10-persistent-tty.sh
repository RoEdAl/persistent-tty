#!/bin/sh
. /lib/functions.sh

#
# persistent-serial
# TTY hotplug script
#

enabled=$(uci -q get persistent-tty.@general[0].enabled)
enabled=$(get_bool ${enabled:-yes})
[ "${enabled}" -eq 0 ] && exit 0

[ "${ACTION}" = add -o "${ACTION}" = remove ] || exit 0
[ "${SUBSYSTEM}" = usb-serial ] || exit 0

[ -n "${DEVICENAME}" ] || exit 1
[ -n "${DEVPATH}" ] || exit 1

function to_upper() {
    echo $1 || tr '[a-z]' '[A-Z]'
}

function replace_vars() {
    local res=${id_link}
    for var in devname subsystem manufacturer manufacturerId product productId interface serial port; do
       vvar=$(eval echo "\$${var}")
       p="\$$var"
       res=${res//$p/$vvar}
       p="\$\{$var\}"
       res=${res//$p/$vvar}
    done    
    echo $res
}

function dev_match() {
    local p=0
    local vvar=0
    for var in manufacturer manufacturerId product productId interface serial; do
        config_get p $1 $var
        [ -z "$p" ] && continue
        vvar=$(eval echo "\$${var}")
        [ "$(to_upper "$p")" = "$(to_upper "$vvar")" ] && continue
        return 1
    done
    return 0
}

function sanitize_name() {
    sed 's/[^0-9A-Za-z]+$//' | sed 's/[^0-9A-Za-z:.-]/_/g'
}

function trim_name() {
    sed 's/[^0-9A-Za-z]+$//'
}

function dry_run_desc() {
   [ "${1:-0}" -eq 1 ] && echo '[DRY RUN] '
}

function link_by_path() {
    local cfg=$1
    local sdev=$2
    local enabled=1

    config_get enabled $cfg enabled 1
    [ "${enabled}" -eq 0 ] && return

    config_get_bool sdry_run $cfg dry_run $dry_run

    path_link=${DEVPATH##/devices/}
    path_link=${path_link%%/${DEVICENAME}}
    path_link=$(echo ${path_link} | sanitize_name)
    
    logger -t tty "$(dry_run_desc $sdry_run)${DEVICENAME} ===> serial/by-path/${path_link}"
    [ "${sdry_run}" -eq 1 ] && return

    mkdir -p /dev/serial/by-path
    # logger -t tts "${DEVICENAME} ===> serial/by-path/${path_link}"
    ln -sf $sdev "/dev/serial/by-path/${path_link}"
}

function link_by_id() {
    local cfg=$1
    local sdev=$2
    local enabled=1

    config_get enabled $cfg enabled 1
    [ "${enabled}" -eq 0 ] && return

    dev_match $cfg || return

    config_get_bool sdry_run $cfg dry_run $dry_run

    config_get id_link $cfg link
    id_link=$(replace_vars | sanitize_name)
    [ -z "${id_link}" ] && return

    logger -t tty "$(dry_run_desc $sdry_run)${DEVICENAME} ===> serial/by-id/${id_link}"
    [ "${sdry_run}" -eq 1 ] && return

    mkdir -p /dev/serial/by-id
    # logger -t tts "${DEVICENAME} ===> serial/by-id/${id_link}"
    ln -sf $sdev "/dev/serial/by-id/${id_link}"
}

function rmdire() {
   [ -d $1 ] || return
   [ -z "$(ls $1)" ] && rmdir $1
}

sdev="/dev/${DEVICENAME}"
config_load persistent-tty
config_get_bool dry_run general dry_run 0

if [ "${ACTION}" = add ]; then
    SDEVPATH=/sys${DEVPATH}
    
    : ${devname:=${DEVICENAME}}
    subsystem=$(basename $(readlink ${SDEVPATH}/../../subsystem))
    [ "${subsystem}" = usb ] || exit 0
    manufacturer=$(cat ${SDEVPATH}/../../manufacturer | trim_name)
    manufacturerId=$(cat ${SDEVPATH}/../../idVendor)
    product=$(cat ${SDEVPATH}/../../product | trim_name)
    productId=$(cat ${SDEVPATH}/../../idProduct)
    serial=$(cat ${SDEVPATH}/../../serial)
    interface=$(cat ${SDEVPATH}/../bInterfaceNumber)
    if [ -f ${SDEVPATH}/port_number ]; then
        port=$(cat ${SDEVPATH}/port_number)
    else
        unset port
    fi

    link_by_path by_path $sdev
    config_foreach link_by_id by_id $sdev
elif [ "${ACTION}" = remove ]; then
    for link in $(find /dev/serial -type l); do
        [ -L ${link} ] || continue
        [ "$(readlink ${link})" = $sdev ] || continue
        slink=${link##/dev/}
        logger -t tty "$(dry_run_desc $dry_run)${DEVICENAME} =X=> ${slink}"
        [ "${dry_run}" -eq 1 ] && continue
        rm ${link}
    done
    if [ ! "${sdry_run}" -eq 1 ]; then
        rmdire /dev/serial/by-path
        rmdire /dev/serial/by-id
        rmdire /dev/serial
    fi
fi
