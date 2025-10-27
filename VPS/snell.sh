#!/usr/bin/env bash

#
# Snell Server Management Script
#
#

# ---
# Script Configuration and Safety
# ---
# set -e: Exit immediately if a command exits with a non-zero status.
# set -u: Treat unset variables as an error.
# set -o pipefail: The return value of a pipeline is the status of the last command to fail.
set -euo pipefail

# ---
# Global Constants and Variables
# ---
readonly SH_VER="1.8.4-optimized"
readonly SNELL_V2_VERSION="2.0.6"
readonly SNELL_V3_VERSION="3.0.1"
readonly SNELL_V4_VERSION="4.1.1"
readonly SNELL_V5_VERSION="5.0.0"

# Directories and Paths
readonly SNELL_DIR="/etc/snell/"
readonly SNELL_BIN="/usr/local/bin/snell-server"
readonly SNELL_CONF="/etc/snell/config.conf"
readonly SNELL_VERSION_FILE="/etc/snell/ver.txt"
readonly SYSCTL_CONF="/etc/sysctl.d/local.conf"
readonly TEMP_DIR=$(mktemp -d) # Create a temporary directory for downloads

# Color Codes
readonly GREEN_FONT_PREFIX="\033[32m"
readonly RED_FONT_PREFIX="\033[31m"
readonly GREEN_BACKGROUND_PREFIX="\033[42;37m"
readonly RED_BACKGROUND_PREFIX="\033[41;37m"
readonly FONT_COLOR_SUFFIX="\033[0m"
readonly YELLOW_FONT_PREFIX="\033[0;33m"

# Log Prefixes
readonly INFO="${GREEN_FONT_PREFIX}[INFO]${FONT_COLOR_SUFFIX}"
readonly ERROR="${RED_FONT_PREFIX}[ERROR]${FONT_COLOR_SUFFIX}"
readonly TIP="${YELLOW_FONT_PREFIX}[NOTE]${FONT_COLOR_SUFFIX}"

# ---
# Cleanup Function
# ---
# This function is called when the script exits, ensuring temporary files are removed.
cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# ---
# Helper and System Check Functions
# ---

# Check for root privileges
check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo -e "${ERROR} This script must be run as root. Please use 'sudo su' or run with 'sudo'."
        exit 1
    fi
}

# Detect operating system
get_os_release() {
    if [[ -f /etc/redhat-release ]]; then
        echo "centos"
    elif grep -q -E -i "debian" /etc/issue 2>/dev/null; then
        echo "debian"
    elif grep -q -E -i "ubuntu" /etc/issue 2>/dev/null; then
        echo "ubuntu"
    elif grep -q -E -i "centos|red hat|redhat" /etc/issue 2>/dev/null; then
        echo "centos"
    else
        echo "unknown"
    fi
}

# Determine system architecture
get_sys_arch() {
    local uname_m
    uname_m=$(uname -m)
    case "${uname_m}" in
        "i686" | "i386") echo "i386" ;;
        *"armv7"* | "armv6l") echo "armv7l" ;;
        *"armv8"* | "aarch64") echo "aarch64" ;;
        *) echo "amd64" ;;
    esac
}

# Install required dependencies
install_dependencies() {
    local release
    release=$(get_os_release)
    echo -e "${INFO} Installing dependencies for ${release}..."
    if [[ "${release}" == "centos" ]]; then
        yum install -y gzip wget curl unzip jq
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        apt-get update
        apt-get install -y gzip wget curl unzip jq
    else
        echo -e "${ERROR} Unsupported operating system. Please install dependencies manually."
        exit 1
    fi
    echo -e "${INFO} Dependencies installed."
}

# Enable BBR and TCP Fast Open
enable_optimizations() {
    echo -e "${INFO} Applying network optimizations (BBR, TFO)..."
    if [[ ! -f "${SYSCTL_CONF}" ]] || ! grep -q "net.ipv4.tcp_congestion_control" "${SYSCTL_CONF}"; then
        cat > "${SYSCTL_CONF}" <<-EOF
fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF
        sysctl --system >/dev/null 2>&1
    fi
    echo -e "${INFO} Network optimizations applied."
}

# ---
# Core Snell Management Functions
# ---

