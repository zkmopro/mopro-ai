---
name: mopro-test
description: >-
  Write and run tests for mopro projects at three levels: Rust unit tests, FFI
  binding tests, and mobile UI tests. Use this skill whenever someone wants to
  test proof generation, verify bindings work, add test coverage, or diagnose
  test failures. Also use when someone asks "does it work" or "how do I verify"
  in a mopro project context.
license: MIT OR Apache-2.0
metadata:
  author: zkmopro
  version: "0.3.1"
---

# Mopro Testing

This skill helps users write and run tests for mopro projects at three levels:
Rust unit tests, FFI binding tests, and mobile UI tests.

## When to Use

- User wants to add tests to their mopro project
- User needs to verify proof generation/verification works
- User asks about testing FFI bindings
- User wants platform-specific UI tests
- User encounters test failures

## Related Skills

- **mopro-project**: Ensure project is initialized before testing
- **mopro-device**: For running FFI/UI tests on simulators/emulators

## Three Test Levels

### Level 1: Rust Unit Tests

Test the Rust prover logic directly using `cargo test`. This is the fastest
feedback loop and doesn't require any mobile toolchain.

```bash
cd <project_dir>
cargo test
```

**What to test:**
- Circuit input validation
- Proof generation with known inputs
- Proof verification
- Error handling (invalid inputs, missing files)

### Level 2: FFI Binding Tests

Test the generated UniFFI bindings to ensure the Rust→native bridge works.
These tests run through the same FFI layer that mobile apps use.

**For iOS bindings:**
```bash
# Requires Xcode and iOS simulator
swift test  # If using Swift package
```

**For Android bindings:**
```bash
# Requires Android toolchain
./gradlew test
```

**For WASM bindings:**
```bash
wasm-pack test --chrome --headless
```

### Level 3: Mobile UI Tests

Platform-specific tests that verify the full stack: UI → FFI → Rust → proof.

- **iOS**: XCTest / XCUITest
- **Android**: JUnit + Espresso / Compose Testing
- **Flutter**: widget tests + integration tests
- **React Native**: Jest + Detox

## Workflow

### Step 1: Determine Test Level

Ask the user what they want to test:
- "Does proof generation work?" → Level 1 (Rust)
- "Do the bindings work?" → Level 2 (FFI)
- "Does the app work end-to-end?" → Level 3 (UI)

### Step 2: Generate Test Code

Based on the level, generate appropriate test files. See:
- references/rust-ffi-tests.md for Level 1 and 2
- references/mobile-ui-tests.md for Level 3

### Step 3: Run Tests

**Rust tests (no confirmation needed):**
```bash
cargo test
cargo test --all-features
```

**FFI tests (confirm before running — requires toolchain):**
```
About to run FFI binding tests. This requires:
- iOS: Xcode simulator
- Android: Android emulator or device
- Web: Chrome + ChromeDriver

Proceed?
```

**UI tests (confirm before running — requires device/simulator):**
```
About to run UI tests on <platform>. This requires:
- A running simulator/emulator or connected device

Proceed?
```

### Step 4: Diagnose Failures

For test failures:
1. Check if circuit artifacts exist in the correct location
2. Verify input format matches expected JSON schema
3. Check that the build was successful and bindings are current
4. For FFI tests, verify the correct architecture was built

## Quick Test Commands

```bash
# Rust-level proof test
cargo test

# Rust with all features
cargo test --all-features

# Code formatting check
cargo fmt --all -- --check

# Lint check
cargo clippy --all-targets --all-features

# WASM tests
wasm-pack test --chrome --headless -- --no-default-features --features wasm
```

## Troubleshooting

### "Cannot find test-vectors"
Tests expect circuit artifacts at relative paths. Run `cargo test` from the
project root directory (where `Cargo.toml` lives).

### "proof verification failed"
Check that:
1. The `.zkey` file is not corrupted
2. Input values match the circuit's expected inputs
3. The correct `ProofLib` variant is used

### Tests pass locally but fail in CI
- CI may not have the Rust targets installed
- CI timeout may be too short for proof generation
- Ensure circuit artifacts are committed or downloaded in CI
