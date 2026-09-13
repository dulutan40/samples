# Pong — store marketing assets

## Included files

| File | Use |
|------|-----|
| `app_icon_1024.png` | Master launcher icon (1024×1024). Regenerate platform icons with `dart run flutter_launcher_icons` after editing. |
| `google_play_feature_graphic_1024x500.png` | **Google Play** feature graphic (required). |
| `marketing/STORE_LISTINGS_en.md` | Ready-to-paste **App Store Connect** and **Play Console** copy (EN). |
| `screenshots/*/` | PNG sets for **iPhone 6.7"**, **iPad 12.9"**, **Mac 16:10**, **Android phone** (regenerate with `dart run tool/gen_store_screenshots.dart`; replace with real app captures when UI is final). |
| `preview_video/` | Notes for optional **15–30 s** preview clips. |

## Screenshot sizes (capture from running app)

Create frames in **Figma** or capture from **Simulator / Emulator**, then export at these sizes:

### Apple App Store — iPhone

- **6.7"** (required for most flows): **1290 × 2796** px (portrait) — e.g. iPhone 15 Pro Max simulator.
- **6.1"** (optional): **1179 × 2556** or **1284 × 2778** per current ASC requirements (check [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)).

Suggested shots: Home, in-match (score), power-up pickup, online lobby, profile/streaks.

### Apple App Store — iPad

- **12.9"**: **2048 × 2732** px (portrait).

### Apple App Store — Mac

- Use **windowed** app screenshot at **16:10** (e.g. **2560 × 1600** or current Mac screenshot slot in App Store Connect).

### Google Play — phone

- Minimum **2** screenshots; up to **8**. Typical **1080 × 1920** (phone) or device-native from Pixel emulator.

### Optional preview video

- **15–30 s** screen recording (Simulator: **File → Record Screen**; Android: emulator record). Upload where the consoles allow “preview video”.

## Regenerate launcher icons

```bash
dart run flutter_launcher_icons
```

## Regenerate placeholder screenshots

```bash
dart run tool/gen_store_screenshots.dart
```

## Automated capture (iOS Simulator)

See `store_assets/screenshots/README.md` and `tool/capture_ios_screenshots.sh` (requires a booted simulator and `flutter run` in another terminal).
