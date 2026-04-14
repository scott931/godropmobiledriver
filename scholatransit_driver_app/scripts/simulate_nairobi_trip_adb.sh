#!/usr/bin/env bash
# Simulate a vehicle trip on the Android emulator with adb emu geo fix.
# Route: Nairobi National Archives → Kenyatta Ave → Haile Selassie / Uhuru Highway corridor.
# Each step is ~50 m (~60 km/h over 3 s); fixes are sent every 3 s to match typical REST polling.
#
# Prerequisites: Android emulator running, adb (PATH or SDK), python3.
# The map listens for GPS only while a trip is active — start a trip or use TEST_ACTIVE_TRIP=true.
# Usage:
#   ./scripts/simulate_nairobi_trip_adb.sh
#   ./scripts/simulate_nairobi_trip_adb.sh -s emulator-5554
#   QUICK=1 ./scripts/simulate_nairobi_trip_adb.sh   # only 3 manual checkpoints
#
# What to watch in the app (map_screen.dart):
#   - Puck should glide between pings (not teleport then sit still).
#   - Bearing should ease through the Kenyatta / roundabout approach (no instant 90° snap).
#   - Stop the script: dead reckoning should coast briefly then stop.
#   - Camera follow should stay smooth (no jitter).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STEP_METERS="${STEP_METERS:-50}"
INTERVAL_SEC="${INTERVAL_SEC:-3}"
ADB="${ADB:-}"

usage() {
  echo "Usage: $0 [-s SERIAL]" >&2
  echo "  -s SERIAL   adb device serial (e.g. emulator-5554). Default: \$ANDROID_SERIAL or first device." >&2
  echo "  QUICK=1     send only three fixes (Archives → Kenyatta → junction)." >&2
  exit 1
}

SERIAL_ARGS=()
while getopts "s:h" opt; do
  case "$opt" in
    s) SERIAL_ARGS=(-s "$OPTARG") ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [ ${#SERIAL_ARGS[@]} -eq 0 ] && [ -n "${ANDROID_SERIAL:-}" ]; then
  SERIAL_ARGS=(-s "$ANDROID_SERIAL")
fi

# Resolve adb when platform-tools are not on PATH (common with Android Studio / Flutter).
resolve_adb() {
  if [ -n "$ADB" ] && [ -x "$ADB" ]; then
    return 0
  fi
  if command -v adb >/dev/null 2>&1; then
    ADB="$(command -v adb)"
    return 0
  fi
  local root
  for root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}"; do
    [ -z "$root" ] && continue
    if [ -x "$root/platform-tools/adb" ]; then
      ADB="$root/platform-tools/adb"
      return 0
    fi
  done
  local props="$SCRIPT_DIR/../android/local.properties"
  if [ -f "$props" ]; then
    local sdk
    sdk=$(grep '^sdk.dir=' "$props" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$sdk" ] && [ -x "$sdk/platform-tools/adb" ]; then
      ADB="$sdk/platform-tools/adb"
      return 0
    fi
  fi
  ADB="adb"
}
resolve_adb

run_adb() {
  if [ "${#SERIAL_ARGS[@]}" -eq 0 ]; then
    "$ADB" "$@"
  else
    "$ADB" "${SERIAL_ARGS[@]}" "$@"
  fi
}

emit_waypoints() {
  STEP_METERS="$STEP_METERS" QUICK="${QUICK:-0}" python3 <<'PY'
import math
import os

R = 6371000.0
STEP = float(os.environ["STEP_METERS"])
QUICK = os.environ.get("QUICK", "0") == "1"

POLY_FULL = [
    (-1.2843, 36.8248),
    (-1.2845, 36.8230),
    (-1.2848, 36.8210),
    (-1.2855, 36.8192),
    (-1.2862, 36.8175),
]

POLY_QUICK = POLY_FULL[:3]


def haversine_m(lat1, lon1, lat2, lon2):
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * R * math.asin(min(1.0, math.sqrt(a)))


def bearing_rad(lat1, lon1, lat2, lon2):
    p1 = math.radians(lat1)
    p2 = math.radians(lat2)
    dlmb = math.radians(lon2 - lon1)
    y = math.sin(dlmb) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dlmb)
    return math.atan2(y, x)


def destination(lat, lon, bearing, dist_m):
    d_r = dist_m / R
    lat1 = math.radians(lat)
    lon1 = math.radians(lon)
    lat2 = math.asin(
        math.sin(lat1) * math.cos(d_r) + math.cos(lat1) * math.sin(d_r) * math.cos(bearing)
    )
    lon2 = lon1 + math.atan2(
        math.sin(bearing) * math.sin(d_r) * math.cos(lat1),
        math.cos(d_r) - math.sin(lat1) * math.sin(lat2),
    )
    return math.degrees(lat2), math.degrees(lon2)


def walk_polyline(poly):
    if len(poly) < 2:
        yield poly[0][1], poly[0][0]
        return
    cur_lat, cur_lon = poly[0]
    yield cur_lon, cur_lat
    for i in range(len(poly) - 1):
        end_lat, end_lon = poly[i + 1]
        while True:
            rem = haversine_m(cur_lat, cur_lon, end_lat, end_lon)
            if rem <= 0.5:
                cur_lat, cur_lon = end_lat, end_lon
                break
            leg = min(STEP, rem)
            brg = bearing_rad(cur_lat, cur_lon, end_lat, end_lon)
            cur_lat, cur_lon = destination(cur_lat, cur_lon, brg, leg)
            yield cur_lon, cur_lat


poly = POLY_QUICK if QUICK else POLY_FULL
for lon, lat in walk_polyline(poly):
    print(f"{lon:.7f} {lat:.7f}")
PY
}

if ! "$ADB" version >/dev/null 2>&1; then
  echo "Could not run adb: $ADB" >&2
  echo "Install Android SDK platform-tools, set ANDROID_HOME, or ensure sdk.dir in android/local.properties points at your SDK." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for 50 m geodesic steps." >&2
  exit 1
fi

if ! run_adb get-state 1>/dev/null 2>&1; then
  echo "No adb device ready. Start an emulator and try: $ADB devices" >&2
  exit 1
fi

if [ "${#SERIAL_ARGS[@]}" -eq 0 ]; then
  echo "Using: $ADB"
else
  echo "Using: $ADB ${SERIAL_ARGS[*]}"
fi
echo "Step: ${STEP_METERS} m every ${INTERVAL_SEC} s (~60 km/h). QUICK=${QUICK:-0}"
echo "Press Ctrl+C to stop (test dead reckoning after stopping)."
echo ""

while read -r lon lat; do
  run_adb emu geo fix "$lon" "$lat"
  echo "$(date "+%Y-%m-%dT%H:%M:%S")  geo fix  lon=$lon  lat=$lat"
  sleep "$INTERVAL_SEC"
done < <(emit_waypoints)

echo "Route complete."
