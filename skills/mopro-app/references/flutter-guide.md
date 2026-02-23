# Flutter Integration Guide

Complete guide for integrating mopro ZK bindings into a Flutter app using Dart.

## Prerequisites

- Flutter SDK 3.0.0+
- Completed `mopro build --platforms flutter` producing `mopro_flutter_bindings/`

Platform-specific requirements:
- **Android**: minSdk 24, compileSdk 34, targetSdk 34, JNA 5.13.0
- **iOS**: Xcode 15+ with command-line tools

## Quick Start (Template)

```bash
mopro create --framework flutter
```

Generates a ready-to-run Flutter project.

## Manual Integration

### Step 1: Create Flutter Project

```bash
flutter create my_zk_app
cd my_zk_app
```

### Step 2: Copy Bindings

Copy the `mopro_flutter_bindings` folder into your project root:

```bash
cp -r /path/to/mopro_project/mopro_flutter_bindings ./
```

### Step 3: Update pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  mopro_flutter_plugin:
    path: ./mopro_flutter_bindings

flutter:
  assets:
    - assets/multiplier2_final.zkey
```

Create the assets directory and copy circuit files:
```bash
mkdir -p assets
cp /path/to/test-vectors/circom/multiplier2_final.zkey assets/
```

Run `flutter pub get` to install dependencies.

### Step 4: Configure Android Build

In `android/app/build.gradle`:

```gradle
android {
    compileSdk 34

    defaultConfig {
        minSdk 24
        targetSdk 34
    }

    buildTypes {
        release {
            // CRITICAL: Disable code shrinking for JNA compatibility
            minifyEnabled false
            shrinkResources false
        }
    }
}

dependencies {
    implementation("net.java.dev.jna:jna:5.13.0@aar")
}
```

### Step 5: Initialize RustLib

In `lib/main.dart`, initialize the Rust bridge before running the app:

```dart
import 'package:flutter/material.dart';
import 'package:mopro_flutter_bindings/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}
```

### Step 6: Generate and Verify Proofs

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mopro_flutter_bindings/src/rust/third_party/mopro_example_app.dart';

class ProofService {
  /// Copy asset to temporary directory and return the file path
  static Future<String> getAssetPath(String assetName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$assetName');
    if (!file.existsSync()) {
      final data = await rootBundle.load('assets/$assetName');
      await file.writeAsBytes(data.buffer.asUint8List());
    }
    return file.path;
  }

  /// Generate a Circom proof
  static Future<ProofResult> prove(String zkeyAsset, Map<String, List<String>> inputs) async {
    final zkeyPath = await getAssetPath(zkeyAsset);
    final inputStr = _mapToJsonString(inputs);

    return await generateCircomProof(
      zkeyPath: zkeyPath,
      circuitInputs: inputStr,
      proofLib: ProofLib.arkworks,
    );
  }

  /// Verify a Circom proof
  static Future<bool> verify(String zkeyAsset, ProofResult proofResult) async {
    final zkeyPath = await getAssetPath(zkeyAsset);

    return await verifyCircomProof(
      zkeyPath: zkeyPath,
      proofResult: proofResult,
      proofLib: ProofLib.arkworks,
    );
  }

  static String _mapToJsonString(Map<String, List<String>> map) {
    final entries = map.entries.map((e) {
      final values = e.value.map((v) => '"$v"').join(',');
      return '"${e.key}":[$values]';
    }).join(',');
    return '{$entries}';
  }
}
```

### Step 7: Build the UI

```dart
import 'package:flutter/material.dart';

class ProofScreen extends StatefulWidget {
  const ProofScreen({super.key});

  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  String _result = 'Ready';
  bool _isProving = false;

  Future<void> _generateProof() async {
    setState(() {
      _isProving = true;
      _result = 'Generating proof...';
    });

    try {
      final stopwatch = Stopwatch()..start();

      final proof = await ProofService.prove(
        'multiplier2_final.zkey',
        {'a': ['3'], 'b': ['5']},
      );

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;

      final valid = await ProofService.verify('multiplier2_final.zkey', proof);

      setState(() {
        _result = 'Proof generated in ${elapsed}ms\nValid: $valid';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mopro ZK Prover')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isProving ? null : _generateProof,
              child: Text(_isProving ? 'Proving...' : 'Generate Proof'),
            ),
            const SizedBox(height: 24),
            Text(_result, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
```

## Critical Warnings

### Avoid `*const ::std::ffi::c_void` Types

If your `lib.rs` uses macros that produce `*const ::std::ffi::c_void` types,
flutter_rust_bridge will fail to generate bindings.

**Fix:** Wrap problematic macros in a private module and expose only safe
public functions:

```rust
mod private {
    // Macro that produces c_void types
    set_circom_circuits! { ... }
}

pub fn my_safe_prove(input: String) -> Result<ProofResult, Error> {
    private::prove(input)
}
```

### Release Build Code Shrinking

Android release builds MUST disable minification:

```gradle
buildTypes {
    release {
        minifyEnabled false
        shrinkResources false
    }
}
```

Without this, R8/ProGuard strips JNA classes and proofs will crash at runtime.

## Running

```bash
flutter run                    # Debug on connected device/simulator
flutter run --release          # Release build (test JNA compatibility)
flutter run -d <device_id>     # Specific device
```

## Reference

Full implementation examples: https://github.com/zkmopro/flutter-app

## Common Issues

### "RustLib not initialized"
Ensure `await RustLib.init()` is called in `main()` before `runApp()`.

### Asset not found
Verify the asset is listed in `pubspec.yaml` under `flutter: assets:` and
run `flutter pub get`.

### Android build fails with JNA error
Add `implementation("net.java.dev.jna:jna:5.13.0@aar")` to Android dependencies.

### Release build crashes
Disable code shrinking in `android/app/build.gradle` (see Critical Warnings).

### iOS build fails
Run `cd ios && pod install` after adding the flutter plugin dependency.
