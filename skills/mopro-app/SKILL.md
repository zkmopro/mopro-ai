---
name: mopro-app
description: Build mobile apps with mopro, create iOS app, build Android app, Flutter ZK app, React Native app, Web WASM app, integrate mopro bindings, add zero-knowledge proofs to mobile app, generate app from description
license: MIT OR Apache-2.0
metadata:
  author: zkmopro
  version: "0.3.0"
---

# Mopro App Development

This skill helps users create and develop mobile applications that use mopro
for zero-knowledge proof generation and verification.

## When to Use

- User wants to build a mobile app with ZK proofs
- User needs help integrating mopro bindings into an existing app
- User asks about platform-specific setup (Xcode, Android Studio, Flutter, RN)
- User wants to generate/verify proofs in their app code
- User encounters app integration errors

## Two Modes

### Mode 1: Template (Quick Start)

Use `mopro create` to generate a starter app. This is the fastest path.

```bash
mopro create --framework <framework>
```

The template includes:
- Pre-configured project with mopro bindings
- Example proof generation/verification using default circuits
- Platform-specific boilerplate already set up

### Mode 2: Custom Integration

For users who have an existing app or want to build from a description,
guide them through manual integration:

1. Copy bindings to their project
2. Configure project settings (dependencies, build config)
3. Write proof generation/verification code
4. Handle circuit inputs and proof results

## Platform Workflow

Regardless of platform, the integration follows this pattern:

1. **Copy bindings** from the mopro build output to the app project
2. **Add dependencies** (JNA for Android, flutter_rust_bridge for Flutter, etc.)
3. **Place circuit artifacts** (.zkey, .bin, .json) as app assets
4. **Import bindings** in app code
5. **Call prove/verify functions** with circuit inputs
6. **Display results** in the UI

## Platform-Specific Guides

For detailed integration instructions, see the reference guides:

- **iOS (Swift)**: references/ios-guide.md
- **Android (Kotlin)**: references/android-guide.md
- **Flutter (Dart)**: references/flutter-guide.md
- **React Native (TypeScript)**: references/react-native-guide.md
- **Web (JavaScript/WASM)**: references/web-guide.md

## API Functions (Cross-Platform)

All platforms expose the same core functions with platform-specific naming:

### Circom Proofs
```
generateCircomProof(zkeyPath, circuitInputs, proofLib) → ProofResult
verifyCircomProof(zkeyPath, proofResult, proofLib) → Boolean
```

### Halo2 Proofs
```
generateHalo2Proof(name, srsKey, provingKey, input) → ProofResult
verifyHalo2Proof(name, srsKey, verifyingKey, proof) → Boolean
```

### Circuit Input Format
All inputs are JSON strings with flat, one-dimensional arrays:
```json
{"a": ["3"], "b": ["5"]}
```

Values are always string arrays, even for single values.

### ProofLib Enum
Platform-specific casing:
- Swift: `ProofLib.arkworks`
- Kotlin: `ProofLib.ARKWORKS`
- React Native: `ProofLib.Arkworks`
- Dart: `ProofLib.arkworks`

## Custom App Generation

When the user describes an app they want to build (e.g., "a ZK voting app"),
follow this process:

1. **Identify the circuit**: What is being proved? (identity, vote, credential)
2. **Choose the platform**: iOS, Android, Flutter, RN, or Web
3. **Start from template**: Use `mopro create` as the base
4. **Modify the UI**: Build the user-facing interface
5. **Wire up circuits**: Connect the custom circuit inputs to the proof functions
6. **Add verification**: Display proof status to the user

Always start from the mopro template and modify, rather than building from scratch.

## Troubleshooting

For common app integration errors, see references/troubleshooting.md.

Key issues:
1. Xcode signing/provisioning errors
2. Android Gradle sync failures
3. Missing jniLibs or .so files
4. Circuit asset not found at runtime
5. Flutter code shrinking breaking JNA
