# Device Management Guide

Comprehensive guide for managing iOS simulators, Android emulators, and
physical devices for mopro development.

## iOS Simulators

### Listing Simulators

```bash
# List all available simulators
xcrun simctl list devices available

# List only booted simulators
xcrun simctl list devices booted

# JSON output for scripting
xcrun simctl list devices available -j
```

### Creating Simulators

Simulators are managed through Xcode:
1. Xcode > Window > Devices and Simulators
2. Click "+" to add a new simulator
3. Choose device type and iOS version

Or via command line:
```bash
# List available device types
xcrun simctl list devicetypes

# List available runtimes
xcrun simctl list runtimes

# Create a simulator
xcrun simctl create "My iPhone" "iPhone 16" "iOS-18-0"
```

### Booting and Shutting Down

```bash
# Boot a simulator by name
xcrun simctl boot "iPhone 16"

# Boot by UDID
xcrun simctl boot <UDID>

# Open Simulator.app (boots default if none running)
open -a Simulator

# Shutdown a specific simulator
xcrun simctl shutdown "iPhone 16"

# Shutdown all simulators
xcrun simctl shutdown all
```

### Installing and Running Apps

```bash
# Install an app on a booted simulator
xcrun simctl install booted /path/to/MyApp.app

# Launch the app
xcrun simctl launch booted com.example.myapp

# Uninstall
xcrun simctl uninstall booted com.example.myapp
```

### Simulator Troubleshooting

**Simulator won't boot:**
```bash
xcrun simctl shutdown all
# If still stuck, erase (WARNING: deletes all simulator data)
xcrun simctl erase all
```

**"Unable to boot device in current state: Booted":**
The simulator is already running. Use it directly or shut it down first.

**Missing simulator runtimes:**
Download in Xcode > Settings > Platforms > iOS > "+" button.

**Performance tips:**
- Use the latest simulator runtime
- Close other resource-heavy apps
- Apple Silicon Macs run simulators much faster than Intel

## Android Emulators

### Listing Emulators

```bash
# List available AVDs (Android Virtual Devices)
$ANDROID_HOME/emulator/emulator -list-avds

# Or using avdmanager
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager list avd
```

### Creating Emulators

Best done through Android Studio:
1. Tools > Device Manager
2. Click "Create Device"
3. Choose hardware profile (e.g., Pixel 6)
4. Select system image:
   - **x86_64** for Intel/AMD hosts (fastest)
   - **arm64-v8a** for Apple Silicon (with Hypervisor)
5. Configure: RAM (4GB+), internal storage (8GB+)

Or via command line:
```bash
# List available system images
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list | grep system-images

# Download a system image
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-34;google_apis;x86_64"

# Create AVD
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
    --name "Pixel_6_API_34" \
    --device "pixel_6" \
    --package "system-images;android-34;google_apis;x86_64"
```

### Starting and Stopping

```bash
# Start emulator (foreground)
$ANDROID_HOME/emulator/emulator -avd Pixel_6_API_34

# Start in background
$ANDROID_HOME/emulator/emulator -avd Pixel_6_API_34 &

# Start with specific options
$ANDROID_HOME/emulator/emulator -avd Pixel_6_API_34 \
    -no-snapshot-load \
    -gpu host \
    -memory 4096

# Kill running emulator
adb -s emulator-5554 emu kill
```

### Installing and Running Apps

```bash
# Install APK on running emulator
adb install app/build/outputs/apk/debug/app-debug.apk

# Install with replacement
adb install -r app-debug.apk

# Launch activity
adb shell am start -n com.example.myapp/.MainActivity

# Uninstall
adb uninstall com.example.myapp
```

### Emulator Troubleshooting

**"emulator: command not found":**
```bash
export PATH="$PATH:$ANDROID_HOME/emulator"
```

**Slow emulator:**
- Enable hardware acceleration:
  - Intel: Install HAXM via SDK Manager
  - Apple Silicon: Hypervisor is automatic
- Use x86_64 system images
- Allocate more RAM in AVD settings
- Enable GPU acceleration: `-gpu host`

**"PANIC: Cannot find AVD system path":**
System image not installed. Install via SDK Manager:
```bash
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-34;google_apis;x86_64"
```

**Emulator crashes on start:**
- Delete and recreate the AVD
- Try cold boot: `-no-snapshot-load`
- Check available disk space

## Physical Devices

### iOS Physical Devices

**Setup:**
1. Connect device via USB (or configure wireless debugging)
2. Trust the computer on the device
3. In Xcode: Window > Devices and Simulators > verify device appears
4. Configure signing in project settings

**Wireless debugging (Xcode 13+):**
1. Connect via USB first
2. Window > Devices and Simulators
3. Check "Connect via network" for the device
4. Disconnect USB — device stays available over WiFi

**Running on device:**
```bash
# Select device in Xcode scheme dropdown, then Cmd+R
# Or from command line:
xcodebuild -project MyApp.xcodeproj \
    -scheme MyApp \
    -destination 'id=<DEVICE_UDID>' \
    build
```

### Android Physical Devices

**Setup:**
1. On the device: Settings > About Phone > tap "Build Number" 7 times
2. Settings > Developer Options > enable "USB Debugging"
3. Connect via USB
4. Accept the debugging prompt on the device

**Verify connection:**
```bash
adb devices
# Should show device serial and "device" status
```

**Running on device:**
```bash
# Install debug APK
adb install app/build/outputs/apk/debug/app-debug.apk

# Or use Gradle
./gradlew installDebug

# With Flutter
flutter run -d <device_id>
```

**Wireless ADB (Android 11+):**
```bash
# Enable wireless debugging on device
# Settings > Developer Options > Wireless Debugging

# Pair (one time)
adb pair <device_ip>:<pair_port>

# Connect
adb connect <device_ip>:<port>
```

## Architecture Matching

When running on a device, the built architecture must match:

| Device | Required Architecture |
|---|---|
| iPhone (any) | `aarch64-apple-ios` |
| iOS Simulator (Apple Silicon) | `aarch64-apple-ios-sim` |
| iOS Simulator (Intel) | `x86_64-apple-ios` |
| Android phone (modern) | `aarch64-linux-android` |
| Android emulator (x86_64) | `x86_64-linux-android` |
| Android emulator (x86) | `i686-linux-android` |
| Android phone (older 32-bit) | `armv7-linux-androideabi` |

If the architecture doesn't match, you'll get:
- iOS: Build error or "could not find module"
- Android: `UnsatisfiedLinkError` crash at runtime

Rebuild with the correct architecture:
```bash
mopro build --platforms <platform> --architectures <correct_arch>
```