# Download and install the Snell binary
download_and_install_snell() {
    local version="$1"
    local arch
    arch=$(get_sys_arch)
    
    local download_url
    # Versions 2 and 3 use a GitHub backup source
    if [[ "${version}" == "${SNELL_V2_VERSION}" || "${version}" == "${SNELL_V3_VERSION}" ]]; then
        download_url="https://raw.githubusercontent.com/xOS/Others/master/snell/v${version}/snell-server-v${version}-linux-${arch}.zip"
    else
        download_url="https://dl.nssurge.com/snell/snell-server-v${version}-linux-${arch}.zip"
    fi
    
    local zip_file="${TEMP_DIR}/snell.zip"
    
    echo -e "${INFO} Downloading Snell Server v${version} for ${arch}..."
    if ! wget -O "${zip_file}" --no-check-certificate "${download_url}"; then
        echo -e "${ERROR} Failed to download Snell Server v${version}."
        return 1
    fi
    
    echo -e "${INFO} Unzipping archive..."
    unzip -o "${zip_file}" -d "${TEMP_DIR}"
    
    local unzipped_binary="${TEMP_DIR}/snell-server"
    if [[ ! -f "${unzipped_binary}" ]]; then
        echo -e "${ERROR} Failed to find 'snell-server' executable in the archive."
        return 1
    fi
    
    echo -e "${INFO} Installing binary..."
    mv -f "${unzipped_binary}" "${SNELL_BIN}"
    chmod +x "${SNELL_BIN}"
    echo "v${version}" > "${SNELL_VERSION_FILE}"
    
    echo -e "${INFO} Snell Server v${version} installed successfully."
    return 0
}

# Setup systemd service for Snell
setup_service() {
    echo -e "${INFO} Setting up systemd service..."
    cat > /etc/systemd/system/snell-server.service <<-EOF
[Unit]
Description=Snell Proxy Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
LimitNOFILE=51200
Restart=on-failure
RestartSec=5s
ExecStart=${SNELL_BIN} -c ${SNELL_CONF}

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable snell-server >/dev/null 2>&1
    echo -e "${INFO} Systemd service created and enabled."
}

# Write configuration to file
write_config() {
    local port="$1"
    local psk="$2"
    local obfs="$3"
    local host="$4"
    local ipv6="$5"
    local tfo="$6"
    local dns="$7"
    local ver="$8"

    # Backup existing config
    if [[ -f "${SNELL_CONF}" ]]; then
        mv "${SNELL_CONF}" "${SNELL_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
    fi
    
    echo -e "${INFO} Writing configuration to ${SNELL_CONF}..."
    cat > "${SNELL_CONF}" <<-EOF
[snell-server]
listen = ::0:${port}
psk = ${psk}
obfs = ${obfs}
version = ${ver}
ipv6 = ${ipv6}
tfo = ${tfo}
EOF
    # Only add obfs-host if obfs is enabled
    if [[ "${obfs}" != "off" ]]; then
        echo "obfs-host = ${host}" >> "${SNELL_CONF}"
    fi
    # Only add DNS for versions that support it (v4+)
    if [[ "${ver}" -ge 4 ]]; then
        echo "dns = ${dns}" >> "${SNELL_CONF}"
    fi
}

