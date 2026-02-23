# Mobile UI Testing Guide

Platform-specific UI test patterns for mopro-integrated apps.

## iOS: XCTest / XCUITest

### Unit Test (XCTest)

Test proof logic without UI in `MyAppTests.swift`:

```swift
import XCTest
@testable import MyApp

class ProofTests: XCTestCase {

    func testProofGenerationPerformance() throws {
        let zkeyPath = Bundle.main.path(forResource: "multiplier2_final", ofType: "zkey")!
        let input = "{\"a\":[\"3\"],\"b\":[\"5\"]}"

        measure {
            do {
                let _ = try generateCircomProof(
                    zkeyPath: zkeyPath,
                    circuitInputs: input,
                    proofLib: ProofLib.arkworks
                )
            } catch {
                XCTFail("Proof generation failed: \(error)")
            }
        }
    }

    func testProofWithDifferentInputs() throws {
        let zkeyPath = Bundle.main.path(forResource: "multiplier2_final", ofType: "zkey")!

        let testCases = [
            ("{\"a\":[\"3\"],\"b\":[\"5\"]}", true),
            ("{\"a\":[\"0\"],\"b\":[\"0\"]}", true),
            ("{\"a\":[\"1\"],\"b\":[\"1\"]}", true),
        ]

        for (input, shouldSucceed) in testCases {
            let result = try? generateCircomProof(
                zkeyPath: zkeyPath,
                circuitInputs: input,
                proofLib: ProofLib.arkworks
            )

            if shouldSucceed {
                XCTAssertNotNil(result, "Should succeed for input: \(input)")
            }
        }
    }
}
```

### UI Test (XCUITest)

Test the full UI flow in `MyAppUITests.swift`:

```swift
import XCTest

class ProofUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }

    func testProveButtonGeneratesProof() {
        let proveButton = app.buttons["Generate Proof"]
        XCTAssertTrue(proveButton.exists)

        proveButton.tap()

        // Wait for proof generation (can take several seconds)
        let resultText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Proof generated'")
        ).firstMatch

        XCTAssertTrue(
            resultText.waitForExistence(timeout: 30),
            "Proof result should appear within 30 seconds"
        )
    }
}
```

### Running iOS Tests

```bash
# From Xcode: Cmd+U to run all tests
# Or from command line:
xcodebuild test \
    -project MyApp.xcodeproj \
    -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

## Android: JUnit + Compose Testing

### Unit Test (JUnit)

Create in `app/src/test/java/com/example/myzkapp/`:

```kotlin
package com.example.myzkapp

import org.junit.Test
import org.junit.Assert.*

class ProofLogicTest {

    @Test
    fun testInputJsonFormat() {
        val inputs = mapOf("a" to listOf("3"), "b" to listOf("5"))
        val json = buildInputJson(inputs)
        assertEquals("{\"a\":[\"3\"],\"b\":[\"5\"]}", json)
    }

    private fun buildInputJson(inputs: Map<String, List<String>>): String {
        return inputs.entries.joinToString(",", "{", "}") { (key, values) ->
            "\"$key\":[${values.joinToString(",") { "\"$it\"" }}]"
        }
    }
}
```

### Instrumented Test (requires device/emulator)

Create in `app/src/androidTest/java/com/example/myzkapp/`:

```kotlin
package com.example.myzkapp

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import org.junit.Rule
import org.junit.Test

class ProofScreenTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun proveButtonExists() {
        composeTestRule.setContent {
            ProofScreen(context = androidx.test.platform.app.InstrumentationRegistry
                .getInstrumentation().targetContext)
        }

        composeTestRule.onNodeWithText("Generate Proof").assertIsDisplayed()
    }

    @Test
    fun proveButtonGeneratesResult() {
        composeTestRule.setContent {
            ProofScreen(context = androidx.test.platform.app.InstrumentationRegistry
                .getInstrumentation().targetContext)
        }

        composeTestRule.onNodeWithText("Generate Proof").performClick()

        // Wait for proof (long timeout for ZK computation)
        composeTestRule.waitUntil(timeoutMillis = 30_000) {
            composeTestRule.onAllNodesWithText("Proof generated", substring = true)
                .fetchSemanticsNodes().isNotEmpty()
        }
    }
}
```

### Running Android Tests

```bash
# Unit tests (no device needed)
./gradlew test

