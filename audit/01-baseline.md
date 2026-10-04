# Baseline (current working tree)

Date: **2026-09-11**. Workspace root `/Users/mac/Downloads/speedygo_project` is **not** a Git repository. Each app under `apps/` is independent. No commit, push, merge, reset, `.env` edit, or unrelated cleanup was performed. Untracked files were preserved.

No `AGENTS.md` at the workspace root. Architecture rule: `.cursor/rules/speedygo-architecture.mdc`. Customer navigation tracker: `apps/customer_app/NAVIGATION_STATUS.md` (rewritten this pass; previous copy was stale).

## Repository boundaries

| Path | Remote | Branch | HEAD | Local delta (approx.) |
| --- | --- | --- | --- | --- |
| `apps/customer_app` | `https://github.com/zedclay/speedygo_customer_app.git` | `feat/customer-auth-session` | `8adae21` | ~109 paths modified/untracked |
| `apps/backend` | `https://github.com/zedclay/speedygo_backend.git` | `main` | `2be7a4d` | ~89 paths; **not modified by this Customer audit** |
| `apps/admin_web` | `https://github.com/zedclay/speedygo_admin_web.git` | none | no commits | untracked scaffold |
| `apps/driver_app` | `https://github.com/zedclay/speedygo_driver_app.git` | none | no commits | untracked scaffold |
| `apps/merchant_app` | `https://github.com/zedclay/speedygo_merchant_app.git` | none | no commits | untracked scaffold |

API used by Customer: `http://127.0.0.1:3000/api/v1`. Persistent development media: `$HOME/.speedygo/dev/storage`. Synthetic Revue: `+213550000072`. Do not share refresh tokens or launch competing app instances against the same session.

## Customer inventory (current tree)

### Shell
Five tabs: **Accueil / Recherche / Commandes / Alertes / Profil** (`HomeBottomBar`, `AppStrings.tab*`). Pushed details sit above the shell. `popOrParent` uses `NavParents` when there is no history.

### Routes
Defined in `lib/core/navigation/app_routes.dart`, wired in `lib/app/router/app_router.dart`. Preview catalog: `lib/core/navigation/nav_catalog.dart` (non-release / `--dart-define=CUSTOMER_NAV_PREVIEW=true` / long-press home logo). Fixture ids `nav-branch`, `nav-order`, `nav-product`, `nav-ticket` are never sent to APIs.

### Feature areas (`lib/features/`)
auth, home, catalog, cart, checkout, addresses, orders, ratings, support, notifications, promotions, account.

### API / session
`lib/core/network/api_client.dart`, `token_refresher.dart` (single-flight, store-read refresh, persist-before-waiters). `lib/core/storage/session_store.dart`. Money: `lib/core/money/money_calc.dart` (BigInt minor units) + `money_format.dart`.

### Native
Android `AndroidManifest.xml` + launch resources; iOS `Info.plist` + `LaunchScreen.storyboard`.

### Tests
`test/` unit/widget; `integration_test/` live/mocked device tests. Audit capture: `test/audit/audit_screenshot_capture_test.dart` (skipped unless `AUDIT_CAPTURE=1`). Live read-only: `integration_test/audit_live_read_gestures_test.dart` (this session **`status=passed`** on SE; see [live/README.md](live/README.md)).

### Native / Android SDK
App `compileSdk = maxOf(flutter.compileSdkVersion, 37)` (`android/app/build.gradle.kts`) because `flutter_secure_storage` 11 compiles against API 37. Local SDK needed `platforms/android-37` (symlink to the installed `android-37.0` folder). `targetSdk` remains Flutter’s. Debug APK built this pass.

## Docs inspected for Customer contracts
`docs/architecture/` AUTHENTICATION, CUSTOMER_ONBOARDING, CART, CHECKOUT, ORDER, PAYMENTS, REFUNDS, RATINGS, SUPPORT, NOTIFICATIONS, REALTIME_TRACKING, CATALOG, PROMOTIONS, CUSTOMER_CATALOG_DISCOVERY, STATE_MACHINES.  
`docs/business-rules/` matching Customer-facing rules (cancellation, refunds, ratings, notifications, catalog discovery).  
`docs/api/API_CONVENTIONS.md`.  
`docs/database/ERD.md` / Prisma contract — **not expanded**.

Backend Customer HTTP (code-inspected, running process on port 3000): `/auth/*`, `/customer/me|profile|addresses`, catalog search/branches/products/images, cart, checkout preview, orders (+ cancel), payment, refunds read, tracking, delivery read, support, ratings, notifications, promotions discovery.

## Stitch
59 `code.html` directories under `screens/CustomerScreens/` plus 3 onboarding HTML files and `algerian_velocity/DESIGN.md`. **No PNG screenshots** are present in the current tree (`SCREEN_INVENTORY.md` is outdated on that point). Artboard size in HTML is typically `390×844`, not iPhone SE `375×667`.
