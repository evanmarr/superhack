<img width="1536" height="1536" alt="logo" src="https://github.com/user-attachments/assets/c66bce1b-e5d3-4e74-9fa9-69937c1b05a0" />




### Startup package checking

<img width="1138" height="814" alt="demo-image-1" src="https://github.com/user-attachments/assets/84b50182-4436-4660-a6d9-4edb5621dace" />

### Main screen

<img width="1138" height="814" alt="demo-image-2" src="https://github.com/user-attachments/assets/c1ccd93e-c865-44ba-b69b-fc4bc4856e82" />

> **Raspberry Pi Edition v3.0** | **Authorized Use Only**

---

## Overview

SuperHack is a comprehensive penetration testing automation framework designed for Linux systems (including ARM/Raspberry Pi). It provides an interactive menu-driven interface for common security testing tasks, including network scanning, enumeration, brute force attacks, payload generation, wireless security auditing, phishing campaigns, OSINT gathering, and defensive tools.

**⚠️ For educational and authorized security testing purposes only. Use responsibly and only on systems you own or have explicit permission to test.**

---

## Features

- **Network Discovery** - Scan subnets for live hosts using nmap
- **Advanced Nmap Scanner** - Customizable scans with SYN, UDP, stealth, OS detection, and script scanning
- **SMB Enumeration** - Enumerate Windows/Samba shares and users with enum4linux-ng
- **LDAP/AD Enumeration** - Active Directory reconnaissance and BloodHound data collection
- **Web Enumeration** - Directory brute-forcing with Gobuster and vulnerability scanning with Nikto
- **Subdomain Enumeration** - DNS brute force and certificate transparency logs
- **Brute Force** - Multi-protocol brute forcing (SSH, FTP, SMB, HTTP, RDP, VNC, Telnet) with Hydra
- **Payload Generator** - Generate Metasploit payloads (Linux x86/x64, Windows, Python, PHP, Android)
- **Password Cracking** - Hash cracking with John the Ripper and Hashcat
- **Exploit Search** - Search Exploit-DB via searchsploit
- **Phishing Tools** - Website cloning, credential harvesting, email spoofing, QR code phishing, USB drop attacks
- **WiFi Scanner** - Network discovery, WPA/WPA2 handshake capture/cracking, WPS attacks, Evil Twin APs
- **SQL Injection** - Automated SQLMap wrapper for web application testing
- **OSINT** - Domain reconnaissance, email harvesting, social media reconnaissance, Shodan integration
- **Blue Team** - Secure password generation, virus scanning, rootkit detection, file integrity monitoring
- **Autopwn** - Automated exploitation against IP addresses and URLs
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
   mkdir -p ~/.superhack && curl -L https://raw.githubusercontent.com/evanmarr/superhack/main/main.sh -o ~/.superhack/main.sh
   ```

2. **Create the alias:**

   ```bash
   cd && nano .bashrc
   ```

3. **Add the following line at the bottom of the file:**

   ```bash
   alias s-hack='sudo bash ~/.superhack/main.sh'
   ```

4. **Save and exit:**

   - Press `^O` (Ctrl+O), then Enter to save
   - Press `^X` (Ctrl+X) to exit

5. **Reload your shell configuration:**

   ```bash
   source ~/.bashrc
   ```

6. **You're all set!**

---

## Usage

### Launch SuperHack from anywhere:

```bash
s-hack
```

For a cooler look, run this in your terminal:

```bash
sudo apt-get install lolcat -y
```

Then, to run, enter this:

```bash
s-hack | lolcat --seed 17
```

Upon running, the script will check for required dependencies and prompt to install any missing packages.

---

## Directory Structure

SuperHack creates the following directory structure in `~/.superhack/`:

```text
~/.superhack/
├── logs/                 # Application logs
├── wordlists/            # Downloaded wordlists (rockyou.txt, SecLists)
├── phishing/             # Phishing campaign files
│   ├── templates/        # Phishing page templates
│   └── captured/         # Captured credentials/data
├── credentials/          # Harvested credentials storage
├── osint/                # OSINT data storage
└── results/
    ├── nmap/             # Network scan results
    ├── enumeration/      # Enumeration output (SMB, web, LDAP)
    ├── exploitation/     # Payloads and exploit data
    ├── wifi/             # Wireless scan results and handshakes
    ├── bruteforce/       # Hydra brute force results
    ├── cracking/         # Password cracking output
    ├── trojans/          # Generated payload storage
    ├── osint/            # OSINT reports
    ├── blueteam/         # Defensive scan results
    └── autopwn/          # Automated exploitation reports
```

---

## Modules

### 1. Network Scanning
- **Network Discovery** - Scan entire subnets to discover live hosts using nmap ping sweeps
- **Advanced Nmap Scanner** - Fully customizable nmap scanning with options for:
  - Scan types: SYN, Connect, UDP, ACK, Window, FIN/NULL/Xmas
  - Port selection: Top 100/1000, all ports, or custom ranges
  - Service/version detection and OS fingerprinting
  - NSE script scanning (safe, vuln, all, or custom)
  - Timing templates (T0-T5) and fragmentation options

### 2. Enumeration
- **SMB Enumeration** - Enumerate Windows/Samba shares, users, and security policies using enum4linux-ng
- **LDAP/AD Enumeration** - Active Directory reconnaissance including:
  - Anonymous LDAP bind
  - Authenticated LDAP queries
  - User enumeration
  - BloodHound data collection
- **Web Enumeration** - Directory/file brute-forcing with Gobuster and vulnerability scanning with Nikto
- **Subdomain Enumeration** - DNS brute force, certificate transparency logs, and zone transfer attempts

### 3. Brute Force
Multi-protocol brute forcing supporting:
- SSH, FTP, SMB, HTTP Basic Auth, HTTP Form POST, RDP, VNC, Telnet
- Uses Hydra with customizable username lists and wordlists

### 4. Payload Generator
Generate Metasploit payloads via msfvenom:
- Linux x86/x64 reverse shells
- Windows reverse shells and Meterpreter
- Python, PHP, ASP.NET reverse shells
- Android APK payloads
- Custom payload specification

### 5. Exploit Search
Search Exploit-DB for known vulnerabilities using searchsploit with detailed exploit viewing.

### 6. Password Cracking
- **John the Ripper** - Auto-detect or specify hash formats
- **Hashcat** - GPU-accelerated cracking with mode selection
- **Hash Type Identification** - Identify unknown hash formats

### 7. Phishing Tools
- **Website Cloning** - Clone websites for credential harvesting with built-in PHP capture scripts
- **Custom Phishing Pages** - Generate corporate, social media, banking, or custom login pages
- **Email Spoofing** - Send spoofed emails using sendemail
- **QR Code Phishing** - Generate malicious QR codes
- **USB Drop Attacks** - Create autorun payloads for USB devices

### 8. Wireless Attacks
- Access point discovery and monitoring
- WPA/WPA2 handshake capture and cracking
- WPS PIN attacks (Reaver)
- Deauthentication attacks
- Evil Twin fake access point creation
- WiFi brute forcer with automated handshake capture

### 9. SQL Injection
Automated SQLMap wrapper for detecting and exploiting SQL injection vulnerabilities.

### 10. OSINT
- **Domain Information** - DNS records, subdomain enumeration, IP information
- **Email OSINT** - Email harvesting with theHarvester
- **Social Media Recon** - Username checking across multiple platforms
- **Metadata Extraction** - Extract metadata from files using exiftool
- **Shodan Search** - Query Shodan for internet-facing devices
- **Full OSINT Report** - Comprehensive automated reconnaissance

### 11. Blue Team
- **Secure Password Generator** - Generate strong passwords and passphrases
- **Virus Scanning** - ClamAV integration for malware detection
- **Rootkit Detection** - rkhunter and chkrootkit scanning
- **File Integrity Monitoring** - Create baselines and detect changes
- **Network Monitoring** - Monitor active connections and listening ports
- **System Hardening Check** - Audit SSH, firewall, services, and SUID files

### 12. Autopwn
- **Autopwn IP** - Automated exploitation against IP addresses with full enumeration
- **Autopwn URL** - Automated web application testing with vulnerability scanning

### 13. Utilities
- **Network Listener** - Quick reverse shell listener setup
- **Quick Reverse Shell** - Generate one-liner reverse shells in multiple languages
- **View Logs** - Browse session logs

---

## Required Dependencies

### Core System Packages
```text
nmap, metasploit-framework, netcat-traditional, hydra, gobuster
dirb, enum4linux-ng, john, hashcat, sqlmap, nikto, masscan
dnsutils, whois, curl, wget, git, iw, tcpdump, proxychains4
wireless-tools, aircrack-ng, python3, python3-pip, arp-scan
netdiscover, macchanger, crackmapexec, responder, bloodhound.py
wireshark, tshark, bettercap, mitmproxy, httrack, sendemail
openssl, sshpass, tmux, screen, vim, nano, lolcat, clamav
clamav-daemon, rkhunter, chkrootkit, haveged, libreoffice
exiftool, theharvester, maltego, spiderfoot, recon-ng, photon
```

### Python Packages
```text
impacket, requests, beautifulsoup4, scapy, pwntools, python-nmap
smbprotocol, ldap3, pyftpdlib, pysmb, paramiko, cryptography
pyOpenSSL, flask, django, mechanize, selenium, pyautogui
shodan, censys, requests-html, social-analyzer, holehe
```

---

## SECURITY NOTICE

**This tool is intended for authorized security testing and educational purposes only.**

- Only use on systems you own or have explicit written permission to test
- Unauthorized access to computer systems is illegal
- The authors assume no liability for misuse of this software
- Always follow responsible disclosure practices

---

## Author
Evan Marr - 2026

## License
For educational purposes only. Use at your own risk.
