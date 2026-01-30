#!/bin/bash
#######################################################################
# 🔍 Advanced Cloudflare IP Scanner & Optimizer
# Finds the fastest Cloudflare IPs for Iran connections
# Uses multiple testing methods for best results
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

# Configuration
RESULT_FILE="$HOME/.warp-pro/best-ips.txt"
FULL_RESULT="$HOME/.warp-pro/scan-results.csv"
CONCURRENT=50
TIMEOUT=2

mkdir -p "$HOME/.warp-pro"

echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║   ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ███████╗██╗      █████╗   ║
║  ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║     ██╔══██╗  ║
║  ██║     ██║     ██║   ██║██║   ██║██║  ██║█████╗  ██║     ███████║  ║
║  ██║     ██║     ██║   ██║██║   ██║██║  ██║██╔══╝  ██║     ██╔══██║  ║
║  ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝██║     ███████╗██║  ██║  ║
║   ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝  ║
║                      IP Scanner & Optimizer                          ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Cloudflare IP ranges
CF_RANGES=(
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "108.162.192.0/18"
    "131.0.72.0/22"
    "141.101.64.0/18"
    "162.158.0.0/15"
    "172.64.0.0/13"
    "173.245.48.0/20"
    "188.114.96.0/20"
    "190.93.240.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
)

# Known good IPs for Iran (from your scan)
KNOWN_GOOD_IPS=(
    "198.41.217.60"
    "172.67.191.73"
    "162.159.14.253"
    "172.64.67.111"
    "104.16.160.140"
    "172.67.100.137"
    "172.67.194.248"
    "198.41.216.37"
)

# Test ports
PORTS=(443 2408 2053 2083 2087 2096 8443 80 8080)

# Check dependencies
check_deps() {
    echo -e "${YELLOW}[*] Checking dependencies...${NC}"
    
    local deps=("curl" "ping" "nc" "timeout")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}[!] Missing: $dep${NC}"
            sudo apt-get install -y netcat-openbsd iputils-ping curl 2>/dev/null || true
        fi
    done
    
    # Try to install CloudflareScanner
    if ! command -v cfscanner &> /dev/null && ! [[ -f "./CFScanner" ]]; then
        echo -e "${YELLOW}[*] Downloading CloudflareScanner...${NC}"
        ARCH=$(uname -m)
        case $ARCH in
            x86_64) ARCH="amd64" ;;
            aarch64) ARCH="arm64" ;;
        esac
        
        curl -sL "https://github.com/MortezaBashworker/CFScanner/releases/latest/download/cfscanner_linux_${ARCH}" -o CFScanner 2>/dev/null && chmod +x CFScanner || true
    fi
    
    echo -e "${GREEN}[✓] Dependencies ready${NC}"
}

# Test single IP with TCP
test_tcp() {
    local ip=$1
    local port=${2:-443}
    
    local start=$(date +%s%N)
    if timeout $TIMEOUT bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
        local end=$(date +%s%N)
        local latency=$(( (end - start) / 1000000 ))
        echo "$latency"
    else
        echo "-1"
    fi
}

# Test single IP with ping
test_ping() {
    local ip=$1
    local result=$(ping -c 1 -W $TIMEOUT "$ip" 2>/dev/null | grep -oP 'time=\K[\d.]+' || echo "-1")
    echo "$result"
}

# Test single IP with curl
test_http() {
    local ip=$1
    local result=$(curl -o /dev/null -s -w '%{time_total}' --connect-timeout $TIMEOUT "http://$ip" 2>/dev/null || echo "-1")
    if [[ "$result" != "-1" ]]; then
        result=$(echo "$result * 1000" | bc | cut -d. -f1)
    fi
    echo "$result"
}

