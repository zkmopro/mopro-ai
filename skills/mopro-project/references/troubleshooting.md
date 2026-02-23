# Mopro Project Troubleshooting

Top build and init errors with diagnosis and fixes.

## 1. "mopro: command not found"

**Cause:** mopro-cli not installed or not in PATH.

**Fix:**
```bash
cargo install mopro-cli
# Ensure ~/.cargo/bin is in PATH
export PATH="$HOME/.cargo/bin:$PATH"
```

If installed but still not found, check:
```bash
which mopro
ls ~/.cargo/bin/mopro
```

## 2. Android NDK Not Found / NDK Version Mismatch

**Symptoms:**
- `error: could not find NDK`
- `NDK_HOME is not set`
- Build fails looking for Android toolchain

**Fix:**
```bash
# Verify NDK is installed
ls $ANDROID_HOME/ndk/
# Should show version directories

# Set environment variables
export ANDROID_HOME="$HOME/Library/Android/sdk"
export NDK_HOME="$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk | sort -V | tail -1)"
```

If `$ANDROID_HOME/ndk/` is empty, install NDK via:
Android Studio > Settings > Languages & Frameworks > Android SDK > SDK Tools >
NDK (Side by Side) > check and apply.

## 3. Missing Rust Target

**Symptoms:**
- `error[E0463]: can't find crate for 'std'`
- `error: target 'aarch64-apple-ios-sim' not found`
- `error: could not compile ... for target ...`

**Fix:**
```bash
# Add the missing target
rustup target add aarch64-apple-ios-sim

# Or add all common targets at once
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
rustup target add aarch64-linux-android x86_64-linux-android
rustup target add wasm32-unknown-unknown
```

If `rustup target add` fails:
```bash
rustup update
rustup target add <target>
```

## 4. `rust_witness!` Macro Errors (Circom)

**Symptoms:**
- `error: cannot find macro 'rust_witness!'`
- `unresolved import 'circom::witness'`

**Cause:** The Circom adapter's witness generation macro isn't properly configured.

**Fix:** Verify `src/lib.rs` has the correct macro invocation:
```rust
use mopro_ffi::circom;

circom::set_circom_circuits! {
    ("multiplier2_final.zkey", circom::witness::witnesscalc::multiplier2::witness),
}
```

Ensure:
1. The `.zkey` filename matches what's in `test-vectors/circom/`
2. The witness module name matches the circuit name (underscores, not hyphens)
3. `mopro-ffi` dependency has `circom` feature enabled in `Cargo.toml`

## 5. Cargo.lock Conflicts

**Symptoms:**
- `error: failed to select a version for ...`
- Merge conflicts in `Cargo.lock`
- Build fails after switching adapters

**Fix:**
```bash
# Delete and regenerate
rm Cargo.lock
cargo build
```

If the issue persists after adapter changes, also clean the build cache:
```bash
cargo clean
cargo build
```

## 6. CMake Not Found During Build

**Symptoms:**
- `error: cmake not found`
- `Could not find CMAKE_ROOT`

**Fix:**
```bash
# macOS
brew install cmake

# Verify
cmake --version
which cmake
```

If installed via non-standard path, ensure it's in PATH:
```bash
export PATH="/Applications/CMake.app/Contents/bin:$PATH"
```

## 7. Build Appears to Hang / Timeout

**Symptoms:**
- No output for several minutes during `mopro build`
- CI/CD pipeline times out
- User assumes build failed

**This is NOT a failure.** Mopro builds are genuinely slow:
- Release mode: 5-15+ minutes for a single architecture
- Multiple architectures multiply the time
- First build (cold cache) is slowest

**What to do:**
- Wait. Check CPU usage to confirm the build is still running.
- For CI, set timeouts to 30+ minutes.
- Use `--mode debug` for faster iteration (not recommended for testing proofs).

## 8. Xcode Command-Line Tools Not Configured

**Symptoms:**
- `xcrun: error: unable to find utility`
- `xcode-select: error: no developer tools were found`
- iOS build fails before compiling

**Fix:**
```bash
# Install CLI tools
xcode-select --install

# Point to Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verify
xcode-select -p
xcodebuild -version
```

## 9. Halo2 Circuit Memory Issues on Mobile

**Symptoms:**
- App crashes during proof generation
- `EXC_RESOURCE RESOURCE_TYPE_MEMORY` on iOS
- OOM killer on Android

**Cause:** Some Halo2 circuits (e.g., RSA) require ~5GB of memory. Mobile devices
typically have 3-6GB total RAM.

**Workarounds:**
- Use smaller circuits for mobile (reduce constraint count)
- Test on devices with more RAM (iPhone Pro models, high-end Android)
- Consider offloading to a server for memory-intensive proofs
- Use Circom/Groth16 for mobile — it's more memory-efficient

## 10. Android Import Name Mismatch

**Symptoms:**
- `Unresolved reference: uniffi`
- Kotlin compilation error after integrating bindings

**Cause:** Android/Kotlin imports require underscores, not hyphens.

**Fix:** If your project is named `my-zk-app`, the import must be:
```kotlin
import uniffi.my_zk_app.*  // underscores, not hyphens
```

NOT:
```kotlin
import uniffi.my-zk-app.*  // WRONG — hyphens cause syntax error
```

The generated `mopro.kt` file's package declaration will show the correct name.

## General Debugging Tips

**Check mopro version:**
```bash
mopro --version
```

**Check Rust toolchain:**
```bash
rustc --version
rustup show
```

**Clean rebuild:**
```bash
cargo clean
rm -rf target/
mopro build --platforms <platform> --mode release
```

**Verbose build output:**
```bash
RUST_LOG=debug mopro build --platforms <platform>
```
