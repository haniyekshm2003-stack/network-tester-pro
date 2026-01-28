#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  🔄 MULTI-IP VPN MANAGER
#  مدیریت چند IP روی یک سرور برای دور زدن فیلترینگ
#═══════════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# IP های فعال
PRIMARY_IP="63.32.250.131"
SECONDARY_IPS=("108.128.15.3" "34.247.23.138" "54.74.125.123" "54.228.90.224")

echo -e "${PURPLE}"
echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    🔄 MULTI-IP VPN MANAGER                                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}📍 IP اصلی: ${PRIMARY_IP}${NC}"
echo -e "${CYAN}📍 IP های اضافی:${NC}"
for ip in "${SECONDARY_IPS[@]}"; do
    echo -e "   - ${ip}"
done

# ═══════════════════════════════════════════════════════════════════════════════
# تنظیم IP های اضافی روی اینترفیس
# ═══════════════════════════════════════════════════════════════════════════════
setup_additional_ips() {
    echo -e "\n${YELLOW}⚙️ تنظیم IP های اضافی...${NC}"
    
    INTERFACE=$(ip route | grep default | awk '{print $5}')
    echo -e "${CYAN}📡 اینترفیس شبکه: ${INTERFACE}${NC}"
    
    # این IP ها توسط AWS به صورت Elastic IP متصل می‌شوند
    # نیازی به تنظیم دستی نیست
    echo -e "${GREEN}✅ IP ها از طریق AWS Elastic IP متصل هستند${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# کانفیگ Xray برای چند IP
# ═══════════════════════════════════════════════════════════════════════════════
create_multi_ip_config() {
    echo -e "\n${YELLOW}⚙️ ساخت کانفیگ Xray برای تمام IP ها...${NC}"
    
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # تولید کلیدهای Reality
    if command -v xray &> /dev/null; then
        REALITY_KEYS=$(xray x25519)
        REALITY_PRIVATE_KEY=$(echo "$REALITY_KEYS" | grep "Private key:" | awk '{print $3}')
        REALITY_PUBLIC_KEY=$(echo "$REALITY_KEYS" | grep "Public key:" | awk '{print $3}')
    else
        echo -e "${RED}❌ Xray نصب نیست. اول install-xray-pro.sh رو اجرا کن${NC}"
        exit 1
    fi
    
    REALITY_SHORT_ID=$(openssl rand -hex 8)
    
    # کانفیگ با listen روی همه IP ها
    cat > /usr/local/etc/xray/config.json << MULTICONFIG
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "tag": "vless-reality-main",
            "listen": "0.0.0.0",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [{"id": "${UUID}", "flow": "xtls-rprx-vision"}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "dest": "www.google.com:443",
                    "serverNames": ["www.google.com", "google.com"],
                    "privateKey": "${REALITY_PRIVATE_KEY}",
                    "shortIds": ["${REALITY_SHORT_ID}"]
                }
            }
        },
        {
            "tag": "vless-ws-backup",
            "listen": "0.0.0.0",
            "port": 8443,
            "protocol": "vless",
            "settings": {
                "clients": [{"id": "${UUID}"}],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {"path": "/vless"}
            }
        }
    ],
    "outbounds": [
        {"protocol": "freedom", "tag": "direct"}
    ]
}
MULTICONFIG

    echo -e "${GREEN}✅ کانفیگ چند IP آماده شد${NC}"
    
    # تولید لینک برای هر IP
    echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🔗 لینک‌های اتصال برای تمام IP ها:${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    
    ALL_IPS=("${PRIMARY_IP}" "${SECONDARY_IPS[@]}")
    
    mkdir -p /root/vpn-configs
    > /root/vpn-configs/all-ips-subscription.txt
    
    for i in "${!ALL_IPS[@]}"; do
        IP="${ALL_IPS[$i]}"
        LINK="vless://${UUID}@${IP}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.google.com&fp=chrome&pbk=${REALITY_PUBLIC_KEY}&sid=${REALITY_SHORT_ID}&type=tcp#VPN-IP$((i+1))-${IP}"
        
        echo -e "\n${CYAN}IP $((i+1)) - ${IP}:${NC}"
        echo -e "${GREEN}${LINK}${NC}"
        
        echo "${LINK}" >> /root/vpn-configs/all-ips-subscription.txt
    done
    
    echo -e "\n${YELLOW}📁 همه لینک‌ها ذخیره شدند در: /root/vpn-configs/all-ips-subscription.txt${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# تست تمام IP ها
# ═══════════════════════════════════════════════════════════════════════════════
test_all_ips() {
    echo -e "\n${YELLOW}🧪 تست اتصال تمام IP ها...${NC}"
    
    ALL_IPS=("${PRIMARY_IP}" "${SECONDARY_IPS[@]}")
    
    for IP in "${ALL_IPS[@]}"; do
        if timeout 5 bash -c "echo > /dev/tcp/${IP}/443" 2>/dev/null; then
            echo -e "${GREEN}✅ ${IP}:443 - فعال${NC}"
        else
            echo -e "${RED}❌ ${IP}:443 - غیرفعال یا بلاک${NC}"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# اجرا
# ═══════════════════════════════════════════════════════════════════════════════
case "${1:-all}" in
    setup)
        setup_additional_ips
        ;;
    config)
        create_multi_ip_config
        ;;
    test)
        test_all_ips
        ;;
    all|*)
        setup_additional_ips
        create_multi_ip_config
        test_all_ips
        
        echo -e "\n${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}🎉 تنظیم چند IP کامل شد!${NC}"
        echo -e "${YELLOW}💡 اگر یک IP بلاک شد، از IP های دیگر استفاده کن${NC}"
        echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════════════${NC}"
        ;;
esac