# Unified installation process
install_snell() {
    if [[ -f "${SNELL_BIN}" ]]; then
        echo -e "${ERROR} Snell Server is already installed. Please uninstall first."
        return 1
    fi
    
    check_root

    echo -e "Choose a Snell version to install:"
    echo " 2) v2 (${SNELL_V2_VERSION})"
    echo " 3) v3 (${SNELL_V3_VERSION})"
    echo " 4) v4 (${SNELL_V4_VERSION}) (Recommended)"
    echo " 5) v5 (${SNELL_V5_VERSION})"
    read -rp "Enter choice [2-5] (default: 4): " ver_choice
    ver_choice=${ver_choice:-4}

    local ver_protocol version_to_install
    case "${ver_choice}" in
        2) ver_protocol=2; version_to_install=${SNELL_V2_VERSION} ;;
        3) ver_protocol=3; version_to_install=${SNELL_V3_VERSION} ;;
        5) ver_protocol=5; version_to_install=${SNELL_V5_VERSION} ;;
        *) ver_protocol=4; version_to_install=${SNELL_V4_VERSION} ;;
    esac

    # --- Collect Configuration ---
    echo -e "${INFO} Starting configuration..."
    read -rp "Enter Snell port [1-65535] (default: 2345): " port
    port=${port:-2345}
    
    read -rp "Enter PSK (Pre-Shared Key) (default: random): " psk
    psk=${psk:-$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)}

    read -rp "Enable obfs? (1=tls, 2=http, 3=off) (default: 3): " obfs_choice
    local obfs="off" host=""
    if [[ "${obfs_choice}" == "1" ]]; then
        obfs="tls"
    elif [[ "${obfs_choice}" == "2" ]]; then
        obfs="http"
    fi
    if [[ "${obfs}" != "off" ]]; then
        read -rp "Enter obfs-host (e.g., icloud.com): " host
        host=${host:-icloud.com}
    fi
    
    read -rp "Enable IPv6? (y/N) (default: n): " ipv6_choice
    local ipv6="false"
    [[ "${ipv6_choice}" =~ ^[Yy]$ ]] && ipv6="true"

    read -rp "Enable TCP Fast Open (TFO)? (Y/n) (default: y): " tfo_choice
    local tfo="true"
    [[ "${tfo_choice}" =~ ^[Nn]$ ]] && tfo="false"

    local dns="1.1.1.1, 8.8.8.8"
    if [[ "${ver_protocol}" -ge 4 ]]; then
        read -rp "Enter DNS servers (comma-separated) (default: 1.1.1.1, 8.8.8.8): " dns
        dns=${dns:-"1.1.1.1, 8.8.8.8"}
    fi

    # --- Execute Installation ---
    install_dependencies
    enable_optimizations
    mkdir -p "${SNELL_DIR}"
    
    if ! download_and_install_snell "${version_to_install}"; then
        echo -e "${ERROR} Installation failed during download."
        return 1
    fi
    
    setup_service
    write_config "${port}" "${psk}" "${obfs}" "${host}" "${ipv6}" "${tfo}" "${dns}" "${ver_protocol}"
    
    start_snell
    echo -e "${GREEN_FONT_PREFIX}Snell Server installation complete!${FONT_COLOR_SUFFIX}"
    view_config
}

# Uninstall Snell
uninstall_snell() {
    check_root
    if [[ ! -f "${SNELL_BIN}" ]]; then
        echo -e "${ERROR} Snell Server is not installed."
        return 1
    fi

    read -rp "Are you sure you want to uninstall Snell Server? (y/N): " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
        stop_snell
        systemctl disable snell-server >/dev/null 2>&1
        rm -f /etc/systemd/system/snell-server.service
        rm -rf "${SNELL_DIR}"
        rm -f "${SNELL_BIN}"
        systemctl daemon-reload
        echo -e "${INFO} Snell Server has been uninstalled."
    else
        echo -e "${INFO} Uninstallation cancelled."
    fi
}

# ---
# Service Control Functions
# ---

start_snell() {
    echo -e "${INFO} Starting Snell Server..."
    systemctl start snell-server
    sleep 1
    if systemctl is-active --quiet snell-server; then
        echo -e "${INFO} Snell Server started successfully."
    else
        echo -e "${ERROR} Failed to start Snell Server. Check logs with 'journalctl -u snell-server'."
    fi
}

stop_snell() {
    echo -e "${INFO} Stopping Snell Server..."
    systemctl stop snell-server
    echo -e "${INFO} Snell Server stopped."
}

restart_snell() {
    echo -e "${INFO} Restarting Snell Server..."
    systemctl restart snell-server
    sleep 1
    if systemctl is-active --quiet snell-server; then
        echo -e "${INFO} Snell Server restarted successfully."
    else
        echo -e "${ERROR} Failed to restart Snell Server. Check logs."
    fi
}

view_status() {
    systemctl status snell-server
}

# ---
# Configuration and Information
# ---

