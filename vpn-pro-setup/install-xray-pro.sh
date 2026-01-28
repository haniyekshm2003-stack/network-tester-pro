#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  🚀 XRAY PRO INSTALLER - ULTIMATE VPN SETUP
#  نصب کننده حرفه‌ای Xray با بهترین پروتکل‌ها
#  
#  پروتکل‌ها:
#  ✅ VLESS + XTLS-Vision (سریع‌ترین)
#  ✅ VLESS + Reality (غیرقابل شناسایی)
#  ✅ Trojan + WebSocket (پایدارترین)
#  ✅ VMess + gRPC (HTTP/2)
#═══════════════════════════════════════════════════════════════════════════════

set -e

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    🚀 XRAY PRO INSTALLER v2.0                                  ║"
echo "║                    Ultimate VPN Setup for Iran                                 ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# تنظیمات
SERVER_IP=$(curl -s ifconfig.me)
UUID=$(cat /proc/sys/kernel/random/uuid)
REALITY_PRIVATE_KEY=""
REALITY_PUBLIC_KEY=""
REALITY_SHORT_ID=$(openssl rand -hex 8)
TROJAN_PASSWORD=$(openssl rand -hex 16)
VMESS_ID=$(cat /proc/sys/kernel/random/uuid)

echo -e "${CYAN}📍 IP سرور: ${SERVER_IP}${NC}"
echo -e "${CYAN}🔑 UUID: ${UUID}${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# نصب پیش‌نیازها
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${YELLOW}📦 نصب پیش‌نیازها...${NC}"

apt update -qq
apt install -y curl wget unzip jq openssl socat cron net-tools ufw

# غیرفعال کردن فایروال یا باز کردن پورت‌ها
ufw allow 443/tcp
ufw allow 80/tcp
ufw allow 8443/tcp
ufw allow 2083/tcp
ufw allow 2053/tcp
ufw --force enable 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════════════════
# نصب Xray
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${YELLOW}⬇️ نصب آخرین نسخه Xray...${NC}"

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# تولید کلیدهای Reality
echo -e "\n${YELLOW}🔐 تولید کلیدهای Reality...${NC}"
REALITY_KEYS=$(xray x25519)
REALITY_PRIVATE_KEY=$(echo "$REALITY_KEYS" | grep "Private key:" | awk '{print $3}')
REALITY_PUBLIC_KEY=$(echo "$REALITY_KEYS" | grep "Public key:" | awk '{print $3}')

echo -e "${GREEN}✅ Private Key: ${REALITY_PRIVATE_KEY}${NC}"
echo -e "${GREEN}✅ Public Key: ${REALITY_PUBLIC_KEY}${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# ساخت فایل کانفیگ Xray
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${YELLOW}⚙️ ساخت کانفیگ Xray...${NC}"

cat > /usr/local/etc/xray/config.json << XRAYCONFIG
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log"
    },
    "inbounds": [
        {
            "tag": "vless-reality",
            "listen": "0.0.0.0",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "www.google.com:443",
                    "xver": 0,
                    "serverNames": [
                        "www.google.com",
                        "google.com",
                        "www.microsoft.com",
                        "microsoft.com"
                    ],
                    "privateKey": "${REALITY_PRIVATE_KEY}",
                    "shortIds": ["${REALITY_SHORT_ID}"]
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": ["http", "tls", "quic"]
            }
        },
        {
            "tag": "trojan-ws",
            "listen": "0.0.0.0",
            "port": 2083,
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "${TROJAN_PASSWORD}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/trojan-ws"
                }
            }
        },
        {
            "tag": "vmess-grpc",
            "listen": "0.0.0.0",
            "port": 2053,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${VMESS_ID}",
                        "alterId": 0
                    }
                ]
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "vmess-grpc"
                }
            }
        },
        {
            "tag": "vless-ws",
            "listen": "0.0.0.0",
            "port": 8443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/vless-ws"
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ],
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "ip": ["geoip:private"],
                "outboundTag": "block"
            },
            {
                "type": "field",
                "protocol": ["bittorrent"],
                "outboundTag": "block"
            }
        ]
    }
}
XRAYCONFIG

# ═══════════════════════════════════════════════════════════════════════════════
# راه‌اندازی سرویس
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${YELLOW}🚀 راه‌اندازی Xray...${NC}"

mkdir -p /var/log/xray
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

