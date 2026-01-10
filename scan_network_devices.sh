#!/bin/bash
# Script to scan for Android devices on the local network

ADB_PATH="/Users/admin/Library/Android/sdk/platform-tools/adb"
LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
NETWORK=$(echo $LOCAL_IP | cut -d'.' -f1-3)

echo "Scanning network $NETWORK.0/24 for Android devices..."
echo "Your local IP: $LOCAL_IP"
echo ""
echo "Checking common ADB ports (5555, 5556) on network devices..."
echo ""

# Check if devices are already connected via network
echo "Currently connected devices:"
$ADB_PATH devices
echo ""

# Try to connect to common ports on the network
echo "Scanning for devices with ADB over network enabled..."
for i in {1..254}; do
    IP="$NETWORK.$i"
    if [ "$IP" != "$LOCAL_IP" ]; then
        # Try port 5555 (default ADB port)
        timeout 0.5 bash -c "echo > /dev/tcp/$IP/5555" 2>/dev/null && echo "Found device at $IP:5555" && $ADB_PATH connect $IP:5555 2>/dev/null
        # Try port 5556 (alternative ADB port)
        timeout 0.5 bash -c "echo > /dev/tcp/$IP/5556" 2>/dev/null && echo "Found device at $IP:5556" && $ADB_PATH connect $IP:5556 2>/dev/null
    fi
done

echo ""
echo "Final device list:"
$ADB_PATH devices
