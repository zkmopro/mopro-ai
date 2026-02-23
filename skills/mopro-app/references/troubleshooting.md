# App Integration Troubleshooting

Top app integration errors across all platforms with diagnosis and fixes.

## 1. Xcode Signing / Provisioning Errors (iOS)

**Symptoms:**
- "Signing requires a development team"
- "No profiles for ... were found"
- "Code signing is required for product type 'Application'"

**Fix:**
1. Select your target in Xcode
2. Go to Signing & Capabilities
3. Check "Automatically manage signing"
4. Select your development team

For simulator testing, signing is not required. These errors only matter for
physical devices.

## 2. Android Gradle Sync Failure

**Symptoms:**
- "Failed to resolve: net.java.dev.jna:jna"
- Gradle sync hangs or fails
- "Could not find com.android.tools.build:gradle"

**Fix:**
Ensure JNA is added with the `@aar` suffix in `app/build.gradle.kts`:
```kotlin
implementation("net.java.dev.jna:jna:5.13.0@aar")
```

Also verify:
- Android Studio is up to date
- Gradle wrapper version matches project requirements
- File > Sync Project with Gradle Files

## 3. Missing jniLibs / .so Files (Android)

**Symptoms:**
- `java.lang.UnsatisfiedLinkError: dlopen failed`
- "couldn't find libuniffi_mopro.so"
- App crashes immediately on proof generation

**Fix:**
Verify the directory structure:
```
app/src/main/jniLibs/
├── arm64-v8a/libuniffi_mopro.so      # Physical device (64-bit)
├── x86_64/libuniffi_mopro.so         # Emulator (64-bit)
└── (other architectures as needed)
```

The architecture must match the running device:
- Emulator (default): needs `x86_64`
- Physical device: needs `arm64-v8a`

If `.so` files are missing, rebuild with the correct architecture:
```bash
mopro build --platforms android --architectures x86_64-linux-android
```

## 4. Circuit Asset Not Found at Runtime

**Symptoms:**
- "File not found" when trying to generate proof
- `zkeyPath` is null or empty
- Crash on `Bundle.main.path(forResource:)` returning nil

### iOS Fix
Ensure the `.zkey` file is added to Copy Bundle Resources:
1. Target > Build Phases > Copy Bundle Resources
2. Click "+" and add the file
3. Verify file name matches exactly (case-sensitive)

### Android Fix
Ensure the file is in `app/src/main/assets/` (not `res/raw/`).
Use the `copyAssetToInternalStorage()` helper to copy to internal storage.

### Flutter Fix
Add the asset to `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/multiplier2_final.zkey
```
Then run `flutter pub get`.

### React Native Fix
Use `react-native-fs` to access assets. Strip `file://` prefix from paths.

## 5. Flutter Release Build Crashes (JNA)

**Symptoms:**
- Release build crashes but debug works fine
- `java.lang.NoClassDefFoundError: com/sun/jna/...`
- Proof generation throws runtime exception in release mode

**Fix:**
Disable code shrinking in `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        minifyEnabled false
        shrinkResources false
    }
}
```

R8/ProGuard strips JNA classes during code shrinking, breaking the native bridge.

## 6. Flutter `c_void` Type Error

**Symptoms:**
- `flutter_rust_bridge` codegen fails
- Error mentions `*const ::std::ffi::c_void`
- Build fails during Dart binding generation

**Fix:**
Wrap macros that produce `c_void` types in a private module:

```rust
mod private {
    use mopro_ffi::circom;
    circom::set_circom_circuits! {
        ("circuit_final.zkey", circom::witness::witnesscalc::circuit::witness),
    }
}

// Expose safe public functions instead
pub fn prove(input: String) -> Result<ProofResult, Error> {
    private::prove(input)
}
```

## 7. iOS Duplicate Symbol Errors

**Symptoms:**
- "duplicate symbol '_uniffi_...' in..."
- Linker error when using multiple bindings in one app

**Fix:**
Isolate each binding in a separate static-library target:
1. File > New > Target > iOS > Static Library
2. Add each `.xcframework` to its own target
3. Import static libraries from the main app target

## 8. React Native Turbo Module Not Found

**Symptoms:**
- "uniffiInitAsync is not a function"
- Module import fails
- Metro bundler can't resolve "mopro-ffi"

**Fix:**
1. Verify React Native version is 0.82+ (`npx react-native --version`)
2. Check workspace config in `package.json`
3. Verify `metro.config.js` includes monorepo watch folders
4. Run `npm install` after workspace changes
5. For iOS: `cd ios && pod install`

## 9. Android Import Name Mismatch

**Symptoms:**
- `Unresolved reference: uniffi`
- Kotlin compilation error

**Fix:**
Hyphens in the Rust crate name become underscores in Kotlin:
```kotlin
// Crate name: my-zk-app
import uniffi.my_zk_app.*  // CORRECT: underscores

// NOT:
import uniffi.my-zk-app.*  // WRONG: hyphens cause syntax error
```

Check the `package` declaration in the generated `mopro.kt` for the exact name.

## 10. WASM SharedArrayBuffer Error (Web)

**Symptoms:**
- "SharedArrayBuffer is not defined"
- `initThreadPool` throws an error
- Proofs run in single-threaded mode (very slow)

**Fix:**
Add COOP/COEP headers to your web server:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

These headers enable `SharedArrayBuffer` which is required for multi-threaded
WASM execution. Without them, `wasm-bindgen-rayon` can't create worker threads.

## General Debugging Approach

1. **Verify bindings exist**: Check that the build output directory has files
2. **Check architecture match**: Device arch must match built `.so` / `.xcframework`
3. **Check asset paths**: Circuit files must be accessible at runtime
4. **Check imports**: Package names must match exactly (watch for hyphens vs underscores)
5. **Check dependencies**: JNA for Android, CocoaPods for iOS, etc.
6. **Try debug mode first**: Release mode adds code shrinking that can break things
7. **Check logs**: Xcode console, Android logcat, Metro bundler, browser console
