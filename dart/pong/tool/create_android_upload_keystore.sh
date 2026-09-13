#!/usr/bin/env bash
# Creates android/upload-keystore.jks (gitignored) and prints next steps for key.properties.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEY="$ROOT/android/upload-keystore.jks"
if [[ -f "$KEY" ]]; then
  echo "Refusing to overwrite existing $KEY"
  exit 1
fi
echo "Generating upload keystore at $KEY (RSA 2048, 10000 days, alias: upload)"
keytool -genkeypair -v \
  -keystore "$KEY" \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storetype JKS
echo ""
echo "Copy android/key.properties.example to android/key.properties and set:"
echo "  storeFile=upload-keystore.jks"
echo "  keyAlias=upload"
echo "Keep the .jks and passwords in a password manager — Play App Signing still requires this upload key for updates."