# Instrumented tests (requires emulator/device)
./gradlew connectedAndroidTest
```

## Flutter: Widget Tests + Integration Tests

### Widget Test

Create `test/proof_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_zk_app/proof_screen.dart';

void main() {
  testWidgets('Prove button is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProofScreen()));

    expect(find.text('Generate Proof'), findsOneWidget);
  });

  testWidgets('Prove button triggers proof generation', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProofScreen()));

    await tester.tap(find.text('Generate Proof'));
    await tester.pump();

    // Should show loading state
    expect(find.text('Proving...'), findsOneWidget);
  });
}
```

### Integration Test

Create `integration_test/proof_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_zk_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full proof generation flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Tap prove button
    await tester.tap(find.text('Generate Proof'));
    await tester.pump();

    // Wait for proof (long timeout)
    await tester.pumpAndSettle(const Duration(seconds: 30));

    // Verify result appears
    expect(find.textContaining('Proof generated'), findsOneWidget);
  });
}
```

### Running Flutter Tests

```bash
# Widget tests (no device needed)
flutter test

# Integration tests (requires device/emulator)
flutter test integration_test/proof_test.dart
```

## React Native: Jest + Detox

### Jest Unit Test

Create `__tests__/proof.test.ts`:

```typescript
import { generateCircomProof, verifyCircomProof, ProofLib } from "mopro-ffi";

// Mock the native module for unit tests
jest.mock("mopro-ffi", () => ({
    generateCircomProof: jest.fn().mockReturnValue({
        proof: "mock_proof_data",
        inputs: "mock_inputs",
    }),
    verifyCircomProof: jest.fn().mockReturnValue(true),
    ProofLib: { Arkworks: "arkworks" },
}));

describe("Proof Generation", () => {
    test("generates proof with valid inputs", () => {
        const result = generateCircomProof(
            "/path/to/zkey",
            JSON.stringify({ a: ["3"], b: ["5"] }),
            ProofLib.Arkworks
        );

        expect(result).toBeDefined();
        expect(result.proof).toBeTruthy();
    });

    test("verifies generated proof", () => {
        const proof = generateCircomProof(
            "/path/to/zkey",
            JSON.stringify({ a: ["3"], b: ["5"] }),
            ProofLib.Arkworks
        );

        const valid = verifyCircomProof("/path/to/zkey", proof, ProofLib.Arkworks);
        expect(valid).toBe(true);
    });
});
```

### Running React Native Tests

```bash
# Jest unit tests
npm test

# E2E tests with Detox (if configured)
npx detox test --configuration ios.sim.debug
```

## Test Timeouts

ZK proof generation is slow. Set appropriate timeouts:

| Platform | Test Framework | Timeout Setting |
|---|---|---|
| iOS | XCTest | `waitForExistence(timeout: 30)` |
| Android | Compose | `waitUntil(timeoutMillis = 30_000)` |
| Flutter | integration_test | `pumpAndSettle(Duration(seconds: 30))` |
| React Native | Jest | `jest.setTimeout(30000)` |
| Web | Mocha/Jest | `this.timeout(30000)` or `jest.setTimeout(30000)` |

## Best Practices

1. **Test Rust first**: Fastest feedback loop, no mobile toolchain needed
2. **Use known test vectors**: multiplier2 with `a=3, b=5` → expected output 15
3. **Separate proving from UI**: Keep proof logic in a service layer for testability
4. **Background threads**: Always test that proof generation runs off the main thread
5. **Error paths**: Test with invalid inputs, missing files, wrong ProofLib
6. **Performance tests**: Use `measure {}` (iOS) or benchmarking tools to track regressions
