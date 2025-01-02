#!/bin/bash

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

show_usage() {
    echo "fifictl - Free WiFi Control Tool"
    echo ""
    echo "Usage: fifictl <command> -i <interface> [-s <ssid>] [-m <mac>]"
    echo ""
    echo "Commands:"
    echo "  conn        Connect to specified WiFi network (requires -s option)"
    echo "  disconn     Disconnect from current WiFi network"
    echo "  status      Show current connection status"
    echo ""
    echo "Options:"
    echo "  -i <interface>    Specify wireless interface (required)"
    echo "  -s <ssid>        Specify SSID (required for conn command)"
    echo "  -m <mac>         Specify MAC address to use (optional, format: XX:XX:XX:XX:XX:XX)"
    echo ""
    echo "Examples:"
    echo "  fifictl conn -i wlan0 -s \"Free_WiFi\" -m 12:34:56:78:9A:BC"
    echo "  fifictl disconn -i wlan0"
    echo "  fifictl status -i wlan0"
    exit 1
}

# Function to validate MAC address format
validate_mac() {
    local mac="$1"
    if ! [[ $mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        error_exit "Invalid MAC address format. Expected format: XX:XX:XX:XX:XX:XX"
    fi
}

# Function to change MAC address
change_mac() {
    local interface="$1"
    local mac="$2"

    echo "Changing MAC address of ${interface} to ${mac}..."

    # Bring interface down before changing MAC
    ip link set "${interface}" down || error_exit "Failed to bring interface down"

    # Change MAC address
    ip link set dev "${interface}" address "${mac}" || error_exit "Failed to change MAC address"

    # Bring interface back up
    ip link set "${interface}" up || error_exit "Failed to bring interface up"

    echo "MAC address changed successfully"
}

do_connect() {
    local ssid="$1"
    local interface="$2"
    local mac="$3"

    # If MAC address is specified, change it first
    if [ -n "$mac" ]; then
        change_mac "${interface}" "${mac}"
    else
        # Enable the interface if no MAC change is needed
        echo "Enabling interface ${interface}..."
        ip link set "${interface}" up || error_exit "Failed to enable the interface."
    fi

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
    echo ""
    echo "Current MAC address:"
    ip link show "${interface}" | grep "link/ether"
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
MAC=""

# Process options
while getopts "i:s:m:" opt; do
    case $opt in
        i)
            INTERFACE="$OPTARG"
            ;;
        s)
            SSID="$OPTARG"
            ;;
        m)
            MAC="$OPTARG"
            validate_mac "$MAC"
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
        do_connect "$SSID" "$INTERFACE" "$MAC"
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
