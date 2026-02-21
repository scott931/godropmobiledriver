#!/bin/bash
# Run the Flutter app with Mapbox token from local.properties.
# Add MAPBOX_ACCESS_TOKEN to android/local.properties, then run: ./scripts/run_with_mapbox.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ANDROID_DIR="$APP_DIR/android"
LOCAL_PROPS="$ANDROID_DIR/local.properties"
DEFINES_FILE="$APP_DIR/dart_defines.json"

# Read MAPBOX_ACCESS_TOKEN from local.properties
MAPBOX_TOKEN=""
if [ -f "$LOCAL_PROPS" ]; then
  MAPBOX_TOKEN=$(grep "MAPBOX_ACCESS_TOKEN" "$LOCAL_PROPS" 2>/dev/null | cut -d= -f2- | tr -d ' ')
fi

if [ -z "$MAPBOX_TOKEN" ]; then
  echo "⚠️  MAPBOX_ACCESS_TOKEN not found in $LOCAL_PROPS"
  echo "   Add: MAPBOX_ACCESS_TOKEN=pk.your_token_here"
  echo "   See: android/local.properties.example"
  exit 1
fi

# Generate dart_defines.json for Flutter
echo "{\"MAPBOX_ACCESS_TOKEN\": \"$MAPBOX_TOKEN\"}" > "$DEFINES_FILE"

# Add dart_defines.json to .gitignore if not already
GITIGNORE="$APP_DIR/.gitignore"
if [ -f "$GITIGNORE" ] && ! grep -q "dart_defines.json" "$GITIGNORE"; then
  echo "dart_defines.json" >> "$GITIGNORE"
fi

cd "$APP_DIR"
exec flutter run --dart-define-from-file="$DEFINES_FILE" "$@"
