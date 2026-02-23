# Mopro CLI Reference

Complete reference for all mopro CLI commands, flags, and adapter configuration.

## Installation

```bash
cargo install mopro-cli
```

From source:
```bash
git clone https://github.com/zkmopro/mopro.git
cd mopro/cli
cargo install --path .
```

## Commands

### `mopro init`

Creates a new mopro project with Rust scaffolding and test vectors.

**Interactive mode** (prompts for all options):
```bash
mopro init
```

**Non-interactive mode** (CI-friendly):
```bash
mopro init --project_name my_zk_app --adapter circom,noir
```

**Flags:**
| Flag | Description | Example |
|------|-------------|---------|
| `--project_name` | Project directory name | `--project_name my_app` |
| `--adapter` | Comma-separated adapter list | `--adapter circom,halo2,noir` |

**Adapter options:** `circom`, `halo2`, `noir`, or any combination.

### `mopro build`

Compiles Rust project into platform-specific bindings.

**Interactive mode:**
```bash
mopro build
```

**Non-interactive mode:**
```bash
mopro build --platforms ios --mode release --architectures aarch64-apple-ios-sim
```

**Flags:**
| Flag | Description | Example |
|------|-------------|---------|
| `--platforms` | Target platform | `--platforms ios` |
| `--mode` | Build mode | `--mode release` or `--mode debug` |
| `--architectures` | Target architectures (comma-separated) | `--architectures aarch64-apple-ios,aarch64-apple-ios-sim` |

**Platform values:** `ios`, `android`, `flutter`, `react-native`, `web`

**Build outputs:**
| Platform | Output Directory | Contents |
|----------|-----------------|----------|
| iOS | `MoproiOSBindings/` | `mopro.swift`, `MoproBindings.xcframework` |
| Android | `MoproAndroidBindings/` | `jniLibs/` (per-arch .so files), `uniffi/mopro/mopro.kt` |
| Flutter | `mopro_flutter_bindings/` | Flutter plugin package |
| React Native | `MoproReactNativeBindings/` | Turbo Module package |
| Web | `MoproWasmBindings/` | `mopro_wasm_lib.js`, WASM files |

### `mopro create`

Generates a starter app template with mopro bindings integrated.

```bash
mopro create --framework flutter
```

**Flags:**
| Flag | Description | Example |
|------|-------------|---------|
| `--framework` | App framework | `--framework ios` |

**Framework values:** `ios`, `android`, `flutter`, `react-native`, `web`

Must run after a successful `mopro build`. Uses the bindings from the build output.

### `mopro update`

Copies updated bindings to an existing app project.

```bash
mopro update --src ./MoproiOSBindings --dest ../MyiOSApp --no_prompt
```

**Flags:**
| Flag | Description | Example |
|------|-------------|---------|
| `--src` | Source bindings directory | `--src ./MoproiOSBindings` |
| `--dest` | Destination app directory | `--dest ../MyApp` |
| `--no_prompt` | Skip confirmation prompts | `--no_prompt` |

### `mopro bindgen`

Generates bindings for specific circuits (advanced usage).

```bash
mopro bindgen --circuit-dir ./circuits --platforms ios
```

**Flags:**
| Flag | Description | Example |
|------|-------------|---------|
| `--circuit-dir` | Directory containing circuit artifacts | `--circuit-dir ./circuits` |
| `--platforms` | Target platform | `--platforms ios` |

### `mopro --help`

Shows all available commands and global flags.

### `mopro --version`

Prints the installed mopro-cli version.

## Adapter Setup Details

### Circom Adapter

Uses Groth16 proving system over BN254 or BLS12-381 curves.

**Required artifacts** (place in `test-vectors/circom/`):
- `<circuit_name>_final.zkey` — proving key from snarkjs trusted setup
- `<circuit_name>.wasm` — witness generator compiled by circom

**Rust configuration** in `src/lib.rs`:
```rust
use mopro_ffi::circom;

circom::set_circom_circuits! {
    ("multiplier2_final.zkey", circom::witness::witnesscalc::multiplier2::witness),
}
```

**Proving libraries:**
- `arkworks` — pure Rust, cross-platform (default)
- `rapidsnark` — C++ based, faster on some platforms

### Halo2 Adapter

Uses Plonkish proving system. Supports PSE Halo2 implementation.

**Required artifacts** (place in `test-vectors/halo2/`):
- `<circuit_name>_srs.bin` — Structured Reference String
- `<circuit_name>_pk.bin` — Proving key
- `<circuit_name>_vk.bin` — Verification key

**Rust configuration** in `src/lib.rs`:
```rust
use mopro_ffi::halo2;

halo2::set_halo2_circuits! {
    ("plonk_fibonacci_pk.bin", my_circuit::prove,
     "plonk_fibonacci_vk.bin", my_circuit::verify),
}
```

**Supported variants:** plonk-fibonacci, hyperplonk-fibonacci, gemini-fibonacci

### Noir Adapter

Uses Barretenberg proving system.

**Required artifacts** (place in `test-vectors/noir/`):
- `<circuit_name>.json` — compiled Noir circuit

**Rust configuration** in `src/lib.rs`:
```rust
use mopro_ffi::noir;

// Noir circuits are loaded at runtime via JSON
```

**Limitations:**
- Not available on 32-bit Android (i686, armv7)
- Does not compile to WASM via Mopro stack
- Requires noir_rs branch v1.0.0-beta.8-3

## Alternative Build Commands

For development/debugging, you can use cargo directly:

```bash
cargo run --bin ios                                                 # iOS
cargo run --bin android                                             # Android
cargo run --bin flutter --no-default-features --features flutter    # Flutter
cargo run --bin react_native                                        # React Native
cargo run --bin web --no-default-features --features wasm           # Web/WASM
```

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `ANDROID_HOME` | Android SDK location | `~/Library/Android/sdk` |
| `NDK_HOME` | Android NDK location | `$ANDROID_HOME/ndk/26.1.10909125` |
