#!/bin/bash
#═══════════════════════════════════════════════════════════════════════════════
#  🚀 REMOTE VPN INSTALLER
#  نصب کننده از راه دور VPN روی سرور AWS
#═══════════════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# تنظیمات سرور
SERVER_IP="108.128.15.3"  # IP اصلی سرور
SSH_KEY="/path/to/vpn-server-key.pem"  # مسیر کلید SSH
SSH_USER="ubuntu"  # یا ec2-user برای Amazon Linux

echo -e "${PURPLE}"
echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    🚀 REMOTE VPN INSTALLER                                     ║"
echo "║                    نصب VPN از راه دور روی AWS                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# بررسی دسترسی
# ═══════════════════════════════════════════════════════════════════════════════
check_access() {
    echo -e "${YELLOW}🔍 بررسی دسترسی به سرور...${NC}"
    
    if [[ ! -f "$SSH_KEY" ]]; then
        echo -e "${RED}❌ کلید SSH پیدا نشد: $SSH_KEY${NC}"
        echo -e "${YELLOW}💡 مسیر کلید رو در خط 14 تغییر بده${NC}"
        exit 1
    fi
    
    chmod 400 "$SSH_KEY"
    
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" "echo connected" 2>/dev/null; then
        echo -e "${GREEN}✅ اتصال به سرور برقرار شد${NC}"
    else
        echo -e "${RED}❌ نمی‌تونم به سرور وصل بشم${NC}"
        echo -e "${YELLOW}💡 ممکنه پورت 22 بلاک باشه${NC}"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# نصب Xray از راه دور
# ═══════════════════════════════════════════════════════════════════════════════
install_xray_remote() {
    echo -e "\n${YELLOW}📦 نصب Xray روی سرور...${NC}"
    
    # اسکریپت نصب رو به سرور منتقل کن
    scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
        "$(dirname "$0")/install-xray-pro.sh" \
        "$SSH_USER@$SERVER_IP:/tmp/"
    
    # اجرا روی سرور
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" \
        "sudo chmod +x /tmp/install-xray-pro.sh && sudo /tmp/install-xray-pro.sh"
    
    echo -e "${GREEN}✅ Xray با موفقیت نصب شد${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# دریافت کانفیگ‌ها
# ═══════════════════════════════════════════════════════════════════════════════
get_configs() {
    echo -e "\n${YELLOW}📥 دریافت کانفیگ‌ها...${NC}"
    
    mkdir -p ~/vpn-configs
    
    scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
        "$SSH_USER@$SERVER_IP:/root/vpn-configs/*" \
        ~/vpn-configs/
    
    echo -e "${GREEN}✅ کانفیگ‌ها دانلود شدند به ~/vpn-configs/${NC}"
    
    echo -e "\n${CYAN}📋 محتویات کانفیگ:${NC}"
    cat ~/vpn-configs/subscription.txt 2>/dev/null || echo "فایل پیدا نشد"
}

# ═══════════════════════════════════════════════════════════════════════════════
# منوی اصلی
# ═══════════════════════════════════════════════════════════════════════════════
case "${1:-menu}" in
    check)
        check_access
        ;;
    install)
        check_access
        install_xray_remote
        get_configs
        ;;
    configs)
        get_configs
        ;;
    menu|*)
        echo -e "${CYAN}استفاده:${NC}"
        echo -e "  $0 check   - تست اتصال به سرور"
        echo -e "  $0 install - نصب کامل VPN"
        echo -e "  $0 configs - دریافت کانفیگ‌ها"
        echo ""
        echo -e "${YELLOW}قبل از اجرا:${NC}"
        echo -e "1. مسیر کلید SSH رو در خط 14 تنظیم کن"
        echo -e "2. از AWS Console کلید vpn-server-key.pem رو دانلود کن"
        ;;
esac
