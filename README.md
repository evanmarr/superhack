![SuperHack Demo Image](https://github.com/user-attachments/assets/4f54b96c-6289-4120-a0b6-b52bb67e9b58)

> **Raspberry Pi Edition v2.1** | **Authorized Use Only**

---

## Overview

SuperHack is a comprehensive penetration testing automation framework designed for Linux systems (including ARM/Raspberry Pi). It provides an interactive menu-driven interface for common security testing tasks, including network scanning, enumeration, brute force attacks, payload generation, and wireless security auditing.

**⚠️ For educational and authorized security testing purposes only. Use responsibly and only on systems you own or have explicit permission to test.**

---

## Features

- **Network Discovery** - Scan subnets for live hosts using nmap
- **Advanced Nmap Scanner** - Customizable scans with SYN, UDP, stealth, OS detection, and script scanning
- **SMB Enumeration** - Enumerate Windows/Samba shares and users with enum4linux-ng
- **Web Enumeration** - Directory brute-forcing with Gobuster and vulnerability scanning with Nikto
- **Brute Force** - Multi-protocol brute forcing (SSH, FTP, SMB, HTTP) with Hydra
- **Payload Generator** - Generate Metasploit payloads (Linux x86/x64, Windows, Python)
- **Password Cracking** - Hash cracking with John the Ripper and Hashcat
- **Exploit Search** - Search Exploit-DB via searchsploit
- **WiFi Scanner** - Network discovery, device enumeration, and monitor mode packet capture
- **SQL Injection** - Automated SQLMap wrapper for web application testing
- **Netcat Listener** - Quick reverse shell listener setup
- **Smart Dependency Manager** - Automatic detection and installation of required tools

---

## Installation

### Prerequisites

- Linux-based operating system (Debian/Ubuntu/Kali recommended)
- Raspberry Pi compatible (ARM architecture)
- `sudo` privileges
- Internet connection for downloading dependencies

### Quick Install

1. **Clone the repository:**

   ```bash
    sudo git clone https://github.com/evanmarr/superhack.git ~/.superhack/
   ```
2. **Create the alias:**

   ```bash
    cd && nano .bashrc
   ```
3. **Add the following line at the bottom of the file:**

   ```bash
    alias s-hack='sudo bash ~/.superhack/main.sh'
   ```

4. **Save and exit:***

    Press ^O (Ctrl+O), then Enter to save
    Press ^X (Ctrl+X) to exit
    Reload your shell configuration:

    ```bash
     source ~/.bashrc
    ```

5. **You're all set!**

## Usage

### Launch SuperHack from anywhere:

```bash
s-hack
```

Upon running, the script will check for required dependencies and prompt to install any missing packages.

## Directory Structure

SuperHack creates the following directory structure in ~/.superhack/:

```text
~/.superhack/
├── logs/                 # Application logs
├── wordlists/            # Downloaded wordlists (rockyou.txt, SecLists)
└── results/
    ├── nmap/             # Network scan results
    ├── enumeration/      # Enumeration output (SMB, web)
    ├── exploitation/     # Payloads and exploit data
    ├── wifi/             # Wireless scan results
    ├── bruteforce/       # Hydra brute force results
    └── cracking/         # Password cracking output
```



### Modules
1. **Network Discovery**
   
    Scan entire subnets to discover live hosts using nmap ping sweeps.

3. **Advanced Nmap Scanner**
   
    Fully customizable nmap scanning with options for:

    Scan types: SYN, Connect, UDP, ACK, Window, FIN/NULL/Xmas
    Port selection: Top 100/1000, all ports, or custom ranges
    Service/version detection and OS fingerprinting
    NSE script scanning (safe, vuln, all, or custom)
    Timing templates (T0-T5) and fragmentation options
5. **SMB Enumeration**
   
    Enumerate Windows/Samba shares, users, and security policies using enum4linux-ng.

7. **Web Enumeration**
   
    Directory/file brute-forcing with Gobuster
    Vulnerability scanning with Nikto
    Automatic wordlist selection from SecLists
9. **Brute Force**
    
    Multi-protocol brute forcing supporting:

    SSH
    FTP
    SMB
    HTTP Basic Authentication
    Uses Hydra with customizable username lists and wordlists.

11. **Payload Generator**
    
    Generate Metasploit payloads via msfvenom:

    Linux x86/x64 reverse shells
    Windows reverse shells
    Python reverse shells
    Custom payload specification
13. **Password Cracking**
    
    John the Ripper - Auto-detect or specify hash formats
    Hashcat - GPU-accelerated cracking with mode selection
15. **Exploit Search**
    
    Search Exploit-DB for known vulnerabilities using searchsploit.

17. **Netcat Listener**
    
    Quick setup for reverse shell listeners.

19. **WiFi Scanner**
    
    Comprehensive wireless security testing:

    Access point discovery
    Device enumeration on current network (ARP scan, nmap, netdiscover)
    Monitor mode packet capture with airodump-ng
    Continuous monitoring for new device detection
21. **SQL Injection Scan**
    
    Automated SQLMap wrapper for detecting SQL injection vulnerabilities.

23. **Dependency Manager**
    
    ### Smart package manager that:

    Detects missing system packages (apt)
    Detects missing Python packages (pip)
    Downloads wordlists (rockyou.txt, SecLists)
    Selective or bulk installation
    Required Dependencies
    ### Core System Packages:
    ```text
    nmap,
    metasploit-framework,
    netcat-traditional
    hydra,
    gobuster,
    dirb,
    enum4linux-ng
    john,
    hashcat,
    sqlmap,
    nikto,
    masscan
    aircrack-ng,
    wireless-tools,
    tcpdump
    python3,
    python3-pip,
    git,
    curl,
    wget
    ```
    ### Python Packages
    ```text
    impacket,
    requests,
    beautifulsoup4
    scapy,
    pwntools,
    python-nmap
    ```

## SECURITY NOTICE

***This tool is intended for authorized security testing and educational purposes only.***

***Only use on systems you own or have explicit written permission to test***
***Unauthorized access to computer systems is illegal***
***The authors assume no liability for misuse of this software***
***Always follow responsible disclosure practices***

## Author:
Evan Marr - 2026

## License
For educational purposes only. Use at your own risk.
