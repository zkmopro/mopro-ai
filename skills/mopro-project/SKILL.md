---
name: mopro-project
description: Initialize mopro projects, build ZK bindings for mobile platforms, create app templates, scaffold new ZK apps, compile for iOS/Android/Flutter/React Native/Web, mopro init, mopro build, mopro create
license: MIT OR Apache-2.0
metadata:
  author: zkmopro
  version: "0.3.0"
---

# Mopro Project Workflow

This skill manages the mopro CLI lifecycle: init → build → create → update.
Each step must complete and be confirmed before proceeding to the next.

## When to Use

- User wants to start a new mopro/ZK project
- User needs to build bindings for a specific platform
- User wants to create an app template from bindings
- User asks about mopro CLI commands or flags
- User encounters init/build/create errors

## Workflow

### Step 1: Determine Which Stage

Ask the user or detect from context which lifecycle stage they need:

1. **Init**: Creating a brand new project (`mopro init`)
2. **Build**: Compiling Rust to platform bindings (`mopro build`)
3. **Create**: Generating an app template (`mopro create`)
4. **Update**: Refreshing bindings in existing app (`mopro update`)

If the user says "set up a new project" or "start from scratch", begin at init.
If bindings already exist (check for `MoproiOSBindings/`, `MoproAndroidBindings/`,
etc.), skip to create or update.

### Step 2: Init (if needed)

Gather required parameters:
- **Project name**: lowercase, no spaces, hyphens OK
- **Adapter(s)**: circom, halo2, noir (can select multiple)

```
About to run: mopro init --project_name <name> --adapter <adapters>
This will create a new directory with Rust project scaffolding.
Proceed? [Y/n]
```

After init, verify the project directory was created with expected structure.
See references/project-structure.md for expected layout.

### Step 3: Build

**CRITICAL: Warn about build duration before starting.**

Gather required parameters:
- **Platform(s)**: ios, android, flutter, react-native, web
- **Mode**: release (default) or debug
- **Architectures**: Default to minimal for testing:
  - iOS: `aarch64-apple-ios-sim` (simulator only)
  - Android: `x86_64-linux-android` (emulator only)
  - Web: `wasm32-unknown-unknown`

```
About to run: mopro build --platforms <platform> --mode <mode> --architectures <arches>

⚠️  This build will take 5-15 minutes in release mode.
    Building only for <arch> (minimal testing config).
    For device/production builds, additional architectures are needed.

Proceed? [Y/n]
```

**Run the build in background** if your agent supports background/async execution.
Builds take 5-15 minutes in release mode. Check periodically.
Do NOT assume failure from slow output.

After build completes, verify output directory exists:
- iOS: `MoproiOSBindings/`
- Android: `MoproAndroidBindings/`
- Flutter: `mopro_flutter_bindings/`
- React Native: `MoproReactNativeBindings/`
- Web: `MoproWasmBindings/`

### Step 4: Create (if needed)

Only after build succeeds. Creates a starter app template.

```
About to run: mopro create --framework <framework>
This will generate a <framework> app template with mopro bindings.
Proceed? [Y/n]
```

### Step 5: Update (for existing projects)

When circuits change and bindings need refreshing:

```bash
mopro build --platforms <platform> --mode release
mopro update --src ./<BindingsDir> --dest ../<AppDir> --no_prompt
```

## Architecture Selection Guide

For quick testing, use minimal architectures. For production, build all.

See references/architectures.md for the full compatibility matrix.

**Quick defaults:**
- iOS simulator: `--architectures aarch64-apple-ios-sim`
- iOS device: `--architectures aarch64-apple-ios`
- Android emulator: `--architectures x86_64-linux-android`
- Android device: `--architectures aarch64-linux-android`
- All iOS: `--architectures aarch64-apple-ios,aarch64-apple-ios-sim,x86_64-apple-ios`
- All Android: `--architectures x86_64-linux-android,i686-linux-android,armv7-linux-androideabi,aarch64-linux-android`

## Adapter Configuration

After `mopro init`, the user must place circuit artifacts in the test-vectors directory:

- **Circom**: `.zkey` and `.wasm` files in `test-vectors/circom/`
- **Halo2**: SRS `.bin` files in `test-vectors/halo2/`
- **Noir**: `.json` circuit files in `test-vectors/noir/`

Default example circuits are included (multiplier2 for Circom/Noir, fibonacci for Halo2).

## Troubleshooting

For common build and init errors, see references/troubleshooting.md.

Key issues to watch for:
1. NDK version mismatch on Android
2. Missing Rust targets for the selected platform
3. `rust_witness!` macro errors with Circom adapter
4. Cargo.lock conflicts when switching adapters
5. Build timeout (not a failure — builds are genuinely slow)
