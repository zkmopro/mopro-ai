# iOS Integration Guide

Complete guide for integrating mopro ZK bindings into an iOS app using Swift.

## Prerequisites

- Xcode 15+ with command-line tools configured
- Completed `mopro build --platforms ios` producing `MoproiOSBindings/`

The bindings directory contains:
- `mopro.swift` — generated Swift bindings
- `MoproBindings.xcframework` — universal framework with per-architecture slices

## Quick Start (Template)

```bash
mopro create --framework ios
```

Opens a ready-to-run Xcode project with example proof generation.

## Manual Integration

### Step 1: Create Xcode Project

File > New > Project > iOS > App. Use **Swift** and **SwiftUI**.

### Step 2: Add Bindings

Drag the entire `MoproiOSBindings` folder from Finder into the Xcode project
navigator. When prompted:
- Check "Copy items if needed"
- Select "Create folder references"
- Add to your app target

Xcode should automatically detect the `.xcframework` and add it to
"Frameworks, Libraries, and Embedded Content" in the target's General tab.

### Step 3: Add Circuit Assets

Drag `.zkey` files (or other circuit artifacts) into the Xcode project.

Then add them to Copy Bundle Resources:
1. Select your target > Build Phases
2. Expand "Copy Bundle Resources"
3. Click "+" and add each `.zkey` / `.bin` / `.json` file

### Step 4: Import and Use Bindings

In your Swift file:

```swift
import SwiftUI

struct ContentView: View {
    @State private var proofResult: String = "Ready"
    @State private var isProving: Bool = false

    // Load circuit asset path
    private var zkeyPath: String {
        Bundle.main.path(forResource: "multiplier2_final", ofType: "zkey") ?? ""
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Mopro ZK Prover")
                .font(.title)

            Button(isProving ? "Proving..." : "Generate Proof") {
                generateProof()
            }
            .disabled(isProving)

            Text(proofResult)
                .font(.caption)
                .padding()
        }
        .padding()
    }

    func generateProof() {
        isProving = true
        proofResult = "Generating proof..."

        DispatchQueue.global(qos: .userInitiated).async {
            let inputStr = "{\"a\":[\"3\"],\"b\":[\"5\"]}"
            let start = CFAbsoluteTimeGetCurrent()

            do {
                let result = try generateCircomProof(
                    zkeyPath: zkeyPath,
                    circuitInputs: inputStr,
                    proofLib: ProofLib.arkworks
                )
                let elapsed = CFAbsoluteTimeGetCurrent() - start

                DispatchQueue.main.async {
                    proofResult = "Proof generated in \(String(format: "%.3f", elapsed))s"
                    isProving = false
                }
            } catch {
                DispatchQueue.main.async {
                    proofResult = "Error: \(error)"
                    isProving = false
                }
            }
        }
    }
}
```

### Step 5: Verify Proofs

```swift
func verifyProof(zkeyPath: String, proofResult: GenerateProofResult) {
    do {
        let isValid = try verifyCircomProof(
            zkeyPath: zkeyPath,
            proofResult: proofResult,
            proofLib: ProofLib.arkworks
        )
        print("Proof valid: \(isValid)")
    } catch {
        print("Verification error: \(error)")
    }
}
```

## Halo2 Proofs (iOS)

```swift
func generateHalo2Proof() {
    let name = "plonk_fibonacci"
    guard let srsPath = Bundle.main.path(forResource: "plonk_fibonacci_srs", ofType: "bin"),
          let pkPath = Bundle.main.path(forResource: "plonk_fibonacci_pk", ofType: "bin") else {
        return
    }

    let srsData = try! Data(contentsOf: URL(fileURLWithPath: srsPath))
    let pkData = try! Data(contentsOf: URL(fileURLWithPath: pkPath))
    let input: [String: [String]] = ["in": ["1", "1"]]

    // Generate proof using Halo2 API
    let proof = try! generateHalo2Proof(
        name: name,
        srsKey: [UInt8](srsData),
        provingKey: [UInt8](pkData),
        input: input
    )
}
```

## Updating Bindings

After modifying circuits and rebuilding:

```bash
mopro build --platforms ios --mode release
mopro update --src ./MoproiOSBindings --dest ../MyiOSApp
```

Or manually: delete the old `MoproiOSBindings` folder in Xcode and re-add the
new one.

## Multiple Bindings

To use multiple circuit bindings in one app (avoiding duplicate symbol errors):

1. For each binding, create a separate static-library target:
   File > New > Target > iOS > Static Library
2. Add each `MoproBindings.xcframework` to its own static-library target
3. Import the static libraries from your main app target

This isolates the symbols and prevents linker conflicts.

## Performance Notes

Proof generation benchmarks (iPhone 16 Pro):
- Keccak256 (Circom): ~630ms
- RSA (Circom): ~749ms
- Semaphore-32 (Circom): ~143ms

Always run proof generation on a background thread (`DispatchQueue.global`)
to avoid blocking the UI.

## Common Issues

### "No such module" error
Ensure `MoproBindings.xcframework` appears in target > General >
Frameworks, Libraries, and Embedded Content.

### Asset not found at runtime
Verify the `.zkey` file is in Copy Bundle Resources (Build Phases).
Check the file name matches exactly (case-sensitive).

### Signing errors
Select your development team in target > Signing & Capabilities.
For testing on simulator, signing is not required.

### Slow proof on simulator
Simulator proofs are slower than physical device. This is expected.
Use a physical device for performance testing.
