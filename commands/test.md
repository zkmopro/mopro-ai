---
description: Run or generate tests for a mopro project at various levels (Rust, FFI, UI)
argument-hint: "[level] [platform]"
allowed-tools: Bash, Read, Write, Glob
---

# /mopro:test

Run or generate tests for a mopro project.

## Arguments

- `$1` (optional): Test level: `rust`, `ffi`, `ui`, `all`. Defaults to `rust`.
- `$2` (optional): Platform for FFI/UI tests: `ios`, `android`, `flutter`,
  `react-native`, `web`

## Instructions

### Level: rust (default)

1. Verify we're in a mopro project:
```bash
ls Cargo.toml
```

2. Run Rust tests directly (no confirmation needed):
```bash
cargo test
```

3. Also run code quality checks:
```bash
cargo fmt --all -- --check
cargo clippy --all-targets --all-features
```

4. Report results: passed/failed tests, any warnings.

### Level: ffi

1. Determine the platform (ask if not specified).

2. Confirm before running:
```
About to run FFI binding tests for <platform>.
This requires a running simulator/emulator for mobile platforms.
Proceed?
```

3. Run platform-specific FFI tests:
   - iOS: `xcodebuild test -project ... -scheme ... -destination 'platform=iOS Simulator,...'`
   - Android: `./gradlew connectedAndroidTest`
   - Web: `wasm-pack test --chrome --headless`

### Level: ui

1. Determine the platform (ask if not specified).

2. If test files don't exist, offer to generate them:
```
No UI tests found for <platform>. Want me to generate test templates?
```

Generate from patterns in the mopro-test skill references.

3. Confirm before running:
```
About to run UI tests on <platform>.
This requires a running simulator/emulator or connected device.
Proceed?
```

4. Run:
   - iOS: `xcodebuild test ...`
   - Android: `./gradlew connectedAndroidTest`
   - Flutter: `flutter test` (widget) or `flutter test integration_test/` (integration)
   - React Native: `npm test`

### Level: all

Run all three levels in sequence: rust → ffi → ui.
Confirm before each level that requires a device.
