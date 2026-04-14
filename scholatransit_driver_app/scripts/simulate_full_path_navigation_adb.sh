#!/usr/bin/env bash
# Full-Path Live Navigation — ADB geo fix along Nairobi Archives → Upper Hill corridor.
# Matches the "Active Trip" test: static polyline on map + vehicle follows with ~3s "REST" cadence.
#
# Route: Kenyatta Ave → Uhuru Highway → Ngong Rd (densified to 15–20 points).
# Edge case: DROP_INDEX=7 skips one injection (dropped packet) to exercise dead reckoning.
#
# Prerequisites: active trip on Map screen, emulator, adb (see simulate_nairobi_trip_adb.sh).
# Usage:
#   ./scripts/simulate_full_path_navigation_adb.sh -s emulator-5554
#   DROP_INDEX=6 ./scripts/simulate_full_path_navigation_adb.sh -s emulator-5554
#
# Map implementation notes (map_screen.dart):
# - Vehicle: GeoJsonSource id "vehicle-puck-source" + SymbolLayer/CircleLayer ids *_vehicle*LayerId.
# - Route line: PolylineAnnotationManager (not the same source); avoids touching route on puck update.
# - Motion ticker updates puck via style API; Flutter setState throttled (~250ms), not every 16ms.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADB="${ADB:-}"
INTERVAL_SEC="${INTERVAL_SEC:-3}"
DROP_INDEX="${DROP_INDEX:-}" # 0-based; empty = no skip

usage() {
  echo "Usage: $0 [-s SERIAL]" >&2
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

emit_route() {
  DROP_INDEX="${DROP_INDEX:-}" python3 <<'PY'
import os
import sys

# (longitude, latitude) — prompt order preserved
KEY = [
    (36.8248, -1.2843),
    (36.8238, -1.2844),
    (36.8225, -1.2846),
    (36.8210, -1.2849),
    (36.8205, -1.2860),
    (36.8198, -1.2875),
    (36.8190, -1.2890),
    (36.8180, -1.2915),
    (36.8170, -1.2940),
    (36.8130, -1.2955),
    (36.8080, -1.2975),
    (36.8025, -1.2988),
]


def densify_to_range(coords, target=18):
    """Insert midpoints between vertices, then resample to ~target positions."""
    if len(coords) < 2:
        return coords
    dense = []
    for i in range(len(coords) - 1):
        lng1, lat1 = coords[i]
        lng2, lat2 = coords[i + 1]
        dense.append((lng1, lat1))
        dense.append(((lng1 + lng2) / 2.0, (lat1 + lat2) / 2.0))
    dense.append(coords[-1])
    if len(dense) <= target:
        return dense
    n = len(dense)
    out = []
    for j in range(target):
        idx = min(n - 1, round(j * (n - 1) / (target - 1)))
        out.append(dense[idx])
    # de-dupe consecutive
    fixed = [out[0]]
    for p in out[1:]:
        if abs(p[0] - fixed[-1][0]) > 1e-7 or abs(p[1] - fixed[-1][1]) > 1e-7:
            fixed.append(p)
    return fixed if len(fixed) >= 15 else out


drop_raw = os.environ.get("DROP_INDEX", "").strip()
drop_at = int(drop_raw) if drop_raw.isdigit() else None

route = densify_to_range(KEY, 18)
print(f"({len(route)} points, DROP_INDEX={drop_at})", file=sys.stderr, flush=True)
for i, (lng, lat) in enumerate(route):
    skip = drop_at is not None and i == drop_at
    print(f"{lng:.7f} {lat:.7f} {'SKIP' if skip else 'FIX'}", flush=True)
PY
}

if ! "$ADB" version >/dev/null 2>&1; then
  echo "Could not run adb: $ADB" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 required" >&2
  exit 1
fi
if ! run_adb get-state 1>/dev/null 2>&1; then
  echo "No adb device. Start an emulator." >&2
  exit 1
fi

if [ "${#SERIAL_ARGS[@]}" -eq 0 ]; then
  echo "Using: $ADB"
else
  echo "Using: $ADB ${SERIAL_ARGS[*]}"
fi
echo "Interval: ${INTERVAL_SEC}s | DROP_INDEX=${DROP_INDEX:-none} (dropped-packet test)"
echo ""

idx=0
while read -r lon lat action; do
  [[ "$lon" =~ ^# ]] && continue
  [ -z "${lon:-}" ] && continue
  if [ "$action" = "SKIP" ]; then
    echo "$(date "+%Y-%m-%dT%H:%M:%S")  SKIP index=$idx (simulated dropped REST packet)"
  else
    run_adb emu geo fix "$lon" "$lat"
    echo "$(date "+%Y-%m-%dT%H:%M:%S")  geo fix idx=$idx lon=$lon lat=$lat"
  fi
  idx=$((idx + 1))
  sleep "$INTERVAL_SEC"
done < <(emit_route)

echo "Full-path navigation simulation complete."
