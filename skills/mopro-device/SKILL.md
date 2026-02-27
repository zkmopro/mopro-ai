---
name: mopro-device
description: >-
  Manage iOS simulators, Android emulators, and physical devices for testing
  mopro apps. Use whenever someone wants to list, start, or run on a simulator
  or emulator, deploy to a phone, or troubleshoot device issues. Also use when
  a user says "run my app" or "test on device" even if they don't mention
  simulators explicitly.
license: MIT OR Apache-2.0
metadata:
  author: zkmopro
  version: "0.3.1"
---

# Mopro Device Management

This skill helps users manage simulators, emulators, and physical devices
for testing mopro apps.

## When to Use

- User wants to run their app on a simulator/emulator
- User needs to list available devices
- User asks about deploying to a physical device
- User encounters simulator/emulator issues

## Related Skills

- **mopro-app**: For building the app to deploy
- **mopro-test**: For running tests on devices

## Actions

### List Devices

Show all available simulators, emulators, and connected physical devices.

Run the unified device listing script:
```bash
bash scripts/list-devices.sh
```

> Run from the skill directory. The script outputs a JSON array to parse and present.

Or check platforms individually:
```bash
# iOS simulators
xcrun simctl list devices available

# Android emulators
$ANDROID_HOME/emulator/emulator -list-avds

# Connected physical devices (Android)
adb devices

# Flutter devices
flutter devices
```

### Start Simulator/Emulator

**Before starting, confirm with the user:**
```
About to boot <device_name>. This may take a moment. Proceed?
```

**iOS Simulator:**
```bash
# List available simulators
xcrun simctl list devices available

# Boot a specific simulator (non-blocking)
xcrun simctl boot "iPhone 16"
```

After booting, verify the simulator is ready:
```bash
xcrun simctl list devices booted
```

Do NOT use `open -a Simulator` — it blocks the agent indefinitely.
Use `xcrun simctl boot` instead, which returns immediately.

**Android Emulator:**
```bash
# List available AVDs
$ANDROID_HOME/emulator/emulator -list-avds
```

Start the emulator using `run_in_background=true` (do NOT use shell `&`):
```bash
$ANDROID_HOME/emulator/emulator -avd <avd_name>
```

After starting, verify the emulator is ready:
```bash
adb wait-for-device
adb shell getprop sys.boot_completed
# Returns "1" when fully booted
```

If no AVD exists, guide the user to create one in Android Studio:
Tools > Device Manager > Create Device.

### Run App on Device

**iOS (Xcode):**
```bash
# Build and run on simulator
xcodebuild -project MyApp.xcodeproj \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    build

# Or open in Xcode and press Cmd+R
open MyApp.xcodeproj
```

**Android (Gradle):**
```bash
# Install and run on connected device/emulator
./gradlew installDebug
adb shell am start -n com.example.myapp/.MainActivity
```

**Flutter:**
```bash
flutter run                     # Auto-selects device
flutter run -d <device_id>      # Specific device
flutter run -d chrome            # Web
```

**React Native:**
```bash
npm run ios          # iOS simulator
npm run android      # Android emulator
```

### Deploy to Physical Device

**iOS Physical Device:**
1. Connect device via USB or WiFi
2. Open project in Xcode
3. Select the device from the device dropdown
4. Configure signing: Signing & Capabilities > Team
5. Build and run (Cmd+R)

**Android Physical Device:**
1. Enable Developer Options on the device
2. Enable USB Debugging
3. Connect via USB
4. Verify connection: `adb devices`
5. Install: `./gradlew installDebug` or `flutter run`

## Troubleshooting

### "No devices found"
- iOS: Check Xcode is installed, simulators are downloaded
- Android: Verify `ANDROID_HOME` is set, emulator images are installed
- Physical: Check USB connection, USB debugging enabled

### "Unable to boot simulator"
```bash
# Reset a stuck simulator
xcrun simctl shutdown all
xcrun simctl erase all  # WARNING: erases all simulator data
```

### "emulator: command not found"
Add Android emulator to PATH:
```bash
export PATH="$PATH:$ANDROID_HOME/emulator"
```

### "adb: command not found"
Add platform-tools to PATH:
```bash
export PATH="$PATH:$ANDROID_HOME/platform-tools"
```

### Slow emulator
- Enable hardware acceleration (HAXM on Intel, Hypervisor on ARM)
- Use x86_64 system images for Android emulator
- Allocate more RAM to the emulator in AVD settings

### iOS app crashes on device but works on simulator
- Check architecture: device needs `aarch64-apple-ios`, simulator needs
  `aarch64-apple-ios-sim`
- Check signing configuration
- Check that circuit assets are in the app bundle
