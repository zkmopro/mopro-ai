---
description: Create a complete mopro project from scratch (init + build + create) with confirmation gates between each step
argument-hint: "[name] [adapter] [platform]"
allowed-tools: Bash, Read, Write, Glob
---

# /mopro:new

Orchestrate the full mopro workflow: init → build → create.
This is the 80% command for starting a new ZK mobile project from scratch.

## Arguments

- `$1` (optional): Project name
- `$2` (optional): Adapter: `circom`, `halo2`, `noir`
- `$3` (optional): Platform: `ios`, `android`, `flutter`, `react-native`, `web`

## Instructions

### Gate 1: Gather Parameters

If any arguments are missing, ask the user:

1. **Project name**: Suggest a default (e.g., `my-zk-app`)
2. **Adapter**: Explain the options:
   - `circom` — Groth16, most common, fast on mobile
   - `halo2` — Plonkish, used in Ethereum L2s
   - `noir` — Developer-friendly DSL (not available on 32-bit Android or WASM)
3. **Platform**: Which target?
   - `ios` — Swift + Xcode
   - `android` — Kotlin + Android Studio
   - `flutter` — Dart, cross-platform iOS + Android
   - `react-native` — TypeScript, cross-platform
   - `web` — JavaScript + WASM (Halo2/Circom only)

### Gate 2: Environment Check

Run the environment check for the selected platform:
```bash
bash $SKILL_DIR/../skills/mopro-env/scripts/check-env.sh <platform>
```

If mopro-cli is not installed:
```
mopro-cli is not installed. Install it with:
  cargo install mopro-cli
```
Stop and guide installation.

If other required tools are missing, warn but allow the user to proceed.

### Gate 3: Init

```
Step 1/3: Initialize project

About to run: mopro init --project_name <name> --adapter <adapter>
This creates a new directory './<name>' with Rust scaffolding.
Proceed?
```

Run init and verify the project was created:
```bash
mopro init --project_name <name> --adapter <adapter>
ls <name>/src/lib.rs
```

### Gate 4: Build

```
Step 2/3: Build bindings

About to run: mopro build --platforms <platform> --mode release --architectures <arch>

⚠️  This will take 5-15 minutes in release mode.
    Building for <arch> only (minimal testing config).

Proceed?
```

Select default minimal architecture:
- iOS: `aarch64-apple-ios-sim`
- Android: `x86_64-linux-android`
- Flutter: `aarch64-apple-ios-sim` (or `x86_64-linux-android` if user prefers Android)
- React Native: `aarch64-apple-ios-sim`
- Web: `wasm32-unknown-unknown`

Change to the project directory and run build in background:
```bash
cd <name> && mopro build --platforms <platform> --mode release --architectures <arch>
```

Use `run_in_background=true`. Inform the user the build is running.
Check on it periodically. Do NOT assume failure from slow output.

After build completes, verify output directory exists.

### Gate 5: Create

Only proceed after build is confirmed successful.

```
Step 3/3: Generate app template

About to run: mopro create --framework <platform>
This generates a starter <platform> app with mopro bindings.
Proceed?
```

```bash
mopro create --framework <platform>
```

### Summary

After all steps complete, summarize:

1. What was created (project name, adapter, platform)
2. Where the project lives
3. How to run it:
   - iOS: Open `.xcodeproj` in Xcode, select simulator, run
   - Android: Open in Android Studio, sync Gradle, run
   - Flutter: `flutter run`
   - React Native: `npm install && npm run ios`
   - Web: open in browser with correct headers
4. Next steps (customize circuits, modify UI, etc.)
