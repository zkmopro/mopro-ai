---
name: mopro-env
description: >-
  Check and fix the development environment for mopro. Use this skill whenever
  a user reports "command not found" errors, missing build tools, or asks what
  they need to install. Also use proactively before any mopro build if the user
  hasn't confirmed their environment is set up, or when they're starting fresh.
license: MIT OR Apache-2.0
metadata:
  author: zkmopro
  version: "0.3.0"
---

# Mopro Environment Setup

This skill helps users verify their development environment is ready for mopro
development and guides them through installing missing prerequisites.

## When to Use

- User asks to check their environment or setup
- User reports build tool errors or missing dependencies
- User is starting fresh with mopro
- User asks "what do I need to install"
- User encounters "command not found" errors for rust, cmake, mopro, etc.

## Related Skills

- **mopro-project**: After environment is ready, proceed to project initialization

## Workflow

### Step 1: Run Environment Check

Run the unified environment check script:

```bash
bash scripts/check-env.sh
```

> Run from the skill directory. The script outputs a JSON array to parse and present.

This outputs a JSON array of tool statuses. Parse and present results clearly.

### Step 2: Assess Results

Categorize tools into three groups:
1. **Required (all platforms)**: rust, cargo, cmake, mopro-cli
2. **Platform-specific**: xcode-cli (iOS), android-sdk/ndk/jdk (Android),
   flutter (Flutter), node (React Native), wasm-pack (Web)
3. **Optional**: circom, nargo (circuit compilers)

### Step 3: Guide Fixes

For each missing required tool, provide the install command:

| Tool | Install Command |
|------|----------------|
| Rust + Cargo | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| CMake | `brew install cmake` (macOS) or download from https://cmake.org/download/ |
| mopro-cli | `cargo install mopro-cli` |
| Xcode CLI tools | `xcode-select --install` |
| Android NDK | Install via Android Studio > SDK Manager > SDK Tools > NDK (Side by Side) |
| JDK 17+ | `brew install openjdk@17` or https://www.oracle.com/java/technologies/downloads |
| Flutter | https://docs.flutter.dev/get-started/install |
| Node.js 20+ | `brew install node@20` or https://nodejs.org |
| wasm-pack | `curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf \| sh` |

### Step 4: Platform-Specific Setup

If the user specifies a target platform, also check:

**iOS**: Verify Xcode command-line tools path is set correctly:
```bash
xcode-select -p
# Should output: /Applications/Xcode.app/Contents/Developer
```

**Android**: Verify environment variables:
```bash
echo $ANDROID_HOME   # Should be set (e.g., ~/Library/Android/sdk)
ls $ANDROID_HOME/ndk  # Should list NDK version directories
```

**React Native**: Verify Node.js version >= 20:
```bash
node --version
```

**Flutter**: Run Flutter doctor:
```bash
flutter doctor
```

**Web**: Verify wasm-pack and Chrome:
```bash
wasm-pack --version
```

## Troubleshooting

### "mopro: command not found"
User needs to install the CLI: `cargo install mopro-cli`
Ensure `~/.cargo/bin` is in PATH.

### "rustup target add" fails
Run `rustup update` first, then retry adding the target.

### CMake not found during build
On macOS: `brew install cmake`
Ensure cmake is in PATH: `which cmake`

### Android NDK not found
Set ANDROID_HOME and verify NDK installation:
```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
ls $ANDROID_HOME/ndk/
```
If empty, install NDK via Android Studio > SDK Manager > SDK Tools.

### Xcode command-line tools not configured
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

For the full prerequisite installation guide, see references/prerequisites.md.
