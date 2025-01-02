# fifictl

A command-line tool for managing Free WiFi connections.

## Features

- Connect to Free WiFi networks with specified interface
- Disconnect from current network
- Check connection status

## Prerequisites

The following commands are required:

- `ip`
- `iwconfig`
- `dhclient`

## Usage

```bash
$ sudo fifictl.sh <command> -i <interface> [-s <ssid>]
```

### Commands

- `conn`: Connect to specified WiFi network (requires -s option)
- `disconn`: Disconnect from current WiFi network
- `status`: Show current connection status

### Options

- `-i <interface>`: Specify wireless interface (required)
- `-s <ssid>`: Specify SSID (required for conn command)

### Examples

Connect to Free WiFi:

```bash
$ sudo fifictl.sh conn -i wlan0 -s "Free_WiFi"
```

Disconnect from current network:

```bash
$ sudo fifictl.sh disconn -i wlan0
```

Check connection status:

```bash
$ sudo fifictl.sh status -i wlan0
```

### Notes

- The script requires root privileges to run
- Interface must be specified using the -i option
- SSID must be specified using the -s option when connecting

## License

This project is licensed under the MIT License - see the [LICENSE](https://opensource.org/license/mit) for details.
