# Mopro Prerequisites

Complete installation guide for all tools needed for mopro development.

## Core Requirements (All Platforms)

### Rust

Rust is required for all mopro development. Install via rustup:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

After installation, add required targets for your platform:

```bash
# iOS targets
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

# Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

# Web/WASM target
rustup target add wasm32-unknown-unknown
```

Verify: `rustc --version` (minimum 1.70+, recommended 1.77+)

### CMake

Required for native compilation of cryptographic libraries.

**macOS (Homebrew):**
```bash
brew install cmake
```

**Manual install:**
Download from https://cmake.org/download/

Verify: `cmake --version`

### mopro CLI

The mopro command-line tool orchestrates project setup and builds.

```bash
cargo install mopro-cli
```

Or build from source:
```bash
git clone https://github.com/zkmopro/mopro.git
cd mopro/cli
cargo install --path .
```

Verify: `mopro --version`

## iOS Prerequisites

### Xcode

Install Xcode from the Mac App Store. Minimum version: **Xcode 15+**.

After installation, configure command-line tools:
```bash
# Install command-line tools if not present
xcode-select --install

# Verify path is set correctly
xcode-select -p
# Expected: /Applications/Xcode.app/Contents/Developer

# If wrong, manually set:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

Also verify in Xcode UI: **Xcode > Settings > Locations > Command Line Tools**
must point to the installed Xcode version.

### iOS Rust Targets

```bash
rustup target add aarch64-apple-ios          # Physical devices
rustup target add aarch64-apple-ios-sim      # Simulator (Apple Silicon)
rustup target add x86_64-apple-ios           # Simulator (Intel Mac)
```

## Android Prerequisites

### JDK (Java Development Kit)

JDK 17 or higher is required.

**macOS (Homebrew):**
```bash
brew install openjdk@17
```

**Manual install:**
Download from https://www.oracle.com/java/technologies/downloads

Verify: `java -version`

### Android Studio

Install from https://developer.android.com/studio

After installation:
1. Open Android Studio
2. Go to **SDK Manager** (Settings > Languages & Frameworks > Android SDK)
3. Under **SDK Platforms**: Install your target API level (recommended: API 34)
4. Under **SDK Tools**: Check and install:
   - **Android SDK Build-Tools**
   - **NDK (Side by Side)** — required for Rust cross-compilation
   - **Android SDK Command-line Tools**
   - **Android SDK Platform-Tools**

### Android Environment Variables

Add to your shell profile (`~/.zshrc`, `~/.bashrc`, or `~/.bash_profile`):

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/tools/bin"

# Set NDK path (replace version with your installed version)
export NDK_HOME="$ANDROID_HOME/ndk/$(ls $ANDROID_HOME/ndk | sort -V | tail -1)"
```

Verify NDK:
```bash
ls $ANDROID_HOME/ndk/
# Should show version directories like 26.1.10909125
```

### Android Rust Targets

```bash
rustup target add aarch64-linux-android      # Physical devices (64-bit ARM)
rustup target add armv7-linux-androideabi     # Physical devices (32-bit ARM)
rustup target add x86_64-linux-android        # Emulator (64-bit x86)
rustup target add i686-linux-android          # Emulator (32-bit x86)
```

**Note**: 32-bit targets (i686, armv7) only support Circom and Halo2.
Noir/Barretenberg requires 64-bit targets.

## Flutter Prerequisites

### Flutter SDK

Install Flutter 3.0.0+ following https://docs.flutter.dev/get-started/install

Verify:
```bash
flutter --version    # Should show 3.0.0+
flutter doctor       # Check for issues
```

### Flutter Android Configuration

In `android/app/build.gradle`:
```gradle
android {
    compileSdk 34
    defaultConfig {
        minSdk 24
        targetSdk 34
    }
}
```

**Critical for release builds** — disable code shrinking:
```gradle
buildTypes {
    release {
        minifyEnabled false
        shrinkResources false
    }
}
```

Also requires JNA dependency in `android/app/build.gradle.kts`:
```kotlin
dependencies {
    implementation("net.java.dev.jna:jna:5.13.0@aar")
}
```

## React Native Prerequisites

### Node.js

Node.js version 20 or higher is required.

**macOS (Homebrew):**
```bash
brew install node@20
```

**Or via nvm:**
```bash
nvm install 20
nvm use 20
```

Verify: `node --version` (must be v20+)

### React Native CLI

```bash
npx @react-native-community/cli@latest init MyApp --version 0.82
```

Minimum React Native version: **0.82+** (for Turbo Module support).

### CocoaPods (iOS builds)

```bash
sudo gem install cocoapods
```

## Web/WASM Prerequisites

### wasm-pack

```bash
curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh
```

Verify: `wasm-pack --version`

### Chrome/ChromeDriver

For WASM testing:
- Chrome: https://www.google.com/chrome/
- ChromeDriver: https://googlechromelabs.github.io/chrome-for-testing/

### WASM Rust Target

```bash
rustup target add wasm32-unknown-unknown
```

## Circuit Compiler Prerequisites (Optional)

These are only needed if you are compiling circuits from source. Pre-compiled
circuit artifacts (.zkey, .wasm, .json) can be used without these tools.

### Circom

```bash
git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
```

Verify: `circom --version`

### Noir (Nargo)

Install via noirup:
```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash
noirup
```

Verify: `nargo --version`

## Quick Verification

Run this to verify all core tools at once:

```bash
echo "=== Core ===" && \
rustc --version && \
cargo --version && \
cmake --version | head -1 && \
mopro --version && \
echo "=== All OK ==="
```
