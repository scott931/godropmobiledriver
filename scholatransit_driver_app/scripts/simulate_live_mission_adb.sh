#!/usr/bin/env bash
# Live Mission: road-following ADB simulation (Nairobi Archives → Upper Hill / KNH area).
# Requires an active trip on the Map screen (start a trip or run with --dart-define=TEST_ACTIVE_TRIP=true).
# - Route from OSRM (Kenyatta Ave → Uhuru Hwy → Ngong Rd corridor on real geometry).
# - Variable speed: ~40–60 km/h straights, ~15 km/h in high-curvature segments.
# - Fix interval: random 2–3 s; occasional 1.5× delay on one step (dead-reckoning stress).
#
# Flutter: enable packet logs with:
#   flutter run --dart-define=DEBUG_VEHICLE_LOCATION_PACKETS=true
#
# Usage:
#   ./scripts/simulate_live_mission_adb.sh
#   ./scripts/simulate_live_mission_adb.sh -s emulator-5554
#   SEED=42 ./scripts/simulate_live_mission_adb.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADB="${ADB:-}"
SEED="${SEED:-}"
JITTER_PROB="${JITTER_PROB:-0.14}"

usage() {
  echo "Usage: $0 [-s SERIAL]" >&2
  echo "  -s SERIAL   adb device serial (e.g. emulator-5554)" >&2
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

if [ "${#SERIAL_ARGS[@]}" -eq 0 ] && [ -n "${ANDROID_SERIAL:-}" ]; then
  SERIAL_ARGS=(-s "$ANDROID_SERIAL")
fi

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

emit_driver_steps() {
  SEED="$SEED" JITTER_PROB="$JITTER_PROB" python3 <<'PY'
import json
import math
import os
import random
import urllib.request

R = 6371000.0
# Start: National Archives, End: Upper Hill / KNH area (lat, lon)
START_LAT, START_LON = -1.2843, 36.8248
END_LAT, END_LON = -1.2988, 36.8025
OSRM_URL = (
    f"https://router.project-osrm.org/route/v1/driving/"
    f"{START_LON},{START_LAT};{END_LON},{END_LAT}"
    f"?overview=full&geometries=geojson"
)

FALLBACK = [
    (START_LAT, START_LON),
    (-1.2860, 36.8180),
    (-1.2920, 36.8100),
    (END_LAT, END_LON),
]


def haversine_m(lat1, lon1, lat2, lon2):
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * R * math.asin(min(1.0, math.sqrt(a)))


def bearing_deg(lat1, lon1, lat2, lon2):
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlmb = math.radians(lon2 - lon1)
    y = math.sin(dlmb) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dlmb)
    return (math.degrees(math.atan2(y, x)) + 360.0) % 360.0


def ang_diff_deg(a, b):
    d = (a - b + 180.0) % 360.0 - 180.0
    return abs(d)


def fetch_coords():
    try:
        req = urllib.request.Request(OSRM_URL, headers={"User-Agent": "ScholaTransitLiveMission/1.0"})
        with urllib.request.urlopen(req, timeout=45) as resp:
            data = json.load(resp)
        routes = data.get("routes") or []
        if not routes:
            return None
        geom = routes[0].get("geometry") or {}
        coords = geom.get("coordinates")
        if not coords or len(coords) < 2:
            return None
        # GeoJSON: [lon, lat]
        return [(c[1], c[0]) for c in coords]
    except Exception:
        return None


def polyline_length_m(coords):
    total = 0.0
    for i in range(len(coords) - 1):
        la, lo = coords[i]
        lb, lo2 = coords[i + 1]
        total += haversine_m(la, lo, lb, lo2)
    return total


def point_at_distance_m(coords, target_m):
    if target_m <= 0:
        c = coords[0]
        return c[0], c[1], bearing_deg(c[0], c[1], coords[1][0], coords[1][1])
    acc = 0.0
    for i in range(len(coords) - 1):
        la, lo = coords[i]
        lb, lo2 = coords[i + 1]
        seg = haversine_m(la, lo, lb, lo2)
        if acc + seg >= target_m:
            frac = (target_m - acc) / seg if seg > 1e-6 else 0.0
            frac = max(0.0, min(1.0, frac))
            lat = la + (lb - la) * frac
            lon = lo + (lo2 - lo) * frac
            return lat, lon, bearing_deg(la, lo, lb, lo2)
        acc += seg
    la, lo = coords[-1]
    lb, lo2 = coords[-2]
    return la, lo, bearing_deg(lb, lo2, la, lo)


def max_turn_ahead_deg(coords, dist_m, total_len, lookahead_m=55.0, step_m=12.0):
    bearings = []
    d = dist_m
    lim = max(total_len - 0.01, 0.0)
    while d < dist_m + lookahead_m:
        lat, lon, brg = point_at_distance_m(coords, min(d, lim))
        bearings.append(brg)
        d += step_m
    if len(bearings) < 2:
        return 0.0
    return max(ang_diff_deg(bearings[i], bearings[i + 1]) for i in range(len(bearings) - 1))


def walk_route(coords):
    seed = os.environ.get("SEED", "").strip()
    if seed:
        random.seed(int(seed))
    jitter_prob = float(os.environ.get("JITTER_PROB", "0.14"))
    total_len = polyline_length_m(coords)
    if total_len < 10:
        return

    la0, lo0, _ = point_at_distance_m(coords, 0.0)
    print(f"{lo0:.7f} {la0:.7f} 2.50 start")

    pos_m = 0.0
    max_steps = 800
    jitter_armed = random.random() < 0.85

    for _ in range(max_steps):
        if pos_m >= total_len - 0.5:
            break

        turn = max_turn_ahead_deg(coords, pos_m, total_len)
        if turn >= 22.0:
            kmh = 15.0
            mode = "turn"
        else:
            kmh = random.uniform(40.0, 60.0)
            mode = "straight"

        interval = random.uniform(2.0, 3.0)
        if jitter_armed and random.random() < jitter_prob:
            interval *= 1.5
            jitter_armed = False
            mode = f"{mode}+jitter"

        speed_mps = kmh / 3.6
        step_m = speed_mps * interval
        pos_m = min(pos_m + step_m, total_len)

        lat, lon, _ = point_at_distance_m(coords, pos_m)
        print(f"{lon:.7f} {lat:.7f} {interval:.2f} {mode}")

    la, lo = coords[-1][0], coords[-1][1]
    print(f"{lo:.7f} {la:.7f} 2.80 end")


def main():
    coords = fetch_coords()
    if coords is None:
        coords = []
        for i in range(len(FALLBACK) - 1):
            a, b = FALLBACK[i], FALLBACK[i + 1]
            n = 12
            for k in range(n):
                t = k / max(n - 1, 1)
                lat = a[0] + (b[0] - a[0]) * t
                lon = a[1] + (b[1] - a[1]) * t
                if not coords or abs(coords[-1][0] - lat) > 1e-8 or abs(coords[-1][1] - lon) > 1e-8:
                    coords.append((lat, lon))
        if len(coords) < 2:
            coords = list(FALLBACK)
    walk_route(coords)


main()
PY
}

if ! "$ADB" version >/dev/null 2>&1; then
  echo "Could not run adb: $ADB" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required." >&2
  exit 1
fi

if ! run_adb get-state 1>/dev/null 2>&1; then
  echo "No adb device ready. Start an emulator: $ADB devices" >&2
  exit 1
fi

if [ "${#SERIAL_ARGS[@]}" -eq 0 ]; then
  echo "Using: $ADB"
else
  echo "Using: $ADB ${SERIAL_ARGS[*]}"
fi
echo "Live Mission: Archives → Upper Hill (OSRM). SEED=${SEED:-random} JITTER_PROB=$JITTER_PROB"
echo "Enable Flutter logs: flutter run --dart-define=DEBUG_VEHICLE_LOCATION_PACKETS=true"
echo ""

while read -r lon lat sleep_sec _meta; do
  [ -z "${lon:-}" ] && continue
  run_adb emu geo fix "$lon" "$lat"
  echo "$(date "+%Y-%m-%dT%H:%M:%S")  geo fix lon=$lon lat=$lat sleep=${sleep_sec}s ${_meta:-}"
  sleep "$sleep_sec"
done < <(emit_driver_steps)

echo "Live Mission complete."
