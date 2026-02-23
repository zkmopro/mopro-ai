# Platform Architecture Compatibility Matrix

Reference for target architectures, device types, and proving system support.

## iOS Architectures

| Target Triple | Device Type | All Proving Systems |
|---|---|---|
| `aarch64-apple-ios` | Physical devices (iPhone, iPad) — 64-bit ARM | Yes |
| `aarch64-apple-ios-sim` | Simulator on Apple Silicon Macs (M1/M2/M3) | Yes |
| `x86_64-apple-ios` | Simulator on Intel Macs | Yes |

**Recommended defaults:**
- Development/testing: `aarch64-apple-ios-sim` (most developers use Apple Silicon)
- Production: `aarch64-apple-ios` (physical devices only)
- Universal: `aarch64-apple-ios,aarch64-apple-ios-sim,x86_64-apple-ios`

**Adding Rust targets:**
```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

## Android Architectures

| Target Triple | Device Type | Proving Systems |
|---|---|---|
| `aarch64-linux-android` | 64-bit ARM devices (Pixel 6+, Galaxy S22+) | All (Circom, Halo2, Noir) |
| `x86_64-linux-android` | 64-bit x86 emulators | All (Circom, Halo2, Noir) |
| `armv7-linux-androideabi` | 32-bit ARM devices (older: Nexus 7, Galaxy S5) | Circom + Halo2 only |
| `i686-linux-android` | 32-bit x86 emulators (legacy) | Circom + Halo2 only |

**Recommended defaults:**
- Development/testing: `x86_64-linux-android` (standard emulator)
- Production: `aarch64-linux-android` (modern physical devices)
- Full coverage: `x86_64-linux-android,aarch64-linux-android`
- Legacy support: add `armv7-linux-androideabi,i686-linux-android`

**Important:** 32-bit architectures (`armv7`, `i686`) do NOT support
Noir/Barretenberg. Only Circom (arkworks/rust-witness) and Halo2 work on 32-bit.

**Adding Rust targets:**
```bash
rustup target add aarch64-linux-android x86_64-linux-android armv7-linux-androideabi i686-linux-android
```

## Web/WASM Architecture

| Target Triple | Notes |
|---|---|
| `wasm32-unknown-unknown` | Browser-based WebAssembly |

**Supported proving systems:**
- Circom: Yes
- Halo2 (PSE): Yes (with `wasm-bindgen-rayon` for multithreading)
- Noir/Barretenberg: **No** — does not compile to WASM via Mopro

**Critical:** Call `initThreadPool(navigator.hardwareConcurrency)` in JavaScript
to enable multi-threaded proving. Without it, Rayon falls back to single-core
sequential execution.

**Adding Rust target:**
```bash
rustup target add wasm32-unknown-unknown
```

## Flutter Architectures

Flutter builds target both iOS and Android. The architecture selection follows
the same rules as native iOS and Android above.

**Build command selects platform:**
```bash
mopro build --platforms flutter --mode release --architectures aarch64-apple-ios-sim
```

**Flutter-specific requirements:**
- `minSdk 24` in Android config
- `compileSdk 34`
- JNA 5.13.0 dependency for Android

## React Native Architectures

React Native builds also target iOS and Android natively. Architecture selection
is the same as native platforms.

```bash
mopro build --platforms react-native --mode release --architectures aarch64-apple-ios-sim
```

**React Native-specific requirements:**
- Node.js 20+
- React Native 0.82+ (Turbo Module support)

## Build Time Expectations

Build times vary significantly by mode and architecture count:

| Configuration | Expected Time |
|---|---|
| Single arch, debug | 2-5 minutes |
| Single arch, release | 5-15 minutes |
| All iOS arches, release | 15-30 minutes |
| All Android arches, release | 15-45 minutes |
| WASM, release | 5-10 minutes |

Factors affecting build time:
- Number of circuits registered
- Circuit complexity (constraint count)
- Number of adapters enabled
- Host machine CPU/RAM
- First build (cold cache) vs subsequent builds

## Architecture Selection Quick Reference

```bash
# iOS simulator only (fastest for testing)
mopro build --platforms ios --mode release --architectures aarch64-apple-ios-sim

# iOS device only
mopro build --platforms ios --mode release --architectures aarch64-apple-ios

# Android emulator only (fastest for testing)
mopro build --platforms android --mode release --architectures x86_64-linux-android

# Android device only
mopro build --platforms android --mode release --architectures aarch64-linux-android

# Web
mopro build --platforms web --mode release --architectures wasm32-unknown-unknown
```
