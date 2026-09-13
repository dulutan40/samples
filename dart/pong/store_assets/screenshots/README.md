# Store screenshots

**Generated frames** (committed PNGs) live under `iphone_6_7/`, `ipad_12_9/`, `mac_16_10/`, and `android_phone/`. They are **marketing placeholders** in Pong brand colors; swap them for **real captures** from the running app before production submission if you want authentic UI.

Regenerate placeholders from repo root:

```bash
dart run tool/gen_store_screenshots.dart
```

---

For **device-accurate** shots:

1. Run the app on the target device size (Simulator / Emulator).
2. Navigate to the screen (Home, Game, Online lobby, Profile, etc.).
3. Capture:
   - **iOS**: `Cmd+S` in Simulator, or `xcrun simctl io booted screenshot file.png`
   - **Android**: Emulator camera icon, or `adb exec-out screencap -p > file.png`
4. Crop/resize to the exact pixel sizes listed in [`../README.md`](../README.md).
5. Upload to App Store Connect and Play Console.

For a scripted iOS flow, see `../../tool/capture_ios_screenshots.sh`.
