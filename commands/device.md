---
description: List, start, and manage iOS simulators, Android emulators, and physical devices
argument-hint: "[action] [platform]"
allowed-tools: Bash, Read, Glob
---

# /mopro:device

Manage simulators, emulators, and physical devices for mopro testing.

## Arguments

- `$1` (optional): Action: `list`, `start`, `run`. Defaults to `list`.
- `$2` (optional): Platform: `ios`, `android`, `flutter`, `all`. Defaults to `all`.

## Instructions

### Action: list (default)

List all available devices without any confirmation:

```bash
bash $SKILL_DIR/../skills/mopro-device/scripts/list-devices.sh $2
```

Parse and display results in a clear table:
| Name | Type | Platform | Status | ID |
|------|------|----------|--------|----|

Group by platform. Highlight any currently booted/running devices.

### Action: start

Start a simulator or emulator.

1. First list available devices for the platform.
2. If multiple devices available, ask which one to start.
3. Confirm before booting:

```
About to boot <device_name>. Proceed?
```

**iOS:**
```bash
xcrun simctl boot "<device_name>"
open -a Simulator
```

**Android:**
```bash
$ANDROID_HOME/emulator/emulator -avd <avd_name> &
```

4. Verify the device is running:
```bash
# iOS
xcrun simctl list devices booted

# Android
adb devices
```

### Action: run

Install and launch the app on a running device.

1. Detect the platform from the project (check for .xcodeproj, build.gradle, pubspec.yaml, package.json).
2. Confirm before installing:

```
About to install and run the app on <device>. Proceed?
```

3. Run platform-specific commands:

**iOS (Xcode):**
```bash
xcodebuild -project *.xcodeproj -scheme <scheme> \
    -destination 'platform=iOS Simulator,name=<device>' build
```

**Android (Gradle):**
```bash
./gradlew installDebug
```

**Flutter:**
```bash
flutter run -d <device_id>
```

**React Native:**
```bash
npm run ios   # or npm run android
```