view_config() {
    if [[ ! -f "${SNELL_CONF}" ]]; then
        echo -e "${ERROR} Configuration file not found. Is Snell installed?"
        return 1
    fi

    # Read values from config
    local port psk obfs host ipv6 tfo dns ver
    port=$(grep -E '^listen\s*=' "${SNELL_CONF}" | awk -F ':' '{print $NF}' | xargs)
    psk=$(grep -E '^psk\s*=' "${SNELL_CONF}" | awk -F '=' '{print $2}' | xargs)
    obfs=$(grep -E '^obfs\s*=' "${SNELL_CONF}" | awk -F '=' '{print $2}' | xargs)
    host=$(grep -E '^obfs-host\s*=' "${SNELL_CONF}" | awk -F '=' '{print $2}' | xargs)
    ipv6=$(grep -E '^ipv6\s*=' "${SNELL_CONF}" | awk -F '=' '{print $2}' | xargs)
    tfo=$(grep -E '^tfo\s*=' "${SNELL_CONF}" | awk -F '=' '{print $2}' | xargs)
    dns=$(grep -E '^dns\s*=' "${SNELL_CONF}" | awk -F '=' '{print $2}' | xargs)
    ver=$(grep -E '^version\s*=' "${SNELL_CONF}" | awk -F '=' '{print $2}' | xargs)

    local ipv4 ipv6_addr
    ipv4=$(curl -s -4 https://ifconfig.co)
    ipv6_addr=$(curl -s -6 https://ifconfig.co)

    echo -e "\n--- Snell Server Configuration ---"
    echo -e "  IPv4 Address : ${GREEN_FONT_PREFIX}${ipv4:-Not Found}${FONT_COLOR_SUFFIX}"
    echo -e "  IPv6 Address : ${GREEN_FONT_PREFIX}${ipv6_addr:-Not Found}${FONT_COLOR_SUFFIX}"
    echo -e "  Port         : ${GREEN_FONT_PREFIX}${port}${FONT_COLOR_SUFFIX}"
    echo -e "  Password (PSK) : ${GREEN_FONT_PREFIX}${psk}${FONT_COLOR_SUFFIX}"
    echo -e "  Obfuscation  : ${GREEN_FONT_PREFIX}${obfs}${FONT_COLOR_SUFFIX}"
    [[ "${obfs}" != "off" ]] && echo -e "  Obfs Host    : ${GREEN_FONT_PREFIX}${host}${FONT_COLOR_SUFFIX}"
    echo -e "  IPv6 Enabled : ${GREEN_FONT_PREFIX}${ipv6}${FONT_COLOR_SUFFIX}"
    echo -e "  TFO Enabled  : ${GREEN_FONT_PREFIX}${tfo}${FONT_COLOR_SUFFIX}"
    [[ "${ver}" -ge 4 ]] && echo -e "  DNS Servers  : ${GREEN_FONT_PREFIX}${dns}${FONT_COLOR_SUFFIX}"
    echo -e "  Version      : ${GREEN_FONT_PREFIX}${ver}${FONT_COLOR_SUFFIX}"
    echo "------------------------------------"

    echo -e "\n${INFO} Surge Profile Line:"
    local surge_line
    surge_line="$(hostname) = snell, ${ipv4}, ${port}, psk=${psk}, version=${ver}, tfo=${tfo}"
    if [[ "${obfs}" != "off" ]]; then
        surge_line+=", obfs=${obfs}, obfs-host=${host}"
    fi
    echo -e "${YELLOW_FONT_PREFIX}${surge_line}${FONT_COLOR_SUFFIX}\n"
}

# ---
# Main Menu
# ---

press_any_key() {
    echo ""
    read -n 1 -s -r -p "Press any key to return to the main menu..."
}

main_menu() {
    clear
    echo "=========================================="
    echo "  Snell Server Management Script"
    echo "=========================================="
    
    if [[ -f "${SNELL_BIN}" ]]; then
        if systemctl is-active --quiet snell-server; then
            echo -e " Status: ${GREEN_FONT_PREFIX}Installed & Running${FONT_COLOR_SUFFIX}"
        else
            echo -e " Status: ${RED_FONT_PREFIX}Installed & Stopped${FONT_COLOR_SUFFIX}"
        fi
        echo "------------------------------------------"
        echo " 1) Start Snell      6) View Config"
        echo " 2) Stop Snell       7) View Logs"
        echo " 3) Restart Snell    8) Uninstall Snell"
        echo " 4) Update Snell     9) Exit"
        echo " 5) Modify Config (TODO)"
    else
        echo -e " Status: ${YELLOW_FONT_PREFIX}Not Installed${FONT_COLOR_SUFFIX}"
        echo "------------------------------------------"
        echo " 1) Install Snell Server"
        echo " 9) Exit"
    fi
    echo "=========================================="

    read -rp "Enter your choice: " choice

    if [[ -f "${SNELL_BIN}" ]]; then
        case "$choice" in
            1) start_snell; press_any_key ;;
            2) stop_snell; press_any_key ;;
            3) restart_snell; press_any_key ;;
            4) echo "Update function not implemented yet."; press_any_key ;; # TODO
            5) echo "Modify config function not implemented yet."; press_any_key ;; # TODO
            6) view_config; press_any_key ;;
            7) view_status ;;
            8) uninstall_snell; press_any_key ;;
            9) exit 0 ;;
            *) echo "Invalid option." ; sleep 1 ;;
        esac
    else
        case "$choice" in
            1) install_snell ;;
            9) exit 0 ;;
            *) echo "Invalid option." ; sleep 1 ;;
        esac
    fi
}

# ---
# Script Execution
# ---

# Initial check
check_root

while true; do
    main_menu
done

