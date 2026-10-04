# Customer app — release readiness checklist

Date: 2026-09-16/17 (local acceptance, technical closure pass).  
Scope: **Customer app only** (no Merchant/Driver UI).  
Constraints honored: no new orders/payments/ratings/business transitions; no Admin ticket status changes; no backend/schema/`.env`/commit/push; Bousbaa untouched; electronic payment left gated off (`ELECTRONIC_PAYMENT_ENABLED` default false); no AVD wipe/SDK downgrade/Docker volume reset; no business-data seeding; UI/snackbar local work preserved.

**Verdict:** Support, location (SE+mocked), session/network, iOS catalog smoke, **in-app natural access-token expiry → refresh**, and full `flutter analyze` + `flutter test test/` are evidence-backed on this closure pass. **Android device smoke remains BLOCKED** (AVD reports boot then drops off `adb` / process exits; disk free was sufficient; no authorized physical Android). Prior release APK build is **not** counted as smoke.

---

## Flow results

| Flow | Platform | Result | Evidence class |
| --- | --- | --- | --- |
| Support list → detail → Back | iOS sim | **PASS** (historical) | Live UI gestures |
| Support draft retention across Back | iOS sim + widget | **PASS** (historical) | Live + unit |
| Support follow-up | — | **PASS** (not resent) | Fixture `followUpSent: true` |
| Support UI create (one synthetic) | iOS sim | **PASS** (historical) | Live UI write once |
| Location permission after tap | iOS sim | **PASS** (historical) | Live OS + in-app allow |
| Denied / forever / services-disabled | host unit | **PASS** | Mocked (`address_flow_test`) |
| Granted → confirm fills form | host unit | **PASS** | Mocked |
| Manual entry + Save @ SE 1.3 | iOS sim + unit | **PASS** (historical) | Live SE viewport + mocked keyboard |
| GPS coordinates | iOS sim | **PASS** (sim only) | `simctl location` — **not** physical GPS |
| Session cold-start restore | iOS sim | **PASS** (historical) | Live (seeded same-app session) |
| Background/resume | iOS sim | **PASS** (historical) | Live lifecycle |
| Client network interruption | iOS sim | **PASS** (historical) | Live Dio to closed port |
| Reconnect API same account | iOS sim | **PASS** (historical) | Live `GET /customer/me` |
| Access-token expiry / refresh rotation | iOS sim | **PASS** (this pass) | Natural expiry + in-app Dio burst |
| Logout / account isolation | host unit | **PASS** | Automated unit |
| Home → category → storefront | iOS sim | **PASS** (historical) | Live smoke (`category: Pharmacies`) |
| Storefront → product → Back | iOS sim | **PASS** (historical) | Live smoke (Atlas / crème solaire) |
| Orders tab | iOS sim | **PASS** (historical) | Live smoke |
| Address form (no save) | iOS sim | **PASS** (historical) | Live smoke |
| Android smoke (same journeys) | Android emu | **BLOCKED** (this pass) | AVD unstable on adb; no gestures |
| Physical-device install | — | **NOT TESTED** | No authorized physical Android |

---

## Platform / toolchain

| Item | Value |
| --- | --- |
| Flutter | 3.47.2 stable / Dart 3.13.2 |
| Xcode | 26.0.1 |
| Android SDK | 35.0.0 (`ANDROID_HOME=~/Library/Android/sdk`) |
| iOS test device | iPhone 17 Pro sim `4A1C3481-8B8E-48BD-983D-03896884EF09` |
| Android AVD | `flutter_emulator` — starts, log `Boot completed`, then **leaves `adb` empty** (process exits; crashdata path logged). Disk check **Ok** this pass |
| Host disk (closure) | Data volume **≈7.8–14Gi available** (not the prior 125Mi FATAL) |
| Electronic payment | gated **off** (default) |
| API for live checks | local Nest `node dist/src/main.js` on `:3000` (existing `.env`; no schema/env edits) |

---

## Commands, exits, artifacts

### Access-token expiry / refresh (this pass — PASS)

```text
flutter test integration_test/customer_release_refresh_expiry_test.dart \
  -d 4A1C3481-8B8E-48BD-983D-03896884EF09 --timeout 30m \
  --dart-define=SPEEDYGO_DEV_OTP_FILE=/Users/mac/.speedygo/dev/otp-last
→ All tests passed (refresh-expiry-live.log) REFRESH6_EXIT:0
```

Account: synthetic **Revue Catalogue SpeedyGo** (`+213550000072`). Bousbaa untouched. One in-app OTP bootstrap (stale seed could not restore). Waited **901s** natural access TTL (no clock/TTL changes). Refresh token never copied to an external HTTP client.

Evidence `logs/refresh-expiry-evidence.json` (sanitized):

| Check | Value |
| --- | --- |
| `accessExpiryObserved` | true (`secondsUntilExp: -3` before burst) |
| `refreshDelta` | **1** (single-flight) |
| `accessRotated` | true (`accessFp` `4ccccc86` → `0345b2b1`; new `exp`) |
| `tokenSourceAfter` | `tokenCache` (store/cache after interceptor; not UI state alone) |
| `subsequentMeOk` / `accountUnchanged` | true / true |
| `stillAuthenticated` | true (`sessionPhaseAfter: ready`) |
| `sidFp` before→after | same (`6d17812b`) — no new sid; not treated as Home-visible inference |
| DB session (OTP) | `01a0aca2-…` **not revoked** after observation |
| `result` | **PASS** |

