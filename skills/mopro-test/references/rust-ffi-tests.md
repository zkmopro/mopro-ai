# Rust and FFI Testing Guide

Patterns for testing mopro projects at the Rust and FFI binding levels.

## Rust Unit Tests

### Basic Proof Generation Test

Create `tests/proof_test.rs` in your mopro project:

```rust
#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    #[test]
    fn test_circom_proof_generation() {
        let zkey_path = "./test-vectors/circom/multiplier2_final.zkey";
        let input_str = r#"{"a":["3"],"b":["5"]}"#;

        let result = mopro_ffi::circom::generate_circom_proof(
            zkey_path,
            input_str,
            mopro_ffi::circom::ProofLib::Arkworks,
        );

        assert!(result.is_ok(), "Proof generation failed: {:?}", result.err());

        let proof_result = result.unwrap();
        assert!(!proof_result.proof.is_empty(), "Proof should not be empty");
    }

    #[test]
    fn test_circom_proof_verification() {
        let zkey_path = "./test-vectors/circom/multiplier2_final.zkey";
        let input_str = r#"{"a":["3"],"b":["5"]}"#;

        let proof_result = mopro_ffi::circom::generate_circom_proof(
            zkey_path,
            input_str,
            mopro_ffi::circom::ProofLib::Arkworks,
        )
        .expect("Failed to generate proof");

        let is_valid = mopro_ffi::circom::verify_circom_proof(
            zkey_path,
            &proof_result,
            mopro_ffi::circom::ProofLib::Arkworks,
        );

        assert!(is_valid.is_ok(), "Verification failed: {:?}", is_valid.err());
        assert!(is_valid.unwrap(), "Proof should be valid");
    }

    #[test]
    fn test_circom_invalid_input() {
        let zkey_path = "./test-vectors/circom/multiplier2_final.zkey";
        let invalid_input = r#"{"invalid":["key"]}"#;

        let result = mopro_ffi::circom::generate_circom_proof(
            zkey_path,
            invalid_input,
            mopro_ffi::circom::ProofLib::Arkworks,
        );

        assert!(result.is_err(), "Should fail with invalid input");
    }

    #[test]
    fn test_missing_zkey_file() {
        let result = mopro_ffi::circom::generate_circom_proof(
            "./nonexistent.zkey",
            r#"{"a":["1"]}"#,
            mopro_ffi::circom::ProofLib::Arkworks,
        );

        assert!(result.is_err(), "Should fail with missing zkey file");
    }
}
```

### Halo2 Proof Tests

```rust
#[cfg(test)]
mod halo2_tests {
    #[test]
    fn test_halo2_proof_generation() {
        let srs_path = "./test-vectors/halo2/plonk_fibonacci_srs.bin";
        let pk_path = "./test-vectors/halo2/plonk_fibonacci_pk.bin";
        let vk_path = "./test-vectors/halo2/plonk_fibonacci_vk.bin";

        let srs = std::fs::read(srs_path).expect("Failed to read SRS");
        let pk = std::fs::read(pk_path).expect("Failed to read PK");

        let mut input = std::collections::HashMap::new();
        input.insert("in".to_string(), vec!["1".to_string(), "1".to_string()]);

        let proof = mopro_ffi::halo2::generate_halo2_proof(
            "plonk_fibonacci",
            &srs,
            &pk,
            &input,
        );

        assert!(proof.is_ok(), "Halo2 proof failed: {:?}", proof.err());
    }
}
```

### Running Rust Tests

```bash
# Run all tests
cargo test

# Run with all features enabled
cargo test --all-features

# Run specific test
cargo test test_circom_proof_generation

# Run with output (see println! in tests)
cargo test -- --nocapture

# Run tests for a specific adapter
cargo test --features circom
cargo test --features halo2
```

## FFI Binding Tests

FFI tests verify the UniFFI-generated bindings work correctly across the
language boundary.

### Swift FFI Test (iOS)

After building iOS bindings, create a test in your Xcode project:

