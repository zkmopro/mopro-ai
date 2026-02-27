# Mopro Plugin

Mopro is a toolkit for building mobile-native zero-knowledge proof applications.
It uses Rust + UniFFI to generate FFI bindings for iOS, Android, Flutter, React
Native, and Web. Supported proving systems: Circom (Groth16), Halo2 (Plonkish),
Noir (Barretenberg).

## Lifecycle
init → build → create → develop → update (repeat build→update as circuits change)
Flutter exception: skip `mopro update` — rebuild with
`mopro build --platforms flutter` then `flutter pub get`.

## CLI Quick Reference
- `mopro init --project_name NAME --adapter circom,noir` (non-interactive)
- `mopro build --platforms ios --mode release --architectures aarch64-apple-ios-sim`
- `mopro build --platforms flutter --mode release` (Flutter — NOT --platforms ios)
- `mopro build --platforms react-native --mode release` (RN — NOT --platforms ios)
- `mopro create --framework flutter`
- `mopro update --src ./ios_bindings --dest ../MyApp --no_prompt`
- `mopro bindgen --circuit-dir ./circuits --platforms ios`

## Guardrails
- mopro build and mobile compilation are LONG (5-15+ min in release mode).
  ALWAYS warn user about expected duration before starting. NEVER assume a
  build failed due to slow output. Do NOT re-run builds without user confirmation.
- Default to minimal architectures for testing (aarch64-apple-ios-sim for iOS
  simulator, x86_64-linux-android for Android emulator). Only build for device/
  release when explicitly requested.
- NEVER chain build + create in a single command. Run build, confirm success,
  then create.
- Default to release mode unless user says debug.
- Always confirm platform selection before building (it takes too long to redo).
- If mopro-cli is not installed, guide user to `cargo install mopro-cli`. Do NOT
  attempt to manually recreate project scaffolding.
- For cross-platform frameworks, use `--platforms flutter` or
  `--platforms react-native`. NEVER use `--platforms ios` or
  `--platforms android` for Flutter or React Native apps — those produce
  native-only bindings that are incompatible.

## Project Detection
Before running any mopro CLI command (build, create, update, bindgen), verify
the working directory is inside an initialized mopro project. Check for ALL of:
- `Cargo.toml` containing `mopro-ffi` dependency
- `src/lib.rs` exists
- `test-vectors/` directory exists

If any marker is missing, stop and tell the user:
"This directory does not appear to be an initialized mopro project.
Run `mopro init` first, or `cd` into your existing mopro project directory."
Do NOT attempt to create these files manually.

## Build Duration Handling
For long-running builds, run builds in background if your agent supports
background or async execution. Check on progress periodically.
Warn user: "This build may take 5-15 minutes in release mode."

## Binding Output Directories
After `mopro build`, output directories are generated based on platform:
- iOS: `MoproiOSBindings/` (mopro.swift + MoproBindings.xcframework)
- Android: `MoproAndroidBindings/` (jniLibs/ + uniffi/mopro/mopro.kt)
- React Native: `MoproReactNativeBindings/`
- Web/WASM: `MoproWasmBindings/` (mopro_wasm_lib.js)
- Flutter: `mopro_flutter_bindings/`

## ProofLib Enum Naming
Platform-specific enum casing for ProofLib:
- Swift (iOS): `ProofLib.arkworks`
- Kotlin (Android): `ProofLib.ARKWORKS`
- React Native: `ProofLib.Arkworks`
- Dart (Flutter): `ProofLib.arkworks`

## Circuit Input Format
All adapters require inputs as flat, one-dimensional JSON string mappings:
`"{\"a\":[\"3\"],\"b\":[\"5\"]}"`

## Architecture Defaults
- iOS simulator: `aarch64-apple-ios-sim` (Apple Silicon) or `x86_64-apple-ios` (Intel)
- iOS device: `aarch64-apple-ios`
- Android emulator: `x86_64-linux-android`
- Android device: `aarch64-linux-android`
- Web: `wasm32-unknown-unknown`

## Known Limitations
- 32-bit Android (i686, armv7): Only Circom + Halo2 (no Noir/Barretenberg)
- WASM + Barretenberg: Not supported via Mopro stack
- Halo2 RSA on mobile: Crashes (~5GB memory needed, mobile has ~3GB)
- Flutter release: Must disable code shrinking (minifyEnabled false)
- Android imports: Replace hyphens with underscores in `import uniffi.<name>.*`

## Validated Versions
- mopro-cli / mopro-ffi: 0.3.x
- Noir adapter: noir_rs branch v1.0.0-beta.8-3
- Flutter: 3.0+, minSdk 24, compileSdk 34
- React Native: 0.82+, Node.js 20+
- Xcode: 15+ with command-line tools
- Android: NDK via SDK Manager, JDK 17+
