# Web/WASM Integration Guide

Complete guide for integrating mopro ZK bindings into a web application using
JavaScript and WebAssembly.

## Prerequisites

- Rust with `wasm32-unknown-unknown` target
- wasm-pack installed
- Chrome browser (for testing)
- Completed `mopro build --platforms web` producing `MoproWasmBindings/`

## Quick Start (Template)

```bash
mopro create --framework web
```

Generates a ready-to-run web project.

## Supported Proving Systems

- **Circom (Groth16)**: Fully supported
- **Halo2 (PSE)**: Supported with multithreading via `wasm-bindgen-rayon`
- **Noir (Barretenberg)**: **NOT supported** in WASM via Mopro

Only PSE Halo2 is compatible with `wasm-bindgen-rayon` for multi-threaded WASM.

## Manual Integration

### Step 1: Configure Rust for Halo2 (if using Halo2)

In your mopro project's `Cargo.toml`, add your Halo2 circuit dependency:

```toml
[dependencies]
mopro-ffi = { version = "0.3", features = ["halo2"] }
my-halo2-circuit = { git = "https://github.com/user/my-halo2-circuit.git" }
```

In `src/lib.rs`, register the circuit:

```rust
use mopro_ffi::halo2;

halo2::set_halo2_circuits! {
    ("my_circuit_pk.bin", my_halo2_circuit::prove,
     "my_circuit_vk.bin", my_halo2_circuit::verify),
}
```

### Step 2: Build WASM Bindings

```bash
rm -rf MoproWasmBindings
mopro build --platforms web --mode release --architectures wasm32-unknown-unknown
```

### Step 3: Set Up Web Project

Create a basic web project structure:

```
my-web-app/
├── index.html
├── main.js
├── assets/
│   ├── multiplier2_final.zkey    # Or your circuit artifacts
│   ├── plonk_fibonacci_srs.bin
│   └── plonk_fibonacci_pk.bin
└── MoproWasmBindings/            # Copied from mopro build output
    ├── mopro_wasm_lib.js
    └── mopro_wasm_lib_bg.wasm
```

### Step 4: Initialize WASM Module

```javascript
// main.js

// Import the WASM module
const mopro_wasm = await import("./MoproWasmBindings/mopro_wasm_lib.js");

// Initialize the WASM module
await mopro_wasm.default();

// CRITICAL: Initialize thread pool for multi-threaded proving
// Without this, Rayon falls back to single-core sequential execution
await mopro_wasm.initThreadPool(navigator.hardwareConcurrency);

console.log("WASM initialized with", navigator.hardwareConcurrency, "threads");
```

### Step 5: Helper - Fetch Binary Files

```javascript
async function fetchBinaryFile(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to load ${url}: ${response.statusText}`);
  }
  return new Uint8Array(await response.arrayBuffer());
}
```

### Step 6: Circom Proofs (Web)

```javascript
async function generateCircomProof() {
  const zkey = await fetchBinaryFile("./assets/multiplier2_final.zkey");
  const inputs = JSON.stringify({ a: ["3"], b: ["5"] });

  const start = performance.now();

  const proof = await mopro_wasm.generateCircomProof(zkey, inputs);

  const elapsed = (performance.now() - start).toFixed(1);
  console.log(`Proof generated in ${elapsed}ms`);

  return proof;
}

async function verifyCircomProof(proof) {
  const zkey = await fetchBinaryFile("./assets/multiplier2_final.zkey");

  const valid = await mopro_wasm.verifyCircomProof(zkey, proof);
  console.log("Proof valid:", valid);

  return valid;
}
```

### Step 7: Halo2 Proofs (Web)

```javascript
async function generateHalo2Proof() {
  const name = "plonk_fibonacci";
  const srsKey = await fetchBinaryFile("./assets/plonk_fibonacci_srs.bin");
  const provingKey = await fetchBinaryFile("./assets/plonk_fibonacci_pk.bin");
  const input = { in: ["1", "1"] };

  const start = performance.now();

  const proof = await mopro_wasm.generateHalo2Proof(
    name,
    srsKey,
    provingKey,
    input
  );

  const elapsed = (performance.now() - start).toFixed(1);
  console.log(`Halo2 proof generated in ${elapsed}ms`);

  return proof;
}

async function verifyHalo2Proof(proof) {
  const name = "plonk_fibonacci";
  const srsKey = await fetchBinaryFile("./assets/plonk_fibonacci_srs.bin");
  const verifyingKey = await fetchBinaryFile("./assets/plonk_fibonacci_vk.bin");

  const valid = await mopro_wasm.verifyHalo2Proof(
    name,
    srsKey,
    verifyingKey,
    proof
  );
  console.log("Halo2 proof valid:", valid);

  return valid;
}
```

### Step 8: HTML Setup

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Mopro ZK Web App</title>
  <!-- Required headers for SharedArrayBuffer (needed for multithreading) -->
  <meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">
  <meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">
</head>
<body>
  <h1>Mopro ZK Prover</h1>
  <button id="prove-btn">Generate Proof</button>
  <pre id="result">Ready</pre>
  <script type="module" src="main.js"></script>
</body>
</html>
```

**Critical:** The COOP/COEP headers are required for `SharedArrayBuffer`,
which enables multi-threaded WASM execution. Without these headers,
`initThreadPool` will fail.

### Step 9: Serve with Correct Headers

Use a dev server that supports these headers:

```bash
# Using npx serve (add serve.json for headers)
npx serve .
```

Create `serve.json`:
```json
{
  "headers": [
    {
      "source": "**/*",
      "headers": [
        { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
        { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" }
      ]
    }
  ]
}
```

Or use Python with a custom server script that adds the headers.

## Performance Notes

WASM proving benchmarks (MacBook Air M3):
- Keccak256 (Halo2): ~26.6s prove / 0.55s verify
- Keccak256 (Noir): ~4122ms (non-WASM path)
- RSA (Noir): ~2068ms (non-WASM path)

WASM is significantly slower than native mobile for ZK proving. Use it for
prototyping and web-only use cases.

## Common Issues

### "SharedArrayBuffer is not defined"
Add COOP/COEP headers to your web server (see Step 8).
Without them, multi-threading is disabled.

### Single-core performance
Call `initThreadPool(navigator.hardwareConcurrency)` after WASM init.
Without it, Rayon uses sequential single-core execution.

### WASM file not found
Verify the import path matches the actual location of `mopro_wasm_lib.js`.
Paths are relative to the importing file.

### Noir/Barretenberg proofs fail
Barretenberg does NOT compile to WASM via the Mopro stack.
Use Circom or Halo2 for web-based proving.

### Large WASM bundle size
WASM binaries for ZK provers can be 5-20MB. Consider:
- Lazy loading the WASM module
- Showing a loading indicator during initialization
- Caching the WASM binary with a service worker