```swift
import XCTest

class MoproFFITests: XCTestCase {

    func testCircomProofGeneration() throws {
        let zkeyPath = Bundle(for: type(of: self))
            .path(forResource: "multiplier2_final", ofType: "zkey")!

        let input = "{\"a\":[\"3\"],\"b\":[\"5\"]}"

        let result = try generateCircomProof(
            zkeyPath: zkeyPath,
            circuitInputs: input,
            proofLib: ProofLib.arkworks
        )

        XCTAssertFalse(result.proof.isEmpty, "Proof should not be empty")
    }

    func testCircomProofVerification() throws {
        let zkeyPath = Bundle(for: type(of: self))
            .path(forResource: "multiplier2_final", ofType: "zkey")!

        let input = "{\"a\":[\"3\"],\"b\":[\"5\"]}"

        let proofResult = try generateCircomProof(
            zkeyPath: zkeyPath,
            circuitInputs: input,
            proofLib: ProofLib.arkworks
        )

        let isValid = try verifyCircomProof(
            zkeyPath: zkeyPath,
            proofResult: proofResult,
            proofLib: ProofLib.arkworks
        )

        XCTAssertTrue(isValid, "Proof should be valid")
    }
}
```

### Kotlin FFI Test (Android)

Create an instrumented test in `app/src/androidTest/`:

```kotlin
package com.example.myzkapp

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import uniffi.mopro.*
import java.io.File
import java.io.FileOutputStream

@RunWith(AndroidJUnit4::class)
class MoproFFITest {

    private lateinit var context: Context
    private lateinit var zkeyPath: String

    @Before
    fun setUp() {
        context = InstrumentationRegistry.getInstrumentation().targetContext
        zkeyPath = copyAsset("multiplier2_final.zkey")
    }

    @Test
    fun testCircomProofGeneration() {
        val input = "{\"a\":[\"3\"],\"b\":[\"5\"]}"

        val result = generateCircomProof(zkeyPath, input, ProofLib.ARKWORKS)

        assertNotNull("Proof result should not be null", result)
    }

    @Test
    fun testCircomProofVerification() {
        val input = "{\"a\":[\"3\"],\"b\":[\"5\"]}"

        val proofResult = generateCircomProof(zkeyPath, input, ProofLib.ARKWORKS)
        val isValid = verifyCircomProof(zkeyPath, proofResult, ProofLib.ARKWORKS)

        assertTrue("Proof should be valid", isValid)
    }

    private fun copyAsset(name: String): String {
        val file = File(context.filesDir, name)
        if (!file.exists()) {
            context.assets.open(name).use { input ->
                FileOutputStream(file).use { output ->
                    input.copyTo(output)
                }
            }
        }
        return file.absolutePath
    }
}
```

### WASM FFI Test

Test WASM bindings using wasm-pack:

```bash
wasm-pack test --chrome --headless -- --no-default-features --features wasm
```

Or create a JavaScript test file:

```javascript
// test_mopro.js
import { generateCircomProof, verifyCircomProof, initThreadPool } from "./MoproWasmBindings/mopro_wasm_lib.js";

async function runTests() {
    await initThreadPool(navigator.hardwareConcurrency);

    // Test proof generation
    const zkey = await fetch("./assets/multiplier2_final.zkey")
        .then(r => r.arrayBuffer())
        .then(b => new Uint8Array(b));

    const inputs = JSON.stringify({ a: ["3"], b: ["5"] });
    const proof = await generateCircomProof(zkey, inputs);
    console.assert(proof !== null, "Proof should not be null");

    // Test verification
    const valid = await verifyCircomProof(zkey, proof);
    console.assert(valid === true, "Proof should be valid");

    console.log("All WASM FFI tests passed");
}

runTests().catch(console.error);
```

## Code Quality Checks

```bash
# Format check
cargo fmt --all -- --check

# Lint check
cargo clippy --all-targets --all-features

# Format and fix
cargo fmt --all
```

## CI Configuration Example

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  rust-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: cargo test --all-features
      - run: cargo fmt --all -- --check
      - run: cargo clippy --all-targets --all-features -- -D warnings
```
