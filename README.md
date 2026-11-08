# fifictl

A command-line tool for managing Free WiFi connections.

## Features

- Connect to Free WiFi networks with specified interface
- Support for MAC address spoofing
- Disconnect from current network
- Check connection status
- Detect a captive portal and report the URL to open

## Notes

- The conn and disconn commands require root privileges
- Interface must be specified with -i for conn, disconn, and status (capport does not need it)
- SSID must be specified using the -s option when connecting
- MAC address is optional and must be in format XX:XX:XX:XX:XX:XX
- MAC address will be changed before connection if specified
- Status command now shows both connection status and current MAC address

## Prerequisites

The following commands are required:

- `ip` (iproute2)
- `iw`
- `udhcpc`
- `curl`

## Usage

```bash
fifictl.sh <command> -i <interface> [-s <ssid>] [-m <mac>]
```

### Commands

- `conn`: Connect to specified WiFi network (requires -s option)
- `disconn`: Disconnect from current WiFi network
- `status`: Show current connection status and MAC address
- `capport`: Report whether a captive portal is blocking access

### Options

- `-i <interface>`: Specify wireless interface (required for conn, disconn, and status)
- `-s <ssid>`: Specify SSID (required for conn command)
- `-m <mac>`: Specify MAC address to use (optional, format: XX:XX:XX:XX:XX:XX)

### Examples

Connect to Free WiFi with default MAC address:

```bash
$ sudo fifictl.sh conn -i wlan0 -s "Free_WiFi"
```

Connect to Free WiFi with specified MAC address:

```bash
$ sudo fifictl.sh conn -i wlan0 -s "Free_WiFi" -m 12:34:56:78:9A:BC
```

Disconnect from current network:

```bash
$ sudo fifictl.sh disconn -i wlan0
```

Check connection status and current MAC address:

```bash
$ fifictl.sh status -i wlan0
```

## Checking for a captive portal

`conn` associates and obtains an IP, but reaching the internet may still require
passing a captive portal. The `capport` command reports that state. Chain it
after a successful `conn`:

```bash
$ sudo fifictl.sh conn -i wlan0 -s "Free_WiFi" && fifictl.sh capport
```

The exit code is the result, so `capport` composes into scripts:

- `0`: online (the probe returned 204)
- `2`: captive portal detected (the URL to open is printed to stdout)
- `3`: offline (the probe got no response)

`capport` sends one plain HTTP request and does not follow redirects, so a
captive portal's redirect reveals the portal URL. Open that URL in a normal
browser to accept the terms. `capport` does not open a browser or accept the
terms itself, and it can be run on its own at any time to re-check a session
that may have expired.

## License

This project is licensed under the [MIT License](./LICENSE).
