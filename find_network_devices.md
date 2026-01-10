# Finding Mobile Devices on Your Network

## Current Network Info
- Your local IP: 192.168.1.100
- Network range: 192.168.1.0/24

## Method 1: Enable Wireless Debugging on Android Device

1. **On your Android device:**
   - Go to Settings > About phone
   - Tap "Build number" 7 times to enable Developer options
   - Go to Settings > Developer options
   - Enable "USB debugging"
   - Enable "Wireless debugging" (Android 11+)
   - Tap "Wireless debugging" to see IP address and port

2. **Connect via ADB:**
   ```bash
   adb connect <DEVICE_IP>:<PORT>
   # Example: adb connect 192.168.1.50:5555
   ```

## Method 2: Connect via USB first, then switch to wireless

1. Connect device via USB
2. Run: `adb tcpip 5555`
3. Disconnect USB
4. Run: `adb connect <DEVICE_IP>:5555`

## Method 3: Use Flutter's device discovery

```bash
flutter devices --device-timeout 30
```

## Quick Commands

Check connected devices:
```bash
/Users/admin/Library/Android/sdk/platform-tools/adb devices
```

Scan for devices (requires wireless debugging enabled):
```bash
# Replace with your device's IP and port
adb connect 192.168.1.XXX:5555
```

List all Flutter devices:
```bash
cd scholatransit_driver_app
flutter devices
```