# Test download speed
test_download() {
    local ip=$1
    local size="1048576"  # 1MB
    
    local start=$(date +%s%N)
    local bytes=$(curl -s --connect-timeout 3 --max-time 5 -H "Host: speed.cloudflare.com" "http://$ip/__down?bytes=$size" 2>/dev/null | wc -c)
    local end=$(date +%s%N)
    
    if [[ $bytes -gt 0 ]]; then
        local duration=$(( (end - start) / 1000000 ))  # ms
        if [[ $duration -gt 0 ]]; then
            local speed=$(( bytes * 1000 / duration / 1024 ))  # KB/s
            echo "$speed"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Quick scan known good IPs
quick_scan() {
    echo -e "${YELLOW}[*] Quick scanning known good IPs...${NC}"
    echo
    
    echo "IP Address,Ping (ms),TCP (ms),Speed (KB/s)" > "$FULL_RESULT"
    > "$RESULT_FILE"
    
    printf "%-20s %-12s %-12s %-15s\n" "IP Address" "Ping" "TCP" "Speed"
    printf "%-20s %-12s %-12s %-15s\n" "----------" "----" "---" "-----"
    
    for ip in "${KNOWN_GOOD_IPS[@]}"; do
        local ping_ms=$(test_ping "$ip")
        local tcp_ms=$(test_tcp "$ip" 443)
        local speed=$(test_download "$ip")
        
        # Color based on results
        local color=$GREEN
        if [[ "$ping_ms" == "-1" ]] || [[ "$tcp_ms" == "-1" ]]; then
            color=$RED
        elif [[ "${ping_ms%.*}" -gt 200 ]]; then
            color=$YELLOW
        fi
        
        printf "${color}%-20s %-12s %-12s %-15s${NC}\n" "$ip" "${ping_ms}ms" "${tcp_ms}ms" "${speed}KB/s"
        
        if [[ "$ping_ms" != "-1" ]] && [[ "$tcp_ms" != "-1" ]]; then
            echo "$ip" >> "$RESULT_FILE"
            echo "$ip,$ping_ms,$tcp_ms,$speed" >> "$FULL_RESULT"
        fi
    done
    
    echo
}

# Full scan (more comprehensive)
full_scan() {
    echo -e "${YELLOW}[*] Running full scan (this may take a while)...${NC}"
    
    # Check if CFScanner is available
    if [[ -f "./CFScanner" ]]; then
        echo -e "${CYAN}[*] Using CloudflareScanner...${NC}"
        ./CFScanner -f ips.txt -o result.csv 2>/dev/null || true
    fi
    
    # Manual scan of ranges
    echo -e "${CYAN}[*] Scanning Cloudflare IP ranges...${NC}"
    
    local temp_ips=$(mktemp)
    local count=0
    
    # Generate sample IPs from ranges
    for range in "${CF_RANGES[@]}"; do
        local base=$(echo $range | cut -d/ -f1 | cut -d. -f1-3)
        for i in $(seq 1 10 255); do
            echo "${base}.${i}" >> "$temp_ips"
            ((count++))
            [[ $count -ge 200 ]] && break 2
        done
    done
    
    echo -e "${CYAN}[*] Testing $count IPs...${NC}"
    
    # Test in parallel (limited)
    cat "$temp_ips" | while read ip; do
        (
            ping_ms=$(test_ping "$ip")
            if [[ "$ping_ms" != "-1" ]] && [[ "${ping_ms%.*}" -lt 300 ]]; then
                tcp_ms=$(test_tcp "$ip" 443)
                if [[ "$tcp_ms" != "-1" ]]; then
                    echo "$ip,$ping_ms,$tcp_ms" >> "$FULL_RESULT"
                fi
            fi
        ) &
        
        # Limit concurrent jobs
        while [[ $(jobs -r -p | wc -l) -ge $CONCURRENT ]]; do
            sleep 0.1
        done
    done
    
    wait
    rm -f "$temp_ips"
    
    echo -e "${GREEN}[✓] Full scan complete${NC}"
}

# Sort and display results
show_results() {
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Top 10 Fastest IPs${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -f "$FULL_RESULT" ]]; then
        # Sort by TCP latency and show top 10
        echo
        printf "%-5s %-20s %-12s %-12s %-15s\n" "#" "IP Address" "Ping" "TCP" "Speed"
        printf "%-5s %-20s %-12s %-12s %-15s\n" "-" "----------" "----" "---" "-----"
        
        tail -n +2 "$FULL_RESULT" | sort -t, -k3 -n | head -10 | nl -w2 -s'. ' | while read line; do
            local num=$(echo $line | cut -d. -f1)
            local data=$(echo $line | cut -d. -f2-)
            local ip=$(echo $data | cut -d, -f1 | tr -d ' ')
            local ping=$(echo $data | cut -d, -f2)
            local tcp=$(echo $data | cut -d, -f3)
            local speed=$(echo $data | cut -d, -f4)
            
            printf "${CYAN}%-5s${NC} %-20s %-12s %-12s %-15s\n" "$num" "$ip" "${ping}ms" "${tcp}ms" "${speed:-N/A}KB/s"
        done
    fi
    
    echo
    echo -e "${YELLOW}📁 Results saved to:${NC}"
    echo -e "   • Best IPs: $RESULT_FILE"
    echo -e "   • Full results: $FULL_RESULT"
}

# Generate WARP config with best IP
generate_config() {
    echo
    echo -e "${YELLOW}[*] Generating WARP config with best IP...${NC}"
    
    local best_ip=$(tail -n +2 "$FULL_RESULT" 2>/dev/null | sort -t, -k3 -n | head -1 | cut -d, -f1)
    
    if [[ -z "$best_ip" ]]; then
        best_ip="${KNOWN_GOOD_IPS[0]}"
    fi
    
    echo -e "${GREEN}[✓] Best IP: $best_ip${NC}"
    
    # Update WARP config if script exists
    if [[ -f "$HOME/.warp-pro/warp.conf" ]]; then
        sed -i "s/Endpoint = .*/Endpoint = ${best_ip}:2408/" "$HOME/.warp-pro/warp.conf"
        echo -e "${GREEN}[✓] Updated $HOME/.warp-pro/warp.conf${NC}"
    fi
    
    echo "$best_ip" > "$HOME/.warp-pro/current-ip.txt"
}

# Main menu
main() {
    check_deps
    
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Select Scan Mode${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "  ${CYAN}1)${NC} Quick scan (known good IPs)"
    echo -e "  ${CYAN}2)${NC} Full scan (all Cloudflare ranges)"
    echo -e "  ${CYAN}3)${NC} Both"
    echo
    
    read -p "Select [1-3]: " choice
    
    case $choice in
        1) quick_scan ;;
        2) full_scan ;;
        3) quick_scan; full_scan ;;
        *) quick_scan ;;
    esac
    
    show_results
    generate_config
    
    echo
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✅ Scan Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run
main "$@"
