# React Native Integration Guide

Complete guide for integrating mopro ZK bindings into a React Native app using TypeScript.

## Prerequisites

- Node.js 20+
- React Native 0.82+ (Turbo Module support required)
- Completed `mopro build --platforms react-native` producing `MoproReactNativeBindings/`
- For iOS: Xcode 15+, CocoaPods
- For Android: Android Studio, JDK 17+, NDK

## Quick Start (Template)

```bash
mopro create --framework react-native
```

Generates a ready-to-run React Native project.

## Manual Integration

### Step 1: Create React Native Project

```bash
npx @react-native-community/cli@latest init MyZKApp --version 0.82
cd MyZKApp
```

### Step 2: Place Bindings

Copy the `MoproReactNativeBindings` folder into the project root:

```bash
cp -r /path/to/mopro_project/MoproReactNativeBindings ./
```

### Step 3: Configure Workspace

3a. Install monorepo config:
```bash
npm add react-native-monorepo-config
```

3b. Add workspace to `package.json`:
```json
{
  "private": true,
  "workspaces": [
    "MoproReactNativeBindings"
  ]
}
```

3c. Create `react-native.config.js` in project root:
```javascript
const {
  generators: { packages },
} = require("react-native-monorepo-config");

module.exports = {
  project: {
    ios: {},
    android: {},
  },
  dependencies: packages(),
};
```

3d. Update `metro.config.js`:
```javascript
const { resolve } = require("path");
const {
  metro: { watchFolders, nodeModulesPaths },
} = require("react-native-monorepo-config");

const { getDefaultConfig, mergeConfig } = require("@react-native/metro-config");

const defaultConfig = getDefaultConfig(__dirname);
const config = {
  watchFolders: watchFolders(),
  resolver: {
    nodeModulesPaths: nodeModulesPaths(),
  },
};

module.exports = mergeConfig(defaultConfig, config);
```

3e. Update `index.js` to initialize bindings before app registration:
```javascript
import { AppRegistry } from "react-native";
import App from "./App";
import { name as appName } from "./app.json";
import { uniffiInitAsync } from "mopro-ffi";

uniffiInitAsync().then(() => {
  AppRegistry.registerComponent(appName, () => App);
});
```

### Step 4: Install Dependencies

```bash
npm add react-native-fs
npm install
cd ios && pod install && cd ..
```

### Step 5: Add Circuit Assets

For iOS, add `.zkey` files to the Xcode project bundle resources.

For Android, place them in `android/app/src/main/assets/`.

Use `react-native-fs` to read asset paths at runtime.

### Step 6: Generate and Verify Proofs

```typescript
import {
  generateCircomProof,
  verifyCircomProof,
  CircomProofResult,
  ProofLib,
} from "mopro-ffi";
import RNFS from "react-native-fs";
import { Platform } from "react-native";

async function getZkeyPath(): Promise<string> {
  const filename = "multiplier2_final.zkey";

  if (Platform.OS === "ios") {
    return RNFS.MainBundlePath + "/" + filename;
  } else {
    // Android: copy from assets to document dir
    const destPath = RNFS.DocumentDirectoryPath + "/" + filename;
    if (!(await RNFS.exists(destPath))) {
      await RNFS.copyFileAssets(filename, destPath);
    }
    return destPath;
  }
}

async function prove(): Promise<CircomProofResult> {
  const zkeyPath = await getZkeyPath();
  const circuitInputs = { a: ["3"], b: ["5"] };

  const result: CircomProofResult = generateCircomProof(
    zkeyPath.replace("file://", ""),
    JSON.stringify(circuitInputs),
    ProofLib.Arkworks
  );

  return result;
}

async function verify(proofResult: CircomProofResult): Promise<boolean> {
  const zkeyPath = await getZkeyPath();

  const valid: boolean = verifyCircomProof(
    zkeyPath.replace("file://", ""),
    proofResult,
    ProofLib.Arkworks
  );

  return valid;
}
```

**Note:** React Native uses `ProofLib.Arkworks` (PascalCase).

### Step 7: Build and Run

Add scripts to `package.json`:
```json
{
  "scripts": {
    "assets": "npx react-native-asset",
    "prebuild": "npm run assets && cd ios && pod install && cd ..",
    "start": "react-native start",
    "ios": "npm run prebuild && react-native run-ios",
    "android": "npm run assets && react-native run-android"
  }
}
```

Run:
```bash
npm run start      # Start Metro bundler
npm run ios        # iOS simulator
npm run android    # Android emulator (ANDROID_HOME must be set)
```

### Step 8: Physical Device (iOS)

For physical iOS devices:
1. Open `ios/MyZKApp.xcworkspace` in Xcode
2. Select your device
3. Configure signing: Signing & Capabilities > Team
4. Build and run from Xcode

## Reference

Full implementation examples: https://github.com/zkmopro/react-native-app

## Common Issues

### "uniffiInitAsync is not a function"
Ensure `index.js` imports from `"mopro-ffi"` and the workspace is configured.
Run `npm install` after adding the workspace.

### CocoaPods install fails
```bash
cd ios
pod deintegrate
pod install
```

### Metro bundler can't find module
Verify `metro.config.js` includes `watchFolders` and `nodeModulesPaths` from
monorepo config.

### Android build fails
Ensure `ANDROID_HOME` is set and NDK is installed:
```bash
echo $ANDROID_HOME
ls $ANDROID_HOME/ndk/
```

### "file://" prefix in path
Always strip the `file://` prefix from asset paths before passing to mopro:
```typescript
zkeyPath.replace("file://", "")
```

### Turbo Module not found
React Native 0.82+ is required for Turbo Module support. Check your RN version:
```bash
npx react-native --version
```
