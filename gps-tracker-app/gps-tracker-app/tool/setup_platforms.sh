#!/usr/bin/env bash
# One-time setup: generates the android/ and ios/ folders and applies the
# dev-time tweaks this app needs (internet permission, plain-HTTP to a local
# backend, minSdk for secure storage). Safe to re-run.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter create --org com.example --project-name gps_tracker_app --platforms=android,ios .
rm -f test/widget_test.dart   # template test refers to a MyApp class we don't have

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q usesCleartextTraffic "$MANIFEST"; then
  perl -0pi -e 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application android:usesCleartextTraffic="true"#' "$MANIFEST"
fi

# flutter_secure_storage (encrypted prefs) needs minSdk 23
for f in android/app/build.gradle android/app/build.gradle.kts; do
  [ -f "$f" ] && perl -pi -e 's/minSdk = flutter\.minSdkVersion/minSdk = 23/; s/minSdkVersion flutter\.minSdkVersion/minSdkVersion 23/' "$f"
done

PLIST=ios/Runner/Info.plist
if [ -f "$PLIST" ] && ! grep -q NSAppTransportSecurity "$PLIST"; then
  perl -0pi -e 's#</dict>\s*</plist>#\t<key>NSAppTransportSecurity</key>\n\t<dict>\n\t\t<key>NSAllowsLocalNetworking</key>\n\t\t<true/>\n\t</dict>\n</dict>\n</plist>#' "$PLIST"
fi

flutter pub get
echo "Done. Run:  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000"
