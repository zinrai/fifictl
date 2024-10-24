#!/bin/bash

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

show_usage() {
    echo "fifictl - Free WiFi Control Tool"
    echo ""
    echo "Usage: fifictl <command> [options]"
    echo ""
    echo "Commands:"
    echo "  conn <SSID>    Connect to specified WiFi network"
    echo "  disconn        Disconnect from current WiFi network"
    echo "  status        Show current connection status"
    echo ""
    echo "Example:"
    echo "  fifictl conn \"Free_WiFi\""
    echo "  fifictl disconn"
    echo "  fifictl status"
    exit 1
}

find_wireless_interfaces() {
    # Try to find wireless interfaces using ip command
    local interfaces
    interfaces=$(ip link show | grep -E 'wl[a-z0-9]+' | cut -d: -f2 | tr -d ' ')

    if [ -z "$interfaces" ]; then
        error_exit "No wireless interface found"
    fi

    echo "$interfaces"
}

# let user choose an interface if multiple are found
select_wireless_interface() {
    local interfaces="$1"
    local interface_count
    interface_count=$(echo "$interfaces" | wc -l)

    if [ "$interface_count" -eq 1 ]; then
        echo "$interfaces"
        return
    fi

    echo "Multiple wireless interfaces found:"
    local i=1
    while read -r interface; do
        echo "$i) $interface"
        i=$((i+1))
    done <<< "$interfaces"

    while true; do
        read -r -p "Select interface number (1-$interface_count): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$interface_count" ]; then
            echo "$interfaces" | sed -n "${choice}p"
            return
        fi
        echo "Invalid choice. Please try again."
    done
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

if [ $# -lt 1 ]; then
    show_usage
fi

COMMAND="$1"
shift

# Find and select wireless interface
WIRELESS_INTERFACES=$(find_wireless_interfaces)
INTERFACE=$(select_wireless_interface "$WIRELESS_INTERFACES")

case "${COMMAND}" in
    "conn")
        if [ $# -lt 1 ]; then
            error_exit "SSID is required for conn command"
        fi
        do_connect "$1" "${INTERFACE}"
        ;;
    "disconn")
        do_disconnect "${INTERFACE}"
        ;;
    "status")
        do_status "${INTERFACE}"
        ;;
    *)
        error_exit "Unknown command: ${COMMAND}"
        ;;
esac
