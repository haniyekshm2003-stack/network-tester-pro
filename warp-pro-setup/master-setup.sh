#!/bin/bash
#######################################################################
# 🚀 Master WARP Setup Script
# One-click setup for all WARP configurations
# Domain: tiki2k.com | Zero Trust: Enabled
#######################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║   ██╗    ██╗ █████╗ ██████╗ ██████╗     ███╗   ███╗ █████╗ ███████╗   ║
║   ██║    ██║██╔══██╗██╔══██╗██╔══██╗    ████╗ ████║██╔══██╗██╔════╝   ║
║   ██║ █╗ ██║███████║██████╔╝██████╔╝    ██╔████╔██║███████║███████╗   ║
║   ██║███╗██║██╔══██║██╔══██╗██╔═══╝     ██║╚██╔╝██║██╔══██║╚════██║   ║
║   ╚███╔███╔╝██║  ██║██║  ██║██║         ██║ ╚═╝ ██║██║  ██║███████║   ║
║    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝         ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ║
║                                                                        ║
║           🇮🇷 Anti-Sanctions Master Setup for Iran 🇮🇷                   ║
║                     Domain: tiki2k.com                                 ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Show configuration
show_config() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Your Configuration${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "  ${YELLOW}Domain:${NC}     tiki2k.com"
    echo -e "  ${YELLOW}Email:${NC}      H.keshmiri2003@gmail.com"
    echo -e "  ${YELLOW}Zone ID:${NC}    a16e32a98e20cd2e03da2d50682f38b0"
    echo -e "  ${YELLOW}Account ID:${NC} 31b99eb61828a98ac16f8dad92c0d22d"
    echo
    echo -e "  ${GREEN}Best IPs from your scan:${NC}"
    echo -e "    1. 198.41.217.60  - 20.75 MB/s"
    echo -e "    2. 172.67.191.73  - 20.22 MB/s"
    echo -e "    3. 162.159.14.253 - 17.48 MB/s"
    echo
}

# Menu
show_menu() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Select Setup Option${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "  ${CYAN}1)${NC} 🔑 Generate WARP Keys & WireGuard Config"
    echo -e "  ${CYAN}2)${NC} 📱 Install Official WARP Client"
    echo -e "  ${CYAN}3)${NC} 🔍 Scan for Best Cloudflare IPs"
    echo -e "  ${CYAN}4)${NC} 🌐 Setup Cloudflare Zero Trust Tunnel"
    echo -e "  ${CYAN}5)${NC} ⚡ Quick Setup (Recommended - All in One)"
    echo -e "  ${CYAN}6)${NC} 📋 Show Configuration Files"
    echo -e "  ${CYAN}7)${NC} 🔧 Manual WireGuard Connection"
    echo -e "  ${CYAN}8)${NC} ❌ Exit"
    echo
}

# Generate WARP keys
option_1() {
    echo -e "${YELLOW}[*] Running WARP Key Generator...${NC}"
    bash "$SCRIPT_DIR/warp-keygen.sh"
}

# Install WARP client
option_2() {
    echo -e "${YELLOW}[*] Installing WARP Client...${NC}"
    bash "$SCRIPT_DIR/install-warp-client.sh"
}

# Scan IPs
option_3() {
    echo -e "${YELLOW}[*] Running IP Scanner...${NC}"
    bash "$SCRIPT_DIR/cloudflare-ip-scanner.sh"
}

# Setup tunnel
option_4() {
    echo -e "${YELLOW}[*] Setting up Cloudflare Tunnel...${NC}"
    bash "$SCRIPT_DIR/cloudflare-tunnel-setup.sh"
}

# Quick setup - all in one
option_5() {
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Quick Setup - All in One${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${CYAN}Step 1/4: Installing dependencies...${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq wireguard wireguard-tools curl jq 2>/dev/null || true
    
    echo -e "${CYAN}Step 2/4: Generating WARP configuration...${NC}"
    bash "$SCRIPT_DIR/warp-keygen.sh"
    
    echo -e "${CYAN}Step 3/4: Scanning for best IPs...${NC}"
    echo "1" | bash "$SCRIPT_DIR/cloudflare-ip-scanner.sh" 2>/dev/null || true
    
    echo -e "${CYAN}Step 4/4: Setting up WireGuard...${NC}"
    if [[ -f "$HOME/.warp-pro/warp.conf" ]]; then
        sudo cp "$HOME/.warp-pro/warp.conf" /etc/wireguard/warp.conf 2>/dev/null || true
        echo -e "${GREEN}[✓] WireGuard config installed${NC}"
    fi
    
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ Quick Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${YELLOW}To connect:${NC}"
    echo -e "  ${CYAN}sudo wg-quick up warp${NC}"
    echo
    echo -e "${YELLOW}To disconnect:${NC}"
    echo -e "  ${CYAN}sudo wg-quick down warp${NC}"
    echo
}

# Show config files
option_6() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Configuration Files${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    echo -e "${YELLOW}📁 Generated Configs:${NC}"
    echo -e "   • $HOME/.warp-pro/warp.conf"
    echo -e "   • $HOME/.warp-pro/warp-wireguard.json"
    echo -e "   • $HOME/.warp-pro/registration.json"
    echo
    
    echo -e "${YELLOW}📁 Template Configs:${NC}"
    echo -e "   • $SCRIPT_DIR/configs/warp-wireguard.conf"
    echo -e "   • $SCRIPT_DIR/configs/xray-warp-config.json"
    echo
    
    echo -e "${YELLOW}📁 Best IPs:${NC}"
    echo -e "   • $HOME/.warp-pro/best-ips.txt"
    echo -e "   • $HOME/.warp-pro/scan-results.csv"
    echo
    
    if [[ -f "$HOME/.warp-pro/warp.conf" ]]; then
        echo -e "${CYAN}Current WireGuard Config:${NC}"
        echo "───────────────────────────────────"
        cat "$HOME/.warp-pro/warp.conf"
        echo "───────────────────────────────────"
    fi
}

# Manual WireGuard connection
option_7() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Manual WireGuard Connection${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    if [[ ! -f "$HOME/.warp-pro/warp.conf" ]]; then
        echo -e "${YELLOW}[!] No config found. Generating...${NC}"
        option_1
    fi
    
    echo -e "${CYAN}[*] Installing WireGuard config...${NC}"
    sudo cp "$HOME/.warp-pro/warp.conf" /etc/wireguard/warp.conf
    
    echo -e "${CYAN}[*] Connecting to WARP...${NC}"
    sudo wg-quick up warp
    
    echo
    echo -e "${GREEN}[✓] Connected!${NC}"
    echo
    echo -e "${CYAN}Current connection:${NC}"
    sudo wg show
    echo
    echo -e "${CYAN}Your new IP:${NC}"
    curl -s https://cloudflare.com/cdn-cgi/trace | grep -E "ip=|loc=|warp="
}

# Main loop
main() {
    show_config
    
    while true; do
        show_menu
        read -p "Select option [1-8]: " choice
        echo
        
        case $choice in
            1) option_1 ;;
            2) option_2 ;;
            3) option_3 ;;
            4) option_4 ;;
            5) option_5 ;;
            6) option_6 ;;
            7) option_7 ;;
            8) 
                echo -e "${GREEN}Goodbye! 👋${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run
main "$@"
