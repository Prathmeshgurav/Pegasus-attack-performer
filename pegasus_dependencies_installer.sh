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

echo -e "${GREEN}[*] DUDE's Pegasus-Like Spyware Dependency Installer${NC}"
echo -e "${YELLOW}Installing dependencies for pegasus_spyware.sh...${NC}"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[-] This script must be run as root (use sudo).${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}[-] Cannot detect OS. Assuming Ubuntu/Debian.${NC}"
    OS="ubuntu"
fi

# Update package lists
echo -e "${YELLOW}[*] Updating package lists...${NC}"
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt update -y
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum update -y || dnf update -y
else
    echo -e "${RED}[-] Unsupported OS: $OS. Install manually.${NC}"
    exit 1
fi

# Install system tools
echo -e "${YELLOW}[*] Installing curl and netcat...${NC}"
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt install -y curl netcat-openbsd
elif [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    yum install -y curl nc || dnf install -y curl nc
fi
if ! command -v curl >/dev/null || ! command -v nc >/dev/null; then
    echo
