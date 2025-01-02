#!/bin/bash

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

show_usage() {
    echo "fifictl - Free WiFi Control Tool"
    echo ""
    echo "Usage: fifictl <command> -i <interface> [-s <ssid>]"
    echo ""
    echo "Commands:"
    echo "  conn        Connect to specified WiFi network (requires -s option)"
    echo "  disconn     Disconnect from current WiFi network"
    echo "  status      Show current connection status"
    echo ""
    echo "Options:"
    echo "  -i <interface>    Specify wireless interface (required)"
    echo "  -s <ssid>        Specify SSID (required for conn command)"
    echo ""
    echo "Examples:"
    echo "  fifictl conn -i wlan0 -s \"Free_WiFi\""
    echo "  fifictl disconn -i wlan0"
    echo "  fifictl status -i wlan0"
    exit 1
}

do_connect() {
    local ssid="$1"
    local interface="$2"

    # Enable the interface
    echo "Enabling interface ${interface}..."
    ip link set "${interface}" up || error_exit "Failed to enable the interface."

    # Connect to WiFi network
    echo "Connecting to ${ssid}..."
    iwconfig "${interface}" essid "${ssid}" || error_exit "Failed to connect to WiFi network."

    # Obtain IP address via DHCP
    echo "Obtaining IP address..."
    dhclient "${interface}" || error_exit "Failed to obtain IP address."

    echo "Successfully connected to Free WiFi."
}

do_disconnect() {
    local interface="$1"
    echo "Disconnecting..."
    dhclient "${interface}" -r
    ip link set "${interface}" down
    echo "Disconnection complete."
}

do_status() {
    local interface="$1"
    echo "Connection status for ${interface}:"
    iwconfig "${interface}"
}

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
   error_exit "This script must be run with root privileges."
fi

# Check if command is provided
if [ $# -lt 1 ]; then
    show_usage
fi

# Get the command
COMMAND="$1"
shift

# Initialize variables
INTERFACE=""
SSID=""

# Process options
while getopts "i:s:" opt; do
    case $opt in
        i)
            INTERFACE="$OPTARG"
            ;;
        s)
            SSID="$OPTARG"
            ;;
        *)
            show_usage
            ;;
    esac
done

# Check if interface is specified
if [ -z "$INTERFACE" ]; then
    error_exit "Wireless interface must be specified with -i option"
fi

# Process commands
case "${COMMAND}" in
    "conn")
        if [ -z "$SSID" ]; then
            error_exit "SSID must be specified with -s option for conn command"
        fi
        do_connect "$SSID" "$INTERFACE"
        ;;
    "disconn")
        do_disconnect "$INTERFACE"
        ;;
    "status")
        do_status "$INTERFACE"
        ;;
    *)
        error_exit "Unknown command: ${COMMAND}"
        ;;
esac
