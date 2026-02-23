---
description: Build mopro ZK bindings for a target platform (iOS, Android, Flutter, React Native, Web)
argument-hint: "[platform] [mode]"
allowed-tools: Bash, Read, Glob
---

# /mopro:build

Build mopro bindings for a target platform.

## Arguments

- `$1` (optional): Target platform: `ios`, `android`, `flutter`, `react-native`, `web`
- `$2` (optional): Build mode: `release` (default) or `debug`

## Instructions

1. If platform is not provided, ask the user which platform they want to target.

2. Verify mopro-cli is installed and we're in a mopro project directory:
```bash
mopro --version
ls Cargo.toml src/lib.rs
```

3. Select minimal default architectures for the platform:
   - iOS: `aarch64-apple-ios-sim` (Apple Silicon simulator)
   - Android: `x86_64-linux-android` (x86_64 emulator)
   - Flutter: follows iOS or Android defaults
   - React Native: follows iOS or Android defaults
   - Web: `wasm32-unknown-unknown`

4. If the user said "device", "production", or "release for app store", use
   device architectures instead:
   - iOS: `aarch64-apple-ios`
   - Android: `aarch64-linux-android`

5. Confirm before running with a duration warning:

```
About to run: mopro build --platforms <platform> --mode <mode> --architectures <arches>

⚠️  This build will take 5-15 minutes in release mode.
    Building only for <arch> (minimal testing config).

Proceed?
```

6. Run the build in the background:
```bash
# Run with run_in_background=true
mopro build --platforms <platform> --mode <mode> --architectures <arches>
```

Use `run_in_background=true` for the Bash tool call. Inform the user that the
build is running and you'll check on it periodically.

7. After build completes, verify the output directory exists:
   - iOS: `ls MoproiOSBindings/`
   - Android: `ls MoproAndroidBindings/`
   - Flutter: `ls mopro_flutter_bindings/`
   - React Native: `ls MoproReactNativeBindings/`
   - Web: `ls MoproWasmBindings/`

8. Report success and suggest next step: `mopro create` or manual integration.
