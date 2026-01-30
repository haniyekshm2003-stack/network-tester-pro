#!/bin/bash
#######################################################################
# 📱 Official WARP Client Installation & Configuration
# Installs official Cloudflare WARP client with Zero Trust
# For Linux systems with Iran optimization
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

# Your Zero Trust organization
ZERO_TRUST_ORG="tiki2k"
CF_EMAIL="H.keshmiri2003@gmail.com"

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║  ██╗    ██╗ █████╗ ██████╗ ██████╗      ██████╗██╗     ██╗      ║
║  ██║    ██║██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██║     ██║      ║
║  ██║ █╗ ██║███████║██████╔╝██████╔╝    ██║     ██║     ██║      ║
║  ██║███╗██║██╔══██║██╔══██╗██╔═══╝     ██║     ██║     ██║      ║
║  ╚███╔███╔╝██║  ██║██║  ██║██║         ╚██████╗███████╗██║      ║
║   ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝          ╚═════╝╚══════╝╚═╝      ║
║            Official WARP Client for Linux                         ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}[!] Running as root${NC}"
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        OS=$(uname -s)
    fi
    echo -e "${CYAN}[*] Detected OS: $OS $VERSION${NC}"
}

# Install WARP client
install_warp() {
    echo -e "${YELLOW}[*] Installing Cloudflare WARP client...${NC}"
    
    case $OS in
        ubuntu|debian)
            # Add Cloudflare GPG key
            curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
            
            # Add repository
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
            
            # Install
            sudo apt-get update
            sudo apt-get install -y cloudflare-warp
            ;;
        fedora|centos|rhel)
            # Add repository
            sudo rpm -ivh https://pkg.cloudflareclient.com/cloudflare-release-el8.rpm 2>/dev/null || true
            sudo dnf install -y cloudflare-warp || sudo yum install -y cloudflare-warp
            ;;
        arch|manjaro)
            # Install from AUR
            yay -S cloudflare-warp-bin || paru -S cloudflare-warp-bin
            ;;
        *)
            echo -e "${RED}[!] Unsupported OS: $OS${NC}"
            echo -e "${YELLOW}[*] Trying generic installation...${NC}"
            
            # Download generic binary
            ARCH=$(uname -m)
            case $ARCH in
                x86_64) ARCH="amd64" ;;
                aarch64) ARCH="arm64" ;;
            esac
            
            curl -L "https://pkg.cloudflareclient.com/pool/$(lsb_release -cs)/main/c/cloudflare-warp/cloudflare-warp_2024.6.497.0-1_${ARCH}.deb" -o /tmp/cloudflare-warp.deb
            sudo dpkg -i /tmp/cloudflare-warp.deb || sudo apt-get install -f -y
            ;;
    esac
    
    echo -e "${GREEN}[✓] WARP client installed${NC}"
}

# Configure WARP
configure_warp() {
    echo -e "${YELLOW}[*] Configuring WARP...${NC}"
    
    # Wait for service to start
    sleep 2
    
    # Register device
    echo -e "${CYAN}[*] Registering device...${NC}"
    warp-cli registration new || warp-cli register 2>/dev/null || true
    
    # Set mode to WARP (full tunnel)
    echo -e "${CYAN}[*] Setting WARP mode...${NC}"
    warp-cli mode warp 2>/dev/null || warp-cli set-mode warp 2>/dev/null || true
    
    # Enable always-on
    warp-cli enable-always-on 2>/dev/null || true
    
    # Accept TOS
    warp-cli --accept-tos || true
    
    echo -e "${GREEN}[✓] WARP configured${NC}"
}

# Configure for Zero Trust
configure_zero_trust() {
    echo -e "${YELLOW}[*] Configuring Zero Trust...${NC}"
    
    if [[ -n "$ZERO_TRUST_ORG" ]]; then
        echo -e "${CYAN}[*] Connecting to Zero Trust org: $ZERO_TRUST_ORG${NC}"
        
        # Set organization
        warp-cli teams-enroll "$ZERO_TRUST_ORG" 2>/dev/null || {
            echo -e "${YELLOW}[!] Manual enrollment required${NC}"
            echo -e "${CYAN}    Run: warp-cli teams-enroll $ZERO_TRUST_ORG${NC}"
        }
    fi
    
    echo -e "${GREEN}[✓] Zero Trust configuration complete${NC}"
}

# Create optimized settings
optimize_for_iran() {
    echo -e "${YELLOW}[*] Optimizing for Iran...${NC}"
    
    # Create custom endpoint config
    mkdir -p ~/.warp-pro
    
    cat > ~/.warp-pro/endpoints.txt << 'EOF'
# Best Cloudflare endpoints for Iran
# Tested with CloudflareScanner

198.41.217.60:2408
172.67.191.73:2408
162.159.14.253:2408
172.64.67.111:2408
104.16.160.140:2408

# Alternative ports
198.41.217.60:500
198.41.217.60:854
198.41.217.60:1701
198.41.217.60:4500
198.41.217.60:2053
198.41.217.60:2083
198.41.217.60:2087
198.41.217.60:2096
198.41.217.60:8443
EOF

    echo -e "${GREEN}[✓] Optimization complete${NC}"
    echo -e "${CYAN}    Best endpoints saved to ~/.warp-pro/endpoints.txt${NC}"
}

# Connect WARP
connect_warp() {
    echo -e "${YELLOW}[*] Connecting to WARP...${NC}"
    
    warp-cli connect
    
    sleep 3
    
    # Check status
    echo -e "${CYAN}[*] Connection status:${NC}"
    warp-cli status
    
    # Test connection
    echo -e "${CYAN}[*] Testing connection...${NC}"
    curl -s https://cloudflare.com/cdn-cgi/trace | grep -E "ip=|warp=|loc="
}

# Show status
show_status() {
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  WARP Status${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    warp-cli status 2>/dev/null || echo "Status unavailable"
    
    echo
    echo -e "${YELLOW}📋 Useful Commands:${NC}"
    echo -e "   ${CYAN}warp-cli connect${NC}    - Connect to WARP"
    echo -e "   ${CYAN}warp-cli disconnect${NC} - Disconnect from WARP"
    echo -e "   ${CYAN}warp-cli status${NC}     - Check connection status"
    echo -e "   ${CYAN}warp-cli settings${NC}   - View settings"
    echo -e "   ${CYAN}warp-cli account${NC}    - View account info"
    echo
}

# Main
main() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Installing Official Cloudflare WARP Client${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    check_root
    detect_os
    install_warp
    configure_warp
    optimize_for_iran
    
    echo
    echo -e "${YELLOW}[?] Do you want to configure Zero Trust? (y/n)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        configure_zero_trust
    fi
    
    echo
    echo -e "${YELLOW}[?] Connect to WARP now? (y/n)${NC}"
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        connect_warp
    fi
    
    show_status
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ WARP Client Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run
main "$@"
