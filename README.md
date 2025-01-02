# fifictl

A command-line tool for managing Free WiFi connections.

## Features

- Connect to Free WiFi networks with specified interface
- Support for MAC address spoofing
- Disconnect from current network
- Check connection status

## Notes

- The script requires root privileges to run
- Interface must be specified using the -i option
- SSID must be specified using the -s option when connecting
- MAC address is optional and must be in format XX:XX:XX:XX:XX:XX
- MAC address will be changed before connection if specified
- Status command now shows both connection status and current MAC address

## Prerequisites

The following commands are required:

- `ip`
- `iwconfig`
- `dhclient`

## Usage

```bash
fifictl.sh <command> -i <interface> [-s <ssid>] [-m <mac>]
```

### Commands

- `conn`: Connect to specified WiFi network (requires -s option)
- `disconn`: Disconnect from current WiFi network
- `status`: Show current connection status and MAC address

### Options

- `-i <interface>`: Specify wireless interface (required)
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
$ sudo fifictl.sh status -i wlan0
```

## License

This project is licensed under the MIT License - see the [LICENSE](https://opensource.org/license/mit) for details.
