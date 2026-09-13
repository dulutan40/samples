# Pong — release, signing, and store submission

This project targets **iOS**, **iPadOS** (universal iOS build), **macOS**, **Android**, and **Web**. Marketing version is driven by [`pubspec.yaml`](../pubspec.yaml) (`version: 0.0.1+1` → name `0.0.1`, build `1`).

## Quick links

- [App Store Connect](https://appstoreconnect.apple.com/)
- [Google Play Console](https://play.google.com/console)
- [Firebase console](https://console.firebase.google.com/) (hosting + backend)

## Version discipline

1. Edit `pubspec.yaml`: bump **name** for marketing (`0.0.1` → `0.0.2`) and increment **build** after every store upload (`+1` → `+2`).
2. Tag Git: `git tag v0.0.2 && git push origin v0.0.2` (optional; triggers [`.github/workflows/release.yml`](../.github/workflows/release.yml)).
3. Paste the same **release notes** into App Store Connect + Play Console.

## Local release builds

```bash
flutter pub get
dart run flutter_launcher_icons   # after changing store_assets/app_icon_1024.png

flutter build web --release
flutter build apk --release
flutter build appbundle --release   # needs Android upload keystore (below)
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
flutter build macos --release
```

Artifacts:

| Platform | Output |
|----------|--------|
| Web | `build/web/` |
| Android APK | `build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` |
| iOS IPA | `build/ios/ipa/*.ipa` |
| macOS | `build/macos/Build/Products/Release/Pong.app` |

## Android — upload keystore (Play Console)

1. Run [`tool/create_android_upload_keystore.sh`](../tool/create_android_upload_keystore.sh) once (creates **gitignored** `android/upload-keystore.jks`).
2. Copy [`android/key.properties.example`](../android/key.properties.example) → `android/key.properties` (gitignored) with real passwords.
3. In Play Console enable **Play App Signing** and register the **upload** certificate.
4. **Back up** the `.jks` and passwords offline (loss = you cannot ship updates under the same app id).

Release builds use `key.properties` when present; otherwise Gradle falls back to **debug** signing (fine for local APK, **not** for Play production).

## Apple — Fastlane Match + TestFlight

1. Create a **private** git repo for Match (certs + profiles encrypted).
2. Install Ruby deps: `bundle install` (repo root [`Gemfile`](../Gemfile)).
3. First-time (local, **not** CI):  
   `bundle exec fastlane ios certificates`  
   Commit the Match repo changes Match makes.
4. Create an **App Store Connect API Key** (Issuer ID, Key ID, `.p8` file). Store as CI secrets or local env.
5. Upload builds:  
   `bundle exec fastlane ios beta_testflight`

See [`fastlane/Fastfile`](../fastlane/Fastfile) and [`fastlane/Matchfile`](../fastlane/Matchfile). Set env:

- `MATCH_GIT_URL` — Match certificates repo  
- `MATCH_PASSWORD` — encryption passphrase  
- `MATCH_READONLY=true` on CI  
- `APP_IDENTIFIER` — default `com.dulutan.pong`  
- `APPLE_TEAM_ID` — 10-char Team ID  
- App Store Connect API key via `APP_STORE_CONNECT_API_KEY` / `FASTLANE` env vars per [Fastlane docs](https://docs.fastlane.tools/app-store-connect-api/)

macOS lane: `bundle exec fastlane mac build_macos` then distribute **Transporter** or Xcode **Organizer**.

## Google Play — internal track

1. Create a **service account** with Play Developer API access; download JSON.
2. `export PLAY_JSON_KEY_PATH="$PWD/play-service-account.json"`  
3. `bundle exec fastlane android beta_play_internal`

## Web — Firebase Hosting

1. Replace `YOUR_FIREBASE_PROJECT_ID` in [`.firebaserc`](../.firebaserc).
2. `npm install -g firebase-tools` (or use npx).
3. `firebase login` then `firebase deploy --only hosting` after `flutter build web --release`.

Point **privacy policy** and **support** URLs in store listings to a **public HTTPS** page. Use [`web/privacy.html`](../web/privacy.html) deployed with the web build (`https://YOUR_DOMAIN/privacy.html` after replacing placeholders), or follow [`docs/PUBLISHING_PRIVACY.md`](PUBLISHING_PRIVACY.md).

## GitHub Actions

Workflow: [`.github/workflows/release.yml`](../.github/workflows/release.yml)

- **ubuntu** job: `flutter build web`, Android **APK**, **AAB** (AAB step uses `continue-on-error` if Gradle signing is missing). When **`PLAY_JSON_KEY`** is set, runs **`bundle exec fastlane android beta_play_internal`** (may still fail if the AAB is not Play-acceptable signing; step is `continue-on-error`).
- **macos** job: `flutter build ios --release --no-codesign`, **macOS** release build (may fail without signing entitlements on CI; `continue-on-error`), uploads **`pong-macos-release.zip`** when the macOS build succeeds. When **`MATCH_GIT_URL`**, **`MATCH_PASSWORD`**, and **`APP_STORE_CONNECT_API_KEY`** are set, runs **`bundle exec fastlane ios beta_testflight`** (`continue-on-error`).

Commit [`Gemfile.lock`](../Gemfile.lock) so `ruby/setup-ruby` `bundler-cache: true` works on Actions.

### Suggested repository secrets

| Secret | Purpose |
|--------|---------|
| `MATCH_GIT_URL`, `MATCH_PASSWORD` | Fastlane Match (private certs repo + passphrase) |
| `APP_STORE_CONNECT_API_KEY` | JSON body of App Store Connect API key (Fastlane env style; see [Fastlane](https://docs.fastlane.tools/app-store-connect-api/)) |
| `APPLE_TEAM_ID` | 10-character Apple Developer Team ID (optional if already in Match/Appfile) |
| `PLAY_JSON_KEY` | Google Play service account JSON **entire file** as the secret value (the workflow writes it to `play-service-account.json` before `supply`) |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PROPERTIES` | Optional: decode to `android/` before `flutter build appbundle` for CI-signed AAB |
| `FIREBASE_SERVICE_ACCOUNT` | Optional: `firebase deploy --only hosting` from CI |

## Fastlane lanes (repo root)

| Lane | Command |
|------|---------|
| iOS Match (read/write) | `bundle exec fastlane ios certificates` |
| iOS TestFlight | `bundle exec fastlane ios beta_testflight` |
| macOS build | `bundle exec fastlane mac build_macos` |
| macOS .pkg upload | `bundle exec fastlane mac upload_mac_app_store` (set `MACOS_PKG_PATH`) |
| Play internal | `bundle exec fastlane android beta_play_internal` |
| Play promote | `bundle exec fastlane android promote_play_production` |

## Store listing copy & compliance

- English listing draft: [`store_assets/marketing/STORE_LISTINGS_en.md`](../store_assets/marketing/STORE_LISTINGS_en.md)  
- Privacy policy template: [`docs/PRIVACY_POLICY.md`](PRIVACY_POLICY.md) (host publicly before submit)  
- Data safety / App Privacy checklist: [`docs/DATA_SAFETY_AND_APP_PRIVACY.md`](DATA_SAFETY_AND_APP_PRIVACY.md)

## Rollback

- **Stores**: you cannot “unpublish” users’ installed binaries; ship a **new** higher build with a fix and expedited review if needed.  
- **Web**: redeploy previous `build/web` artifact from CI artifacts or Git tag.  
- **Firebase**: keep previous Hosting release in Firebase console versions.

## Screenshots

Regenerate **placeholder** marketing frames: `dart run tool/gen_store_screenshots.dart`. Device-accurate captures: [`store_assets/README.md`](../store_assets/README.md) and [`tool/capture_ios_screenshots.sh`](../tool/capture_ios_screenshots.sh).

## First-time submission vs later builds

| First time | Later |
|------------|--------|
| Create App Store / Play app records, listings, screenshots, privacy URLs, ratings | Bump `pubspec` build number; refresh screenshots only if UI changed |
| Run Match locally once (`certificates` lane), populate private certs repo | `MATCH_READONLY=true` on CI; rotate certs via Match as needed |
| Longer review if permissions or data collection change | Faster review when changes are small |

