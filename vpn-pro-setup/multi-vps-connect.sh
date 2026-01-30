#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# 🔌 Multi-VPS SSH Connection Manager
# 📌 Connects to multiple VPS servers from separate terminals
# ═══════════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ────────────────────────────────────────────────────────────────────────────
# 📝 VPS CONFIGURATION - Edit these with your VPS details
# ────────────────────────────────────────────────────────────────────────────
declare -A VPS_SERVERS=(
    ["VPS-1"]="user@your-vps1-ip -p 22"
    ["VPS-2"]="user@your-vps2-ip -p 22"
    ["VPS-3"]="user@your-vps3-ip -p 22"
    ["VPS-4"]="user@your-vps4-ip -p 22"
)

# SSH Options for stability
SSH_OPTS="-o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ConnectTimeout=30 -o StrictHostKeyChecking=no"

# ────────────────────────────────────────────────────────────────────────────
# 🔧 FUNCTIONS
# ────────────────────────────────────────────────────────────────────────────

show_menu() {
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  🔌 Multi-VPS SSH Connection Manager${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Available VPS Servers:${NC}"
    echo ""

    local i=1
    for vps in "${!VPS_SERVERS[@]}"; do
        echo -e "  ${GREEN}$i)${NC} $vps"
        ((i++))
    done

    echo ""
    echo -e "  ${BLUE}a)${NC} Connect to ALL VPS (opens new terminals)"
    echo -e "  ${MAGENTA}t)${NC} Test all connections"
    echo -e "  ${RED}q)${NC} Quit"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
}

connect_vps() {
    local vps_name=$1
    local vps_conn=${VPS_SERVERS[$vps_name]}

    if [[ -z "$vps_conn" ]]; then
        echo -e "${RED}❌ VPS '$vps_name' not found!${NC}"
        return 1
    fi

    echo -e "${GREEN}🔌 Connecting to $vps_name...${NC}"
    echo -e "${YELLOW}Command: ssh $SSH_OPTS $vps_conn${NC}"

    # Connect using SSH
    ssh "$SSH_OPTS" "$vps_conn"
}

test_connection() {
    local vps_name=$1
    local vps_conn=${VPS_SERVERS[$vps_name]}

    echo -e -n "${YELLOW}Testing $vps_name... ${NC}"

    if ssh "$SSH_OPTS" -o BatchMode=yes -o ConnectTimeout=5 "$vps_conn" "echo ok" 2>/dev/null; then
        echo -e "${GREEN}✅ Connected${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        return 1
    fi
}

test_all_connections() {
    echo -e "${CYAN}🔍 Testing all VPS connections...${NC}"
    echo ""

    local success=0
    local failed=0

    for vps in "${!VPS_SERVERS[@]}"; do
        if test_connection "$vps"; then
            ((success++))
        else
            ((failed++))
        fi
    done

    echo ""
    echo -e "${GREEN}✅ Success: $success${NC} | ${RED}❌ Failed: $failed${NC}"
}

# ────────────────────────────────────────────────────────────────────────────
# 🚀 MAIN
# ────────────────────────────────────────────────────────────────────────────

main() {
    # Check if a VPS name was provided as argument
    if [[ -n "$1" ]]; then
        connect_vps "$1"
        exit $?
    fi

    # Interactive mode
    while true; do
        show_menu
        read -p "Select option: " choice

        case $choice in
            1|2|3|4)
                local vps_names=(${!VPS_SERVERS[@]})
                local selected_vps=${vps_names[$((choice-1))]}
                connect_vps "$selected_vps"
                ;;
            a|A)
                echo -e "${YELLOW}Opening connections to all VPS...${NC}"
                for vps in "${!VPS_SERVERS[@]}"; do
                    echo -e "${GREEN}→ $vps${NC}"
                done
                ;;
            t|T)
                test_all_connections
                read -p "Press Enter to continue..."
                ;;
            q|Q)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
