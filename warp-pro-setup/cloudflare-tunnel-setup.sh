#!/bin/bash
#######################################################################
# 🌐 Cloudflare Zero Trust Tunnel Setup
# For: tiki2k.com with Zero Trust paid plan
# Creates private tunnel connection through your VPS
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

# Configuration - YOUR CLOUDFLARE DETAILS
CF_ZONE_ID="a16e32a98e20cd2e03da2d50682f38b0"
CF_ACCOUNT_ID="31b99eb61828a98ac16f8dad92c0d22d"
CF_DOMAIN="tiki2k.com"
CF_EMAIL="H.keshmiri2003@gmail.com"

# Tunnel configuration
TUNNEL_NAME="iran-bypass-tunnel"
TUNNEL_DIR="$HOME/.cloudflared"

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║   ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ███████╗██╗      █████╗   ║
║  ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║     ██╔══██╗  ║
║  ██║     ██║     ██║   ██║██║   ██║██║  ██║█████╗  ██║     ███████║  ║
║  ██║     ██║     ██║   ██║██║   ██║██║  ██║██╔══╝  ██║     ██╔══██║  ║
║  ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝██║     ███████╗██║  ██║  ║
║   ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝  ║
║            Zero Trust Tunnel - Iran Bypass Edition                    ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Install cloudflared
install_cloudflared() {
    echo -e "${YELLOW}[*] Installing cloudflared...${NC}"
    
    if command -v cloudflared &> /dev/null; then
        echo -e "${GREEN}[✓] cloudflared already installed${NC}"
        cloudflared --version
        return
    fi
    
    # Download latest cloudflared
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
    esac
    
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -o /tmp/cloudflared
    chmod +x /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
    
    echo -e "${GREEN}[✓] cloudflared installed${NC}"
    cloudflared --version
}

# Login to Cloudflare
login_cloudflare() {
    echo -e "${YELLOW}[*] Logging into Cloudflare...${NC}"
    
    mkdir -p "$TUNNEL_DIR"
    
    if [[ -f "$TUNNEL_DIR/cert.pem" ]]; then
        echo -e "${GREEN}[✓] Already logged in${NC}"
        return
    fi
    
    echo -e "${CYAN}[!] Opening browser for authentication...${NC}"
    echo -e "${YELLOW}    If browser doesn't open, visit the URL shown below${NC}"
    
    cloudflared tunnel login || {
        echo -e "${RED}[!] Auto-login failed. Please run manually:${NC}"
        echo -e "${CYAN}    cloudflared tunnel login${NC}"
        return 1
    }
    
    echo -e "${GREEN}[✓] Logged in successfully${NC}"
}

# Create tunnel
create_tunnel() {
    echo -e "${YELLOW}[*] Creating tunnel: $TUNNEL_NAME...${NC}"
    
    # Check if tunnel exists
    EXISTING=$(cloudflared tunnel list 2>/dev/null | grep "$TUNNEL_NAME" || true)
    if [[ -n "$EXISTING" ]]; then
        echo -e "${GREEN}[✓] Tunnel already exists${NC}"
        TUNNEL_ID=$(echo "$EXISTING" | awk '{print $1}')
    else
        cloudflared tunnel create "$TUNNEL_NAME"
        TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    fi
    
    echo -e "${GREEN}[✓] Tunnel ID: $TUNNEL_ID${NC}"
}

# Create tunnel config for WARP proxy
create_tunnel_config() {
    echo -e "${YELLOW}[*] Creating tunnel configuration...${NC}"
    
    cat > "$TUNNEL_DIR/config.yml" << EOF
# Cloudflare Tunnel Configuration for Iran Bypass
tunnel: $TUNNEL_NAME
credentials-file: $TUNNEL_DIR/$TUNNEL_ID.json

# Enable WARP routing
warp-routing:
  enabled: true

# Ingress rules - proxy everything through tunnel
ingress:
  # SOCKS5 proxy for local applications
  - hostname: proxy.${CF_DOMAIN}
    service: socks-proxy
    originRequest:
      noTLSVerify: true
  
  # SSH access (optional)
  - hostname: ssh.${CF_DOMAIN}
    service: ssh://localhost:22
  
  # HTTP proxy
  - hostname: http.${CF_DOMAIN}
    service: http://localhost:8080
  
  # Catch-all
  - service: http_status:404

# Connection settings for Iran
originRequest:
  connectTimeout: 30s
  noHappyEyeballs: true
  
# Protocol selection (try HTTP/2 first, fall back to QUIC)
protocol: auto

# Edge connection settings
edge-ip-version: auto

# Logging
loglevel: info
EOF

    echo -e "${GREEN}[✓] Configuration created at $TUNNEL_DIR/config.yml${NC}"
}

# Create DNS records
setup_dns() {
    echo -e "${YELLOW}[*] Setting up DNS records...${NC}"
    
    # Create CNAME for tunnel
    cloudflared tunnel route dns "$TUNNEL_NAME" "proxy.${CF_DOMAIN}" 2>/dev/null || true
    cloudflared tunnel route dns "$TUNNEL_NAME" "ssh.${CF_DOMAIN}" 2>/dev/null || true
    cloudflared tunnel route dns "$TUNNEL_NAME" "http.${CF_DOMAIN}" 2>/dev/null || true
    
    echo -e "${GREEN}[✓] DNS records configured${NC}"
}

# Create systemd service
create_service() {
    echo -e "${YELLOW}[*] Creating systemd service...${NC}"
    
    sudo tee /etc/systemd/system/cloudflared-tunnel.service > /dev/null << EOF
[Unit]
Description=Cloudflare Tunnel for Iran Bypass
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=notify
TimeoutStartSec=0
User=$USER
ExecStart=/usr/local/bin/cloudflared tunnel --config $TUNNEL_DIR/config.yml run
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable cloudflared-tunnel
    
    echo -e "${GREEN}[✓] Service created and enabled${NC}"
}

# Create local SOCKS5 proxy script
create_local_proxy() {
    echo -e "${YELLOW}[*] Creating local proxy configuration...${NC}"
    
    cat > "$TUNNEL_DIR/start-proxy.sh" << 'EOF'
#!/bin/bash
# Start cloudflared as local SOCKS5 proxy
# This creates a local proxy that routes through Cloudflare

cloudflared access tcp --hostname proxy.tiki2k.com --listener localhost:1080 &
echo "SOCKS5 proxy started on localhost:1080"
echo "Configure your apps to use SOCKS5 proxy: 127.0.0.1:1080"
EOF
    chmod +x "$TUNNEL_DIR/start-proxy.sh"
    
    echo -e "${GREEN}[✓] Local proxy script created${NC}"
}

# Main
main() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Setting up Cloudflare Zero Trust Tunnel${NC}"
    echo -e "${CYAN}  Domain: $CF_DOMAIN${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    install_cloudflared
    
    echo
    echo -e "${YELLOW}[!] Next Steps:${NC}"
    echo -e "1. Run: ${CYAN}cloudflared tunnel login${NC}"
    echo -e "2. Run: ${CYAN}cloudflared tunnel create $TUNNEL_NAME${NC}"
    echo -e "3. Run: ${CYAN}cloudflared tunnel route dns $TUNNEL_NAME proxy.$CF_DOMAIN${NC}"
    echo -e "4. Start: ${CYAN}cloudflared tunnel run $TUNNEL_NAME${NC}"
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ cloudflared installed!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

main "$@"
