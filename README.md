# fifictl

A command-line tool for managing Free WiFi connections.

## Features

- Automatic wireless interface detection
- Support for multiple wireless interfaces
- Connect to Free WiFi networks
- Disconnect from current network
- Check connection status

## Prerequisites

The following commands are required:

- `ip`
- `iwconfig`
- `dhclient`

## Usage

```bash
fifictl.sh <command> [options]
```

### Examples

Connect to Free WiFi:

```bash
$ sudo fifictl.sh conn "Free_WiFi"
```

Disconnect from current network:

```bash
$ sudo fifictl.sh disconn
```

Check connection status:

```bash
$ sudo fifictl.sh status
```

### Notes

- The script requires root privileges to run
- If multiple wireless interfaces are available, you will be prompted to select one

## License

This project is licensed under the MIT License - see the [LICENSE](https://opensource.org/license/mit) for details.
