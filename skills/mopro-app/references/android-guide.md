# Android Integration Guide

Complete guide for integrating mopro ZK bindings into an Android app using Kotlin.

## Prerequisites

- Android Studio with SDK and NDK installed
- JDK 17+
- Completed `mopro build --platforms android` producing `MoproAndroidBindings/`

The bindings directory contains:
- `jniLibs/` — native libraries per architecture (`arm64-v8a/`, `x86_64/`, etc.)
- `uniffi/mopro/mopro.kt` — generated Kotlin bindings

## Quick Start (Template)

```bash
mopro create --framework android
```

Opens a ready-to-run Android Studio project.

## Manual Integration

### Step 1: Create Android Project

In Android Studio: File > New > New Project > Empty Activity.
Use Kotlin and Jetpack Compose. Switch to **Android** directory view.

### Step 2: Add JNA Dependency

In `app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("net.java.dev.jna:jna:5.13.0@aar")
    // ... other dependencies
}
```

Sync: File > Sync Project with Gradle Files.

### Step 3: Copy Bindings

```bash
# Copy native libraries
cp -r MoproAndroidBindings/jniLibs app/src/main/

# Copy Kotlin bindings
cp -r MoproAndroidBindings/uniffi app/src/main/java/
```

Verify the structure:
```
app/src/main/
├── jniLibs/
│   ├── arm64-v8a/
│   │   └── libuniffi_mopro.so
│   └── x86_64/
│       └── libuniffi_mopro.so
└── java/
    └── uniffi/
        └── mopro/
            └── mopro.kt
```

### Step 4: Add Circuit Assets

Create an assets folder: File > New > Folder > Assets Folder.

Place `.zkey`, `.bin`, or `.json` circuit files in `app/src/main/assets/`.

### Step 5: Asset Loader Helper

Android requires copying assets to internal storage before use:

```kotlin
import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

fun copyAssetToInternalStorage(context: Context, assetFileName: String): String? {
    val file = File(context.filesDir, assetFileName)
    if (file.exists()) return file.absolutePath

    return try {
        context.assets.open(assetFileName).use { inputStream ->
            FileOutputStream(file).use { outputStream ->
                val buffer = ByteArray(1024)
                var length: Int
                while (inputStream.read(buffer).also { length = it } > 0) {
                    outputStream.write(buffer, 0, length)
                }
                outputStream.flush()
            }
        }
        file.absolutePath
    } catch (e: IOException) {
        e.printStackTrace()
        null
    }
}
```

### Step 6: Generate and Verify Proofs

```kotlin
import uniffi.mopro.*  // Replace 'mopro' with your crate name if different
import androidx.compose.runtime.*
import kotlinx.coroutines.launch

@Composable
fun ProofScreen(context: Context) {
    val coroutineScope = rememberCoroutineScope()
    var result by remember { mutableStateOf("Ready") }
    var isProving by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Mopro ZK Prover", style = MaterialTheme.typography.headlineMedium)

        Spacer(modifier = Modifier.height(24.dp))

        Button(
            onClick = {
                isProving = true
                coroutineScope.launch {
                    val path = copyAssetToInternalStorage(context, "multiplier2_final.zkey")
                    path?.let { zkeyPath ->
                        try {
                            val inputStr = "{\"a\":[\"3\"],\"b\":[\"5\"]}"
                            val start = System.currentTimeMillis()

                            val proofResult = generateCircomProof(
                                zkeyPath,
                                inputStr,
                                ProofLib.ARKWORKS
                            )

                            val elapsed = System.currentTimeMillis() - start
                            result = "Proof generated in ${elapsed}ms"

                            // Verify
                            val valid = verifyCircomProof(
                                zkeyPath,
                                proofResult,
                                ProofLib.ARKWORKS
                            )
                            result += "\nValid: $valid"
                        } catch (e: Exception) {
                            result = "Error: ${e.message}"
                        }
                        isProving = false
                    }
                }
            },
            enabled = !isProving
        ) {
            Text(if (isProving) "Proving..." else "Generate Proof")
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(result)
    }
}
```

**Important:** The import uses `uniffi.mopro.*`. If your Rust crate name has
hyphens (e.g., `my-zk-app`), replace with underscores: `uniffi.my_zk_app.*`.

### Step 7: Wire Up in MainActivity

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MyAppTheme {
                ProofScreen(context = this)
            }
        }
    }
}
```

## Updating Bindings

```bash
mopro build --platforms android --mode release
mopro update --src ./MoproAndroidBindings --dest ../MyAndroidApp
```

If `mopro update` doesn't work (project outside mopro dir), manually repeat
the copy steps.

## Multiple Bindings

To use multiple circuit bindings in one Android app:

1. Rename each `mopro.kt` uniquely (e.g., `CircuitA.kt`, `CircuitB.kt`)
2. Change `package uniffi.mopro` to unique packages (e.g., `uniffi.circuit_a`)
3. Merge all `.so` files into the single `jniLibs/` directory (files must have
   unique names)
4. Import using the renamed packages

## Performance Notes

Proof generation benchmarks (Samsung S23 Ultra):
- Anon Aadhaar (Circom): ~3395ms
- RSA (Circom): ~950ms
- Keccak256 (Noir): ~1303ms

Always run proof generation in a coroutine to avoid blocking the main thread.

## Common Issues

### "java.lang.UnsatisfiedLinkError"
The `.so` files are missing or in the wrong directory. Verify:
```
app/src/main/jniLibs/<arch>/libuniffi_mopro.so
```
Architecture must match the running device/emulator.

### Gradle sync failure
Ensure JNA dependency is added correctly with `@aar` suffix:
```kotlin
implementation("net.java.dev.jna:jna:5.13.0@aar")
```

### Import not resolved
Check the package name in `mopro.kt` matches your import. Hyphens in the
crate name become underscores in Kotlin.

### Asset file not found
Ensure circuit files are in `app/src/main/assets/` (not `res/`).
The `copyAssetToInternalStorage` function copies from assets to internal storage.

### Emulator architecture mismatch
Default emulator uses `x86_64`. If you built only for `aarch64-linux-android`,
the `.so` won't load. Either:
- Rebuild with `--architectures x86_64-linux-android`
- Or use ARM emulator images
