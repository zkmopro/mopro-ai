#!/usr/bin/env bash
# Unified environment check for mopro development
# Outputs JSON array of tool statuses for machine parsing
#
# Usage: bash check-env.sh [platform]
# Platforms: ios, android, flutter, react-native, web, all (default: all)

set -euo pipefail

PLATFORM="${1:-all}"

# JSON output accumulator
RESULTS="["
FIRST=true

add_result() {
    local tool="$1"
    local installed="$2"
    local version="$3"
    local required="$4"
    local platform="$5"

    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        RESULTS+=","
    fi

    RESULTS+=$(cat <<EOF
{"tool":"${tool}","installed":${installed},"version":${version},"required":${required},"platform":"${platform}"}
EOF
)
}

check_tool() {
    local tool="$1"
    local cmd="$2"
    local required="$3"
    local platform="$4"
    local version_cmd="${5:-}"

    if command -v "$cmd" &>/dev/null; then
        local ver="null"
        if [ -n "$version_cmd" ]; then
            ver="\"$(eval "$version_cmd" 2>&1 | head -1 | sed 's/[^0-9.]//g; s/^\.//; s/\.$//' || echo "unknown")\""
            # Clean up empty version strings
            if [ "$ver" = '""' ] || [ "$ver" = '"."' ]; then
                ver="null"
            fi
        fi
        add_result "$tool" "true" "$ver" "$required" "$platform"
    else
        add_result "$tool" "false" "null" "$required" "$platform"
    fi
}

# ---- Core tools (always checked) ----
check_tool "rust" "rustc" "true" "all" "rustc --version | awk '{print \$2}'"
check_tool "cargo" "cargo" "true" "all" "cargo --version | awk '{print \$2}'"
check_tool "cmake" "cmake" "true" "all" "cmake --version | head -1 | awk '{print \$3}'"
check_tool "mopro-cli" "mopro" "true" "all" "mopro --version 2>&1 | awk '{print \$2}'"

# ---- iOS tools ----
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "flutter" ]; then
    if command -v xcodebuild &>/dev/null; then
        XCODE_VER="\"$(xcodebuild -version 2>&1 | head -1 | awk '{print $2}')\""
        add_result "xcode" "true" "$XCODE_VER" "false" "ios"
    else
        add_result "xcode" "false" "null" "false" "ios"
    fi

    if command -v xcode-select &>/dev/null && xcode-select -p &>/dev/null; then
        CLI_PATH="$(xcode-select -p 2>&1)"
        add_result "xcode-cli" "true" "\"configured\"" "false" "ios"
    else
        add_result "xcode-cli" "false" "null" "false" "ios"
    fi

    check_tool "xcrun" "xcrun" "false" "ios"
fi

# ---- Android tools ----
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "flutter" ]; then
    # Java/JDK
    if command -v java &>/dev/null; then
        JAVA_VER="\"$(java -version 2>&1 | head -1 | sed 's/.*"\(.*\)".*/\1/')\""
        add_result "jdk" "true" "$JAVA_VER" "false" "android"
    else
        add_result "jdk" "false" "null" "false" "android"
    fi

    # Android SDK
    if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
        add_result "android-sdk" "true" "\"$ANDROID_HOME\"" "false" "android"
    elif [ -d "$HOME/Library/Android/sdk" ]; then
        add_result "android-sdk" "true" "\"$HOME/Library/Android/sdk\"" "false" "android"
    else
        add_result "android-sdk" "false" "null" "false" "android"
    fi

    # Android NDK
    NDK_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}/ndk"
    if [ -d "$NDK_HOME" ] && [ "$(ls -A "$NDK_HOME" 2>/dev/null)" ]; then
        NDK_VER="\"$(ls "$NDK_HOME" | sort -V | tail -1)\""
        add_result "android-ndk" "true" "$NDK_VER" "false" "android"
    else
        add_result "android-ndk" "false" "null" "false" "android"
    fi

    check_tool "adb" "adb" "false" "android" "adb --version | head -1 | awk '{print \$5}'"
fi

# ---- Flutter tools ----
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "flutter" ]; then
    check_tool "flutter" "flutter" "false" "flutter" "flutter --version 2>&1 | head -1 | awk '{print \$2}'"
    check_tool "dart" "dart" "false" "flutter" "dart --version 2>&1 | awk '{print \$4}'"
fi

# ---- React Native tools ----
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "react-native" ]; then
    check_tool "node" "node" "false" "react-native" "node --version | sed 's/v//'"
    check_tool "npm" "npm" "false" "react-native" "npm --version"
    check_tool "npx" "npx" "false" "react-native"
fi

# ---- Web/WASM tools ----
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "web" ]; then
    check_tool "wasm-pack" "wasm-pack" "false" "web" "wasm-pack --version | awk '{print \$2}'"
fi

# ---- Circuit compilers (optional) ----
check_tool "circom" "circom" "false" "all" "circom --version 2>&1 | awk '{print \$NF}'"
check_tool "nargo" "nargo" "false" "all" "nargo --version 2>&1 | awk '{print \$NF}'"

# Close JSON array
RESULTS+="]"

echo "$RESULTS"
