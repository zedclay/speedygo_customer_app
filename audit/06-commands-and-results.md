# Commands and exits

Workspace: `/Users/mac/Downloads/speedygo_project`. Customer: `apps/customer_app`. Sequential where tools share Flutter lock. No commit / push / `.env` / schema.

## Flutter analyze (final tree)

```
flutter analyze
```

**exit 0.** `No issues found!` The previous 14 `prefer_const_*` / `prefer_initializing_formals` infos were fixed in source (no analyzer-rule weakening).

## Flutter test (full unit/widget, final tree)

```
flutter test
```

**exit 0.** `+278 ~13: All tests passed!`

Skipped (13): `test/audit/audit_screenshot_capture_test.dart` unless `AUDIT_CAPTURE=1` (populated Stitch goldens). Restore-phase addition is included in the +278 count.

## Golden capture (mocked, populated)

```
AUDIT_CAPTURE=1 flutter test test/audit/audit_screenshot_capture_test.dart --update-goldens
```

**exit 0.** 13 tests, 54 PNGs in `audit/visuals/widget/mocked/`. Fixture data labelled mocked.

## Stitch HTML references

```
python3 audit/scripts/render_stitch.py
```

**exit 0.** `engine=chrome-headless rendered=38 missing_html=0` (Playwright Python package absent; Google Chrome headless used).

```
python3 audit/scripts/compare_visuals.py
```

**exit 0.** `compared=38 missing=0` → `audit/visuals/compare/`.

## Android

Diagnosis: app `compileSdk` followed `flutter.compileSdkVersion` (36). `flutter_secure_storage` 11.0.0 compiles with **37**. SDK had `platforms/android-37.0` (`AndroidVersion.ApiLevel=37.0`) but Gradle looks up `platforms/android-37`.

Fix: `compileSdk = maxOf(flutter.compileSdkVersion, 37)` in `android/app/build.gradle.kts` (raise to match the plugin, not lower). Local symlink `$ANDROID_HOME/platforms/android-37` → `android-37.0` (machine SDK layout; not a repo file).

First retry after symlink reached native merge then **No space left on device**. `flutter clean` freed ~1.6G. Stale Gradle execution-history lock cleared with `./gradlew --stop`.

```
ANDROID_HOME=$HOME/Library/Android/sdk flutter build apk --debug
```

**exit 0.** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (re-run after UI fixes also exit 0). Gradle/AGP/Kotlin “will soon be dropped” warnings only.

## iOS

Not re-run this continuation (`flutter build ios --simulator --debug` was **exit 0** on the prior tree). Live integration below compiled with Xcode for the SE sim.

## Live read-only gestures (one instance)

Prior misclassified run: **exit 0** with `blocked_home` (harness returned without `fail()`).

Diagnostic + OTP-offline runs on SE `E342AC62-…` were **exit 1** (`blocked_login`): displayed **phone**. First fail: `reauthRequired`. One in-app Revue OTP then showed **offline** because SpeedyGo Redis `:6381` was unresponsive while `GET /health` stayed **200**. OTP was not retried after that copy.

After Docker Desktop relaunch (volumes kept), Redis 6381 **PONG**. One in-app Revue OTP reached Home. Later runs **restored** to Home without another OTP.

```
flutter test integration_test/audit_live_read_gestures_test.dart \
  -d E342AC62-65EB-4786-87D1-292AF132E1CF \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1 \
  --dart-define=SPEEDYGO_DEV_OTP_FILE=$HOME/.speedygo/dev/otp-last
```

**exit 0.** `status=passed` in `audit/live/read-only-gestures.json`. Assertions: Home `/home`, categories `/home/categories`, bakeries `/home/categories/results`, storefront `/merchants/0d00c071-…11004`, product `/products/0d00c071-…30402`, Back to Home, Commandes `/orders`, addresses `/account/addresses`, support `/support`, Alertes `/alerts`. Shots in `audit/live/shots/`.

No competing `flutter run`. No order submit/cancel, cart clear, or record create.

## Live photographed product (focused)

```
flutter test integration_test/audit_live_product_photo_test.dart \
  -d E342AC62-65EB-4786-87D1-292AF132E1CF \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1 \
  --dart-define=SPEEDYGO_DEV_OTP_FILE=$HOME/.speedygo/dev/otp-last
```

**exit 0.** `audit/live/product-photo-gestures.json` `status=passed` — Croissant au beurre menu+detail photos. Pain khobz unbound recorded as content gap.

## This visual-completion pass (focused only)

```
flutter analyze
```

**exit 0.**

```
flutter test test/live_screen_classify_test.dart test/features/auth_visual_layout_test.dart \
  test/features/orders/order_cancellation_flow_test.dart \
  test/features/orders/order_recovery_flow_test.dart \
  test/features/support/support_controllers_test.dart
```

**exit 0.**

```
AUDIT_CAPTURE=1 flutter test test/audit/audit_screenshot_capture_remaining_test.dart --update-goldens
```

**exit 0** (auth/restore + remaining journeys after harness fixes). Compare: `compared=57 missing=39`.

Earlier full-suite / Android APK results remain tied to the earlier tree (not restarted).

