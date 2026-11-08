#!/bin/bash

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

require_root() {
    if [ "$(id -u)" != "0" ]; then
        error_exit "This command must be run with root privileges."
    fi
}

require_interface() {
    if [ -z "$INTERFACE" ]; then
        error_exit "Wireless interface must be specified with -i option"
    fi
}

show_usage() {
    echo "fifictl - Free WiFi Control Tool"
    echo ""
    echo "Usage: fifictl <command> -i <interface> [-s <ssid>] [-m <mac>]"
    echo ""
    echo "Commands:"
    echo "  conn        Associate with an open WiFi network and obtain an IP (requires -s)"
    echo "  disconn     Disconnect from the current network"
    echo "  status      Show connection status and current MAC address"
    echo "  capport     Report whether a captive portal is blocking access (no -i needed)"
    echo ""
    echo "Options:"
    echo "  -i <interface>    Wireless interface (required for conn, disconn, status)"
    echo "  -s <ssid>        SSID (required for conn)"
    echo "  -m <mac>         MAC address to use (optional, format: XX:XX:XX:XX:XX:XX)"
    echo ""
    echo "Examples:"
    echo "  fifictl conn -i wlan0 -s \"Free_WiFi\""
    echo "  fifictl conn -i wlan0 -s \"Free_WiFi\" -m 12:34:56:78:9A:BC"
    echo "  fifictl conn -i wlan0 -s \"Free_WiFi\" && fifictl capport"
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

    # Interface must be down to change its MAC
    ip link set "${interface}" down || error_exit "Failed to bring interface down"
    ip link set dev "${interface}" address "${mac}" || error_exit "Failed to change MAC address"
    ip link set "${interface}" up || error_exit "Failed to bring interface up"

    echo "MAC address changed successfully"
}

do_connect() {
    local ssid="$1"
    local interface="$2"
    local mac="$3"

    # If a MAC address is specified, change it first (this also brings the interface up)
    if [ -n "$mac" ]; then
        change_mac "${interface}" "${mac}"
    else
        echo "Enabling interface ${interface}..."
        ip link set "${interface}" up || error_exit "Failed to enable the interface."
    fi

    # Associate with the open network (-w waits for the association result)
    echo "Associating with ${ssid}..."
    iw dev "${interface}" connect -w "${ssid}" || error_exit "Failed to associate with the network."

    # Obtain an IP address (-n: give up if none, -q: quit once configured, no daemon left behind)
    echo "Obtaining IP address..."
    udhcpc -i "${interface}" -n -q || error_exit "Failed to obtain an IP address."

    # L2 association and L3 address are done. Reaching the internet may still
    # require passing a captive portal, which the capport command reports.
    echo "Associated and obtained an IP on ${interface}."
}

do_disconnect() {
    local interface="$1"
    echo "Disconnecting..."
    # udhcpc -q already exited, so there is no lease daemon to release
    iw dev "${interface}" disconnect
    ip addr flush dev "${interface}"
    ip link set "${interface}" down
    echo "Disconnection complete."
}

do_status() {
    local interface="$1"
    echo "Connection status for ${interface}:"
    iw dev "${interface}" link
    echo ""
    echo "Current MAC address:"
    ip link show "${interface}" | grep "link/ether"
}

# Report whether a captive portal is blocking internet access.
# A plain http:// probe endpoint returns 204 when the network is truly online.
# A captive portal intercepts it and answers with a redirect or its own page.
# Exit code is the result: 0 online, 2 captive (URL to stdout), 3 offline.
do_capport() {
    local probe_url="http://connectivitycheck.gstatic.com/generate_204"
    local timeout=5

    local out rc code redirect
    # Redirects are not followed, so %{redirect_url} exposes the portal URL.
    out=$(curl -s -m "${timeout}" -o /dev/null -w '%{http_code} %{redirect_url}' "${probe_url}")
    rc=$?
    if [ "${rc}" -ne 0 ]; then
        echo "offline: curl exit ${rc}" >&2
        exit 3
    fi
    read -r code redirect <<< "${out}"

    case "${code}" in
        204)
            echo "online" >&2
            exit 0
            ;;
        3??)
            echo "captive portal detected" >&2
            echo "${redirect:-$probe_url}"
            exit 2
            ;;
        *)
            echo "captive portal detected (status ${code})" >&2
            echo "${probe_url}"
            exit 2
            ;;
    esac
}

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

# Process commands
case "${COMMAND}" in
    "conn")
        require_root
        require_interface
        if [ -z "$SSID" ]; then
            error_exit "SSID must be specified with -s option for conn command"
        fi
        do_connect "$SSID" "$INTERFACE" "$MAC"
        ;;
    "disconn")
        require_root
        require_interface
        do_disconnect "$INTERFACE"
        ;;
    "status")
        require_interface
        do_status "$INTERFACE"
        ;;
    "capport")
        do_capport
        ;;
    *)
        error_exit "Unknown command: ${COMMAND}"
        ;;
esac
