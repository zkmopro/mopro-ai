#!/usr/bin/env bash
# Unified device listing for mopro development
# Lists iOS simulators, Android emulators, and connected physical devices
# Outputs JSON for machine parsing
#
# Usage: bash list-devices.sh [platform]
# Platforms: ios, android, flutter, all (default: all)

set -euo pipefail

PLATFORM="${1:-all}"

RESULTS="["
FIRST=true

add_device() {
    local name="$1"
    local type="$2"       # simulator, emulator, physical
    local platform="$3"   # ios, android
    local status="$4"     # booted, shutdown, available, connected
    local id="$5"

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        RESULTS+=","
    fi

    # Escape quotes in name
    name="${name//\"/\\\"}"

    RESULTS+=$(cat <<EOF
{"name":"${name}","type":"${type}","platform":"${platform}","status":"${status}","id":"${id}"}
EOF
)
}

# ---- iOS Simulators ----
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ]; then
    if command -v xcrun &>/dev/null; then
        # Parse simctl JSON output
        while IFS= read -r line; do
            name=$(echo "$line" | sed 's/^ *//;s/ *$//')
            if [ -n "$name" ]; then
                # Extract device info from simctl list
                id="unknown"
                status="available"
                add_device "$name" "simulator" "ios" "$status" "$id"
            fi
        done < <(xcrun simctl list devices available -j 2>/dev/null | \
            python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for runtime, devices in data.get('devices', {}).items():
        for d in devices:
            if d.get('isAvailable', False):
                state = 'booted' if d.get('state') == 'Booted' else 'shutdown'
                print(f\"{d['name']}|{state}|{d['udid']}\")
except: pass
" 2>/dev/null || true)

        # Re-parse with proper field extraction
        RESULTS="["
        FIRST=true

        while IFS='|' read -r name status udid; do
            if [ -n "$name" ]; then
                add_device "$name" "simulator" "ios" "$status" "$udid"
            fi
        done < <(xcrun simctl list devices available -j 2>/dev/null | \
            python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for runtime, devices in data.get('devices', {}).items():
        for d in devices:
            if d.get('isAvailable', False):
                state = 'booted' if d.get('state') == 'Booted' else 'shutdown'
                print(f\"{d['name']}|{state}|{d['udid']}\")
except: pass
" 2>/dev/null || true)
    fi
fi

# ---- Android Emulators ----
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ]; then
    EMULATOR_CMD="${ANDROID_HOME:-$HOME/Library/Android/sdk}/emulator/emulator"
    if [ -x "$EMULATOR_CMD" ]; then
        while IFS= read -r avd; do
            if [ -n "$avd" ]; then
                add_device "$avd" "emulator" "android" "available" "$avd"
            fi
        done < <("$EMULATOR_CMD" -list-avds 2>/dev/null || true)
    fi

    # Connected Android devices (physical + running emulators)
    if command -v adb &>/dev/null; then
        while IFS= read -r line; do
            id=$(echo "$line" | awk '{print $1}')
            status=$(echo "$line" | awk '{print $2}')
            if [ -n "$id" ] && [ "$status" = "device" ]; then
                # Determine if emulator or physical
                if echo "$id" | grep -q "emulator"; then
                    add_device "$id" "emulator" "android" "booted" "$id"
                else
                    # Get device model name
                    model=$(adb -s "$id" shell getprop ro.product.model 2>/dev/null || echo "$id")
                    add_device "$model" "physical" "android" "connected" "$id"
                fi
            fi
        done < <(adb devices 2>/dev/null | tail -n +2 | grep -v "^$" || true)
    fi
fi

# ---- Flutter Devices ----
if [ "$PLATFORM" = "flutter" ]; then
    if command -v flutter &>/dev/null; then
        # Flutter's own device listing
        flutter devices --machine 2>/dev/null | \
            python3 -c "
import json, sys
try:
    devices = json.load(sys.stdin)
    for d in devices:
        name = d.get('name', 'Unknown')
        platform = d.get('targetPlatform', 'unknown')
        dev_id = d.get('id', 'unknown')
        print(f\"{name}|{platform}|{dev_id}\")
except: pass
" 2>/dev/null | while IFS='|' read -r name platform dev_id; do
            if [ -n "$name" ]; then
                add_device "$name" "device" "$platform" "available" "$dev_id"
            fi
        done || true
    fi
fi

# Close JSON array
RESULTS+="]"

echo "$RESULTS"
