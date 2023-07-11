#
# persistent-serial
# TTY hotplug script
#

enabled=$(uci -q get persistent-tty.@general[0].enabled)
[ "${enabled:-1}" -eq 0 ] && exit 0

[ "${ACTION}" = add -o "${ACTION}" = remove ] || exit 0
[ "${SUBSYSTEM}" = usb-serial ] || exit 0

[ -n "${DEVICENAME}" ] || exit 1
[ -n "${DEVPATH}" ] || exit 1

function to_upper() {
    echo $1 || tr '[a-z]' '[A-Z]'
}

function replace_vars() {
    res=${id_link}
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
    for var in manufacturer manufacturerId product productId interface serial; do
        p=$(uci -q get persistent-tty.@by_id[$1].$var)
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
   [ "${sdry_run}" -eq 1 ] && echo '[DRY RUN] '
}

function rmdire() {
   [ -d $1 ] || return
   [ -z "$(ls $1)" ] && rmdir $1
}


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
    
    dry_run=$(uci -q get persistent-tty.@general[0].dry_run)
    : ${dry_run:=0}

    # by-path
    senabled=$(uci -q get persistent-tty.@by_path[0].enabled)
    if [ ! "${senabled:-1}" -eq 0 ]; then
        sdry_run=$(uci -q get persistent-tty@by_path[0].dry_run)
        : ${sdry_run:=$dry_run}

        path_link=${DEVPATH##/devices/}
        path_link=${path_link%%/${DEVICENAME}}
        path_link=$(echo ${path_link} | sanitize_name)
        
        logger -t tty "$(dry_run_desc)${DEVICENAME} ===> serial/by-path/${path_link}"

        if [ ! "${sdry_run}" -eq 1 ]; then
            # logger -t tts "${DEVICENAME} ===> serial/by-path/${path_link}"
            mkdir -p /dev/serial/by-path
            ln -sf "/dev/${DEVICENAME}" "/dev/serial/by-path/${path_link}"
        fi
    fi

    # by-id
    idx=-1
    while true; do
        idx=$(($idx+1))
        by_id=$(uci -q get persistent-tty.@by_id[$idx])
        [ -z "${by_id}" ] && break

        senabled=$(uci -q get persistent-tty.@by_id[$idx].enabled)
        : ${senabled:=1}
        [ "${senabled}" -eq 0 ] && continue

        dev_match $idx || continue

        sdry_run=$(uci -q get persistent-tty.@by_id[$idx].dry_run)
        : ${sdry_run:=$dry_run}

        id_link=$(uci -q get persistent-tty.@by_id[$idx].link)
        id_link=$(replace_vars | sanitize_name)
        [ -z "${id_link}" ] && continue

        logger -t tty "$(dry_run_desc)${DEVICENAME} ===> serial/by-id/${id_link}"
        [ "${sdry_run}" -eq 1 ] && continue

        mkdir -p /dev/serial/by-id
        # logger -t tts "${DEVICENAME} ===> serial/by-id/${id_link}"
        ln -sf "/dev/${DEVICENAME}" "/dev/serial/by-id/${id_link}"
    done
elif [ "${ACTION}" = remove ]; then
    sdry_run=$(uci -q get persistent-tty.@general[0].dry_run)
    : ${sdry_run:=0}
    for link in $(find /dev/serial -type l); do
        [ -L ${link} ] || continue
        [ "$(readlink ${link})" = "/dev/${DEVICENAME}" ] || continue
        slink=${link##/dev/}
        logger -t tty "$(dry_run_desc)${DEVICENAME} =x=> ${slink}"
        [ "${sdry_run}" -eq 1 ] && continue
        rm ${link}
    done
    if [ ! "${sdry_run}" -eq 1 ]; then
        rmdire /dev/serial/by-path
        rmdire /dev/serial/by-id
        rmdire /dev/serial
    fi
fi

