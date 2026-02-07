#!/bin/bash
# =============================================
# ULTIMATE LEGENDARY GOD MODE TUNNEL ENGINE
# Fully Interactive + Menu + Health Check
# Author: Erfan
# =============================================
set -e

echo "🔥 Ultimate LEGENDARY Tunnel Engine Setup 🔥"
echo ""

# ----------------------------
# CREATE CONFIG DIR
# ----------------------------
CONFIG_DIR="./config"
mkdir -p $CONFIG_DIR

MAIN_CONF="$CONFIG_DIR/main.conf"
TUNNELS_CONF="$CONFIG_DIR/tunnels.conf"

# ----------------------------
# 1️⃣ IRAN IP CONFIG
# ----------------------------
if [ ! -f "$MAIN_CONF" ]; then
    read -p "Enter your IRAN Public IP: " IRAN_PUBLIC_IP
    echo "IRAN_PUBLIC_IP=$IRAN_PUBLIC_IP" > $MAIN_CONF
else
    source $MAIN_CONF
fi

# Allow editing main.conf
read -p "Do you want to edit main.conf? (y/n): " edit_main
if [[ "$edit_main" == "y" ]]; then
    nano $MAIN_CONF
    source $MAIN_CONF
fi

# ----------------------------
# 2️⃣ TUNNEL CONFIG
# ----------------------------
> $TUNNELS_CONF
read -p "Enter number of foreign servers (tunnels): " TUNNELS

for ((i=0;i<$TUNNELS;i++)); do
    read -p "Enter FOREIGN IP for tunnel $i: " IP
    read -p "Enter PUBLIC KEY for tunnel $i: " PUB
    echo "WG${i}_IP=$IP" >> $TUNNELS_CONF
    echo "WG${i}_PUB=$PUB" >> $TUNNELS_CONF
done

# Allow editing tunnels.conf
read -p "Do you want to edit tunnels.conf? (y/n): " edit_tunnels
if [[ "$edit_tunnels" == "y" ]]; then
    nano $TUNNELS_CONF
fi

# Load tunnels
source $TUNNELS_CONF

# ----------------------------
# 3️⃣ INSTALL REQUIREMENTS
# ----------------------------
apt update
apt install -y wireguard iproute2 cron

# Enable BBR + fq_codel
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# ----------------------------
# 4️⃣ CREATE MULTI WIREGUARD TUNNELS
# ----------------------------
BASE_NET=("10.10.10" "10.20.20" "10.30.30" "10.40.40" "10.50.50") # Subnet base
for ((i=0;i<$TUNNELS;i++)); do
    WG="wg$i"
    NET=${BASE_NET[$i]}
    PORT=$((51820+i))
    eval FOREIGN=\$WG${i}_IP
    eval PUBKEY=\$WG${i}_PUB

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
PublicKey = $PUBKEY
Endpoint = $FOREIGN:$PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

    wg-quick up $WG
done

# ----------------------------
# 5️⃣ MULTIPATH ROUTING
# ----------------------------
echo "🔥 Setting multipath routing..."
CMD="ip route replace default scope global"
for ((i=0;i<$TUNNELS;i++)); do
    CMD="$CMD nexthop dev wg$i weight 1"
done
eval $CMD

# ----------------------------
# 6️⃣ POLICY ROUTING FOR XRAY
# ----------------------------
ip rule add fwmark 255 table 100 || true
CMD2="ip route replace default"
for ((i=0;i<$TUNNELS;i++)); do
    CMD2="$CMD2 nexthop dev wg$i weight 1"
done
CMD2="$CMD2 table 100"
eval $CMD2

# SSH safe
ip rule add from $IRAN_PUBLIC_IP table main || true

# ----------------------------
# 7️⃣ HEALTH CHECK SCRIPT
# ----------------------------
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

# ----------------------------
# 8️⃣ SIMPLE MENU
# ----------------------------
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
echo "6) Edit main.conf"
echo "7) Edit tunnels.conf"
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
6)
    nano $MAIN_CONF
    source $MAIN_CONF
    ;;
7)
    nano $TUNNELS_CONF
    source $TUNNELS_CONF
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