Server correlation: OTP created session `01a0aca2-403c-71be-aa14-8deab496eb39` (`revoked=f`). No refresh-token reuse failure observed (`refreshDelta=1`, still authenticated). Home visibility alone was **not** used as success (`homeVisibleAloneInsufficient: true`).

Note: an earlier failed attempt with a **stale** seed refresh revoked historical session `01a0a4f8-5522-…` (not initiated as an operator revoke; Bousbaa unaffected). Closure observation used a fresh OTP session only.

### Android smoke (this pass — BLOCKED)

```text
df → Avail ≈14Gi then ≈7.8Gi (sufficient vs prior 125Mi FATAL)
emulator -avd flutter_emulator …
→ log: Disk space requirements … Ok; Boot completed in ~5s; then process exits
adb devices → (empty) after boot window
→ no gesture run; APK build from prior day still ≠ smoke
```

Requested journeys **not executed** (no usable `adb` device): Home → categories → storefront → product → Back; Commandes → order → Back; Profil → support. No new business records.

### Analyze + unit suite (final tree, sequential)

```text
flutter analyze
→ exit 0, 5 infos only (prefer_const_* / unnecessary_const in tests)
  logs/flutter-analyze-closure-final.txt

flutter test test/
→ +334 ~44 All tests passed  UNIT_FINAL_EXIT:0
  logs/flutter-unit-full-closure-final.txt
```

Narrow product fix this pass: `SgSnack` clears static dedupe state when the overlay host is disposed (fixes favorites blocked-message flake after snackbar work). No assertion weakening.

### Support / location / session / iOS catalog (historical — unchanged)

See prior sections below; not re-run this closure except where noted. Evidence files under `logs/` from 2026-09-15 remain valid historical passes.

### Support (live) — historical

```text
flutter test integration_test/customer_release_support_test.dart \
  -d 4A1C3481-8B8E-48BD-983D-03896884EF09 --timeout 12m
→ All tests passed (support-live-5.log)
```

### Location (live SE + mocked matrix) — historical

```text
flutter test integration_test/customer_release_location_se_test.dart …
→ All tests passed (location-live-3.log)
flutter test test/features/addresses/address_flow_test.dart → 12 passed
```

### Session / network — historical

```text
flutter test integration_test/customer_release_session_network_test.dart …
→ All tests passed (session-network-live-2.log)
```

### Pharmacie Atlas product journey (live API + iOS) — historical

```text
flutter test integration_test/customer_release_smoke_ios_test.dart …
→ All tests passed (smoke-ios-11.log)
```

### Release builds (prior — unchanged)

| Artifact | Kind | Exit | Path |
| --- | --- | --- | --- |
| Android APK | Release APK (not Play upload; **≠ smoke**) | 0 | `build/app/outputs/flutter-apk/app-release.apk` |
| iOS Runner.app | Unsigned `--no-codesign` | 0 | `build/ios/iphoneos/Runner.app` |
| Signed App Store / TestFlight | — | **NOT TESTED** | No credentials |
| Store upload | — | **NOT DONE** | Forbidden this pass |

---

## Defects fixed this pass

| Defect | Fix |
| --- | --- |
| SgSnack static dedupe blocked identical messages after overlay teardown | `onHostDisposed` clears `_entry` / `_activeMessage` when host disposes |
| Refresh evidence read `SessionController.tokens` after silent rotation | Observation uses `TokenCache` / session store (matches Dio) |

### Files changed (Customer) this closure

- `lib/core/widgets/sg_snackbar.dart`
- `integration_test/customer_release_refresh_expiry_test.dart`
- `audit/customer-release-readiness/**` (this report + logs)

Preserved (not reopened): snackbar/UI cleanup (order title, checkout zone hide, item photos, payment reachability) and related tests/captures.

---

## Remaining blockers (separated from historical passes)

**Still open**

1. **Android installable-device smoke — BLOCKED.** Disk free is OK; AVD `flutter_emulator` does not stay on `adb` after snapshot boot (process exits). No authorized physical Android. Gesture journeys not run. Prior APK ≠ smoke.

**Closed this closure pass**

- In-app natural access-token expiry → single refresh rotation (iOS sim + live API).
- Final `flutter analyze` (exit 0, 5 infos) + full `flutter test test/` (`+334 ~44`).
- SgSnack teardown dedupe flake.

**Historical passes (not re-litigated)**

- iOS support / location / session-network / Pharmacie Atlas catalog smoke.
- Catalog/cart unit gesture fixes.

**Optional / out of MVP**

- Electronic payment (gated off).
- Merchant/Driver UIs; store publishing; physical GPS.

---

## Next highest-priority task

Stabilize Android runtime (keep `flutter_emulator` attached on `adb` with `sys.boot_completed=1`, or use an already-authorized physical device), then run `customer_release_smoke_android_test.dart` with `API_BASE_URL=http://10.0.2.2:3000/api/v1` and `SMOKE_TOKEN_JSON` — without AVD wipe or disk cleanup scripts.
