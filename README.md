# Perersistent names for serial devices - *OpenWRT* hotplug script

This hotplug script just creates persistent symlinks for `ttyUSB*` devices in a similar way to *udev* (*systemd*). *Coldplug* mode is also supported.

## Instalation

Download latest package and install it manually:

```sh
opkg install persistent-tty_1.1-1_all.ipk
```

*Dry run* mode is enabled by default (see below).

## Configuration

Configuration file is `/etc/config/persistent-tty`. You can use standard `uci` utility in order to modify this one.

### General options:

* `enabled` - **yes**|no

    Enable/disable this hotplug script:

    ```sh
    uci set persistent-tty.general.enabled=no
    uci commit
    ```

* `dry_run` - yes|**no**

    Enable/disable *dry run* mode:

    ```sh
    uci set persistent-tty.general.dry_run=yes
    uci commit
    ```

### `by_path` section options

There's only one `by_path` section.
By-path symlinks are created in `/dev/serial/by-path` directory.

* `enabled` - **yes**|no

    Enable/disable creation of `by_path` link:

    ```sh
    uci set persistent-tty.by_path.enabled=no
    uci commit
    ```

* `dry_run` - yes|**no**

    Enable/disable *dry run* mode for `by_path` link:

    ```sh
    uci set persistent-tty.by_path.dry_run=yes
    uci commit
    ```

### `by_id` sections options

Many `by_id` sections may by defined. There are few installed by default.
Symlinks are created in `/dev/serial/by-id` directory.

* `link` - link name pattern (mandatory option)

    ```sh
    uci set 'persistent-tty.@by_id[0].link=${subsystem}-${manufacturer}:${product}-if${interface}-port${port}'
    uci commit
    ```

    Available placeholders:

    * `${devname}`
    * `${subsystem}`
    * `${manufacturerId}` (vendor ID)
    * `${manufacturer}`
    * `${productId}`
    * `${product}`
    * `${interface}`
    * `${serial}`
    * `${port}`

* `enabled` - **yes**|no

    Enable/disable creation of this link:

    ```sh
    uci set persistent-tty.by_path.enabled=no
    uci commit
    ```

    or

    ```sh
    uci delete persistent-tty.by_path.enabled
    uci commit
    ```

* `dry_run` - yes|**no**

    Enable/disable *dry run* mode for this link:

    ```sh
    uci set persistent-tty.by_path.dry_run=yes
    uci commit
    ```

#### Matching options

By default `by_id` section matches all serial devices.
You can limit link creation to specific device or device group by using following options:

* `manufacturer`
* `manufacturerId`
* `product`
* `productId`
* `interface`
* `serial`

Matching is case insensitive.

Examples:

* Specify device by `vid:pid` pair:

    ```sh
    uci set persistent-tty.ftdi=by_id
    uci set persistent-tty.ftdi.link='ftdi-${serial}'
    uci set persistent-tty.ftdi.manufacturerId='0403'
    uci set persistent-tty.ftdi.productId='6001'
    uci commit
    uci 
    ```

* Specify device by manufacturer and product name:

    ```sh
    uci set persistent-tty.ftdi=by_id
    uci set persistent-tty.ftdi.link='ftdi-${serial}'
    uci set persistent-tty.ftdi.manufacturer='FTDI'
    uci set persistent-tty.ftdi.product='FT232R USB UART'
    uci commit
    ```

## Log messages

### *Dry run* mode

```
Wed Jul 12 09:18:40 2023 user.notice tty: [DRY RUN] ttyUSB3 ===> serial/by-path/platform_soc_1c14000.usb_usb1_1-1_1-1.2_1-1.2:1.0
Wed Jul 12 09:18:40 2023 user.notice tty: [DRY RUN] ttyUSB3 ===> serial/by-id/usb-FTDI:FT232R_USB_UART-if00-port0
Wed Jul 12 09:18:40 2023 user.notice tty: [DRY RUN] ttyUSB3 ===> serial/by-id/usb-0403:6001-if00-port0
Wed Jul 12 09:18:40 2023 user.notice tty: [DRY RUN] ttyUSB3 ===> serial/by-id/usb-AH05WPW6-if00-port0
```

### Normal mode

New device attached:

```
Wed Jul 12 09:36:39 2023 user.notice tty: ttyUSB3 ===> serial/by-path/platform_soc_1c14000.usb_usb1_1-1_1-1.2_1-1.2:1.0
Wed Jul 12 09:36:39 2023 user.notice tty: ttyUSB3 ===> serial/by-id/usb-FTDI:FT232R_USB_UART-if00-port0
Wed Jul 12 09:36:39 2023 user.notice tty: ttyUSB3 ===> serial/by-id/usb-0403:6001-if00-port0
Wed Jul 12 09:36:39 2023 user.notice tty: ttyUSB3 ===> serial/by-id/usb-AH05WPW6-if00-port0
```

Device removal:

```
Thu Jul 13 08:39:31 2023 user.notice tty: ttyUSB3 =X=> serial/by-id/ftdi-AH05WPW6
Thu Jul 13 08:39:31 2023 user.notice tty: ttyUSB3 =X=> serial/by-id/usb-AH05WPW6-if00-port0
Thu Jul 13 08:39:31 2023 user.notice tty: ttyUSB3 =X=> serial/by-id/usb-0403:6001-if00-port0
Thu Jul 13 08:39:31 2023 user.notice tty: ttyUSB3 =X=> serial/by-id/usb-FTDI:FT232R_USB_UART-if00-port0
Thu Jul 13 08:39:31 2023 user.notice tty: ttyUSB3 =X=> serial/by-path/platform_soc_1c14000.usb_usb1_1-1_1-1.
```

## Links

* [Leo-PL's hotplug script](//gist.github.com/Leo-PL/b5ee737e49b34c1551dba6c182707c8e),
* [*eko.one* - przypisanie na stałe urządzeń ttyUSB (polish)](//eko.one.pl/forum/viewtopic.php?id=13452).