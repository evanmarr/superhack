<img width="1536" height="1536" alt="logo" src="https://github.com/user-attachments/assets/c66bce1b-e5d3-4e74-9fa9-69937c1b05a0" />




### Startup package checking

<img width="1138" height="814" alt="demo-image-1" src="https://github.com/user-attachments/assets/c596bb23-6375-4131-8c75-677e0fb9d93a" />

### Main screen

<img width="1138" height="814" alt="demo-image-2" src="https://github.com/user-attachments/assets/a5453d74-cec1-486b-8a58-48bcccfcb2b1" />

> **Raspberry Pi Edition v3.0** | **Authorized Use Only**

---

## Overview

SuperHack is a comprehensive penetration testing automation framework designed for Linux systems (including ARM/Raspberry Pi). It provides an interactive menu-driven interface for common security testing tasks, including network scanning, enumeration, brute force attacks, payload generation, wireless security auditing, phishing campaigns, OSINT gathering, and defensive tools.

**⚠️ For educational and authorized security testing purposes only. Use responsibly and only on systems you own or have explicit permission to test.**

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

   ```text
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
