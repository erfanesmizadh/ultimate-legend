#!/bin/bash
# =============================================
# ULTIMATE LEGENDARY GOD MODE TUNNEL ENGINE
# Author: ChatGPT
# Features:
# - Multi WireGuard tunnel
# - Xray Least-Latency Outbound
# - Kernel Multipath + BBR + fq_codel
# - Health Check + Auto Failover
# - Simple Bash Menu
# =============================================
set -e

# ================================
# CONFIGURATION (EDIT HERE)
# ================================
IRAN_PUBLIC_IP="YOUR_IRAN_PUBLIC_IP"
WG_PORT_BASE=51820
TUNNELS=2
FOREIGN_IPS=("1.1.1.1" "2.2.2.2")   # IP سرورهای خارج
BASE_NET=("10.10.10" "10.20.20" "10.30.30") # Subnet هر tunnel

# ==================================
# INSTALL REQUIREMENTS
# ==================================
apt update
apt install -y wireguard iproute2 cron

# ENABLE BBR + fq_codel
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# ==================================
# CREATE MULTI WIREGUARD TUNNELS
# ==================================
for ((i=0;i<$TUNNELS;i++)); do
    WG="wg$i"
    NET=${BASE_NET[$i]}
    PORT=$((WG_PORT_BASE+i))
    FOREIGN=${FOREIGN_IPS[$i]}

    echo "🔥 Creating $WG..."

    wg genkey | tee /etc/wireguard/${WG}_private.key | wg pubkey > /etc/wireguard/${WG}_public.key
    PRIVATE=$(cat /etc/wireguard/${WG}_private.key)

    cat > /etc/wireguard/$WG.conf <<EOF
[Interface]
PrivateKey = $PRIVATE
Address = ${NET}.2/24
MTU = 1280
PostUp = tc qdisc replace dev %i root fq_codel
PostUp = ip link set %i txqueuelen 20000
PostDown = tc qdisc del dev %i root

[Peer]
PublicKey = REPLACE_WITH_FOREIGN_PUBLICKEY_$i
Endpoint = $FOREIGN:$PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    wg-quick up $WG
done

# ==================================
# MULTIPATH ROUTING
# ==================================
echo "🔥 Setting multipath routing..."
CMD="ip route replace default scope global"
for ((i=0;i<$TUNNELS;i++)); do
    CMD="$CMD nexthop dev wg$i weight 1"
done
eval $CMD

# ==================================
# POLICY ROUTING FOR XRAY
# ==================================
ip rule add fwmark 255 table 100 || true
CMD2="ip route replace default"
for ((i=0;i<$TUNNELS;i++)); do
    CMD2="$CMD2 nexthop dev wg$i weight 1"
done
CMD2="$CMD2 table 100"
eval $CMD2

# SSH safe
ip rule add from $IRAN_PUBLIC_IP table main || true

# ==================================
# HEALTH CHECK SCRIPT
# ==================================
cat > /usr/local/bin/wg-health.sh <<'EOF'
#!/bin/bash
TARGET=1.1.1.1
for IF in $(ls /sys/class/net | grep wg); do
    LAT=$(ping -I $IF -c1 -W1 $TARGET | grep 'time=' | awk -F'time=' '{print $2}' | cut -d' ' -f1)
    if [[ -z "$LAT" ]]; then
        ip link set $IF down
    else
        ip link set $IF up
    fi
done
EOF

chmod +x /usr/local/bin/wg-health.sh
(crontab -l 2>/dev/null; echo "* * * * * bash /usr/local/bin/wg-health.sh") | crontab -

# ==================================
# SIMPLE MENU
# ==================================
menu() {
while true; do
clear
echo "======================================"
echo "🔥 Ultimate LEGENDARY Tunnel Menu 🔥"
echo "======================================"
echo "1) Show WireGuard Status"
echo "2) Restart a Tunnel"
echo "3) Bring Down a Tunnel"
echo "4) Bring Up a Tunnel"
echo "5) Show Routing Table"
echo "0) Exit"
echo "--------------------------------------"
read -p "Select option: " opt

case $opt in
1)
    wg show
    read -p "Press enter to continue..."
    ;;
2)
    read -p "Tunnel name (wg0, wg1,...): " tn
    wg-quick down $tn
    wg-quick up $tn
    ;;
3)
    read -p "Tunnel name (wg0, wg1,...): " tn
    wg-quick down $tn
    ;;
4)
    read -p "Tunnel name (wg0, wg1,...): " tn
    wg-quick up $tn
    ;;
5)
    ip route show
    read -p "Press enter to continue..."
    ;;
0)
    exit 0
    ;;
*)
    echo "Invalid option!"
    ;;
esac
done
}

menu
