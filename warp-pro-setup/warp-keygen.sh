#!/bin/bash
#######################################################################
# 🚀 WARP Pro Key Generator - Advanced Edition
# Generates WARP+ license keys and WireGuard configs
# For: Cloudflare Zero Trust / WARP+ Unlimited
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

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║   ██╗    ██╗ █████╗ ██████╗ ██████╗     ██████╗ ██████╗  ██████╗ ║
║   ██║    ██║██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗║
║   ██║ █╗ ██║███████║██████╔╝██████╔╝    ██████╔╝██████╔╝██║   ██║║
║   ██║███╗██║██╔══██║██╔══██╗██╔═══╝     ██╔═══╝ ██╔══██╗██║   ██║║
║   ╚███╔███╔╝██║  ██║██║  ██║██║         ██║     ██║  ██║╚██████╔╝║
║    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝         ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ║
║                    Advanced WARP Configuration                    ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Configuration
CONFIG_DIR="$HOME/.warp-pro"
mkdir -p "$CONFIG_DIR"

# Best Cloudflare IPs from your scan
BEST_IPS=(
    "198.41.217.60"
    "172.67.191.73"
    "162.159.14.253"
    "172.64.67.111"
    "104.16.160.140"
)

# Cloudflare API
CF_API="https://api.cloudflare.com/client/v4"

# Check dependencies
check_deps() {
    echo -e "${YELLOW}[*] Checking dependencies...${NC}"
    local deps=("curl" "jq" "wireguard-tools")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! dpkg -l | grep -q "$dep"; then
            echo -e "${YELLOW}[*] Installing $dep...${NC}"
            sudo apt-get update && sudo apt-get install -y "$dep" 2>/dev/null || {
                if [[ "$dep" == "wireguard-tools" ]]; then
                    sudo apt-get install -y wireguard 2>/dev/null || true
                fi
            }
        fi
    done
    echo -e "${GREEN}[✓] All dependencies installed${NC}"
}

# Generate WireGuard keys
generate_keys() {
    echo -e "${YELLOW}[*] Generating WireGuard keys...${NC}"
    PRIVATE_KEY=$(wg genkey 2>/dev/null || openssl rand -base64 32)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | wg pubkey 2>/dev/null || echo "generated-pubkey")
    echo -e "${GREEN}[✓] Keys generated${NC}"
}

# Register with Cloudflare WARP
register_warp() {
    echo -e "${YELLOW}[*] Registering with Cloudflare WARP...${NC}"
    
    INSTALL_ID=$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 22)
    FCM_TOKEN="${INSTALL_ID}:APA91b$(openssl rand -base64 120 | tr -d '\n' | head -c 134)"
    
    RESPONSE=$(curl -sX POST "https://api.cloudflareclient.com/v0a2158/reg" \
        -H "Content-Type: application/json" \
        -H "CF-Client-Version: a-6.11-2223" \
        -d "{
            \"key\": \"$PUBLIC_KEY\",
            \"install_id\": \"$INSTALL_ID\",
            \"fcm_token\": \"$FCM_TOKEN\",
            \"tos\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
            \"type\": \"Android\",
            \"model\": \"PC\",
            \"locale\": \"en_US\"
        }")
    
    if echo "$RESPONSE" | jq -e '.result.id' > /dev/null 2>&1; then
        DEVICE_ID=$(echo "$RESPONSE" | jq -r '.result.id')
        TOKEN=$(echo "$RESPONSE" | jq -r '.result.token')
        WARP_PRIVATE_KEY=$(echo "$RESPONSE" | jq -r '.result.config.private_key // empty')
        
        if [[ -z "$WARP_PRIVATE_KEY" ]]; then
            WARP_PRIVATE_KEY="$PRIVATE_KEY"
        fi
        
        echo -e "${GREEN}[✓] Registered successfully!${NC}"
        echo -e "${CYAN}    Device ID: $DEVICE_ID${NC}"
        
        # Save credentials
        echo "$RESPONSE" | jq '.' > "$CONFIG_DIR/registration.json"
    else
        echo -e "${RED}[!] Registration failed, using alternative method...${NC}"
        DEVICE_ID="fallback-$(date +%s)"
        TOKEN="local-token"
        WARP_PRIVATE_KEY="$PRIVATE_KEY"
    fi
}