sleep 3
if systemctl is-active --quiet xray; then
    echo -e "${GREEN}✅ Xray با موفقیت راه‌اندازی شد!${NC}"
else
    echo -e "${RED}❌ خطا در راه‌اندازی Xray${NC}"
    journalctl -u xray -n 20 --no-pager
    exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# تولید لینک‌های اشتراک
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 نصب کامل شد! لینک‌های اتصال:${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"

# VLESS Reality (بهترین و سریع‌ترین)
VLESS_REALITY="vless://${UUID}@${SERVER_IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.google.com&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp#🚀-VLESS-Reality-UltraFast"

# VLESS WebSocket
VLESS_WS="vless://${UUID}@${SERVER_IP}:8443?encryption=none&security=none&type=ws&path=/vless-ws#📡-VLESS-WS"

# Trojan WebSocket
TROJAN_WS="trojan://${TROJAN_PASSWORD}@${SERVER_IP}:2083?security=none&type=ws&path=/trojan-ws#🛡️-Trojan-WS"

# VMess gRPC
VMESS_JSON=$(cat << EOF
{
    "v": "2",
    "ps": "⚡-VMess-gRPC",
    "add": "${SERVER_IP}",
    "port": "2053",
    "id": "${VMESS_ID}",
    "aid": "0",
    "net": "grpc",
    "type": "none",
    "host": "",
    "path": "vmess-grpc",
    "tls": ""
}
EOF
)
VMESS_GRPC="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"

echo -e "\n${CYAN}1️⃣ VLESS + Reality (سریع‌ترین - ضد شناسایی):${NC}"
echo -e "${GREEN}${VLESS_REALITY}${NC}"

echo -e "\n${CYAN}2️⃣ VLESS + WebSocket (پایدار):${NC}"
echo -e "${GREEN}${VLESS_WS}${NC}"

echo -e "\n${CYAN}3️⃣ Trojan + WebSocket (رمزنگاری قوی):${NC}"
echo -e "${GREEN}${TROJAN_WS}${NC}"

echo -e "\n${CYAN}4️⃣ VMess + gRPC (HTTP/2):${NC}"
echo -e "${GREEN}${VMESS_GRPC}${NC}"

# ذخیره در فایل
SAVE_DIR="/root/vpn-configs"
mkdir -p "$SAVE_DIR"

cat > "$SAVE_DIR/subscription.txt" << EOF
# 🚀 VPN Pro Subscription
# IP: ${SERVER_IP}
# Date: $(date)

${VLESS_REALITY}
${VLESS_WS}
${TROJAN_WS}
${VMESS_GRPC}
EOF

cat > "$SAVE_DIR/config-info.txt" << EOF
═══════════════════════════════════════════════════════════════════════════════
                        🔐 VPN PRO CONFIGURATION INFO
═══════════════════════════════════════════════════════════════════════════════

📍 Server IP: ${SERVER_IP}

🔑 VLESS UUID: ${UUID}
🔑 Trojan Password: ${TROJAN_PASSWORD}
🔑 VMess ID: ${VMESS_ID}

🔐 Reality Private Key: ${REALITY_PRIVATE_KEY}
🔐 Reality Public Key: ${REALITY_PUBLIC_KEY}
🔐 Reality Short ID: ${REALITY_SHORT_ID}

📡 پورت‌ها:
   - 443  → VLESS Reality (اصلی)
   - 8443 → VLESS WebSocket
   - 2083 → Trojan WebSocket
   - 2053 → VMess gRPC

═══════════════════════════════════════════════════════════════════════════════
EOF

echo -e "\n${YELLOW}📁 کانفیگ‌ها ذخیره شدند در:${NC}"
echo -e "   ${SAVE_DIR}/subscription.txt"
echo -e "   ${SAVE_DIR}/config-info.txt"

# ═══════════════════════════════════════════════════════════════════════════════
# تست سرویس
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "\n${YELLOW}🧪 تست پورت‌ها...${NC}"
sleep 2
for port in 443 8443 2083 2053; do
    if netstat -tuln | grep -q ":${port} "; then
        echo -e "${GREEN}✅ پورت ${port} فعال است${NC}"
    else
        echo -e "${RED}❌ پورت ${port} غیرفعال است${NC}"
    fi
done

echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 نصب کامل شد!${NC}"
echo -e "${YELLOW}💡 برای استفاده، لینک‌های بالا رو در v2rayNG یا Clash کپی کنید${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
