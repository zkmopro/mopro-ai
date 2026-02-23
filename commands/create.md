---
description: Generate a starter app template from mopro bindings (iOS, Android, Flutter, React Native, Web)
argument-hint: "[framework]"
allowed-tools: Bash, Read, Write, Glob
---

# /mopro:create

Generate a starter app template with integrated mopro bindings.

## Arguments

- `$1` (optional): App framework: `ios`, `android`, `flutter`, `react-native`, `web`

## Instructions

1. If framework is not provided, ask the user which framework they want.

2. Verify we're in a mopro project with completed build output:
```bash
ls Cargo.toml src/lib.rs
```

Then check for the corresponding bindings directory:
- iOS: `ls MoproiOSBindings/`
- Android: `ls MoproAndroidBindings/`
- Flutter: `ls mopro_flutter_bindings/`
- React Native: `ls MoproReactNativeBindings/`
- Web: `ls MoproWasmBindings/`

If bindings don't exist, inform the user they need to run `mopro build` first.
Do NOT chain build + create automatically.

3. Confirm before running:
```
About to run: mopro create --framework <framework>
This will generate a <framework> app template in the current directory.
Proceed?
```

4. Run create:
```bash
mopro create --framework $1
```

5. After completion, list the generated app directory and summarize:
   - What was created
   - How to open/run the project:
     - iOS: Open `.xcodeproj` in Xcode, select simulator, run
     - Android: Open in Android Studio, sync Gradle, run
     - Flutter: `cd <app_dir> && flutter run`
     - React Native: `cd <app_dir> && npm install && npm run ios`
     - Web: `cd <app_dir> && npm install && npm start`

6. Mention that the template includes example proof generation using the
   default circuits. For custom circuits, they'll need to modify the app code.