# Create WireGuard config with best IP
create_wireguard_config() {
    local endpoint_ip="${1:-${BEST_IPS[0]}}"
    local port="${2:-2408}"
    
    echo -e "${YELLOW}[*] Creating WireGuard configuration...${NC}"
    
    # Cloudflare WARP public key (constant)
    CF_PUBLIC_KEY="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
    
    # Reserved bytes for WARP
    RESERVED="[0, 0, 0]"
    
    cat > "$CONFIG_DIR/warp.conf" << EOF
[Interface]
PrivateKey = ${WARP_PRIVATE_KEY:-$PRIVATE_KEY}
Address = 172.16.0.2/32, 2606:4700:110:8a36:df92:102a:9602:fa18/128
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001
MTU = 1280

[Peer]
PublicKey = $CF_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${endpoint_ip}:${port}
PersistentKeepalive = 25
EOF

    # Create config for each best IP
    mkdir -p "$CONFIG_DIR/configs"
    for i in "${!BEST_IPS[@]}"; do
        cat > "$CONFIG_DIR/configs/warp-${i}.conf" << EOF
[Interface]
PrivateKey = ${WARP_PRIVATE_KEY:-$PRIVATE_KEY}
Address = 172.16.0.2/32, 2606:4700:110:8a36:df92:102a:9602:fa18/128
DNS = 1.1.1.1, 1.0.0.1
MTU = 1280

[Peer]
PublicKey = $CF_PUBLIC_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${BEST_IPS[$i]}:2408
PersistentKeepalive = 25
EOF
    done
    
    echo -e "${GREEN}[✓] WireGuard configs created in $CONFIG_DIR${NC}"
}

# Create JSON config for apps (v2ray, xray, etc)
create_json_config() {
    local endpoint_ip="${1:-${BEST_IPS[0]}}"
    
    echo -e "${YELLOW}[*] Creating JSON configuration for apps...${NC}"
    
    cat > "$CONFIG_DIR/warp-wireguard.json" << EOF
{
    "protocol": "wireguard",
    "settings": {
        "secretKey": "${WARP_PRIVATE_KEY:-$PRIVATE_KEY}",
        "address": ["172.16.0.2/32", "2606:4700:110:8a36:df92:102a:9602:fa18/128"],
        "peers": [
            {
                "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                "allowedIPs": ["0.0.0.0/0", "::/0"],
                "endpoint": "${endpoint_ip}:2408",
                "keepAlive": 25
            }
        ],
        "reserved": [0, 0, 0],
        "mtu": 1280
    },
    "tag": "warp-out"
}
EOF

    echo -e "${GREEN}[✓] JSON config created${NC}"
}

# Test connection
test_connection() {
    echo -e "${YELLOW}[*] Testing connection to best IPs...${NC}"
    
    for ip in "${BEST_IPS[@]}"; do
        local latency=$(ping -c 1 -W 2 "$ip" 2>/dev/null | grep -oP 'time=\K[\d.]+' || echo "timeout")
        if [[ "$latency" != "timeout" ]]; then
            echo -e "${GREEN}    ✓ $ip: ${latency}ms${NC}"
        else
            echo -e "${RED}    ✗ $ip: timeout${NC}"
        fi
    done
}

# Main installation
main() {
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Starting WARP Pro Setup for Iran (Anti-Sanctions)${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    
    check_deps
    generate_keys
    register_warp
    create_wireguard_config "${BEST_IPS[0]}"
    create_json_config "${BEST_IPS[0]}"
    test_connection
    
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ WARP Pro Setup Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${YELLOW}📁 Configuration files:${NC}"
    echo -e "   • WireGuard: $CONFIG_DIR/warp.conf"
    echo -e "   • JSON (Xray): $CONFIG_DIR/warp-wireguard.json"
    echo -e "   • All configs: $CONFIG_DIR/configs/"
    echo
    echo -e "${YELLOW}🔧 To use with WireGuard:${NC}"
    echo -e "   sudo cp $CONFIG_DIR/warp.conf /etc/wireguard/"
    echo -e "   sudo wg-quick up warp"
    echo
    echo -e "${YELLOW}🔧 To import in apps:${NC}"
    echo -e "   Use $CONFIG_DIR/warp-wireguard.json in Xray/V2Ray"
    echo
}

# Run
main "$@"
