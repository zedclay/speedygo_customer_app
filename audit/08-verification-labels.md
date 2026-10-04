# Verification labels

| Flow / claim | Label | Notes |
| --- | --- | --- |
| Widget/unit suite on this tree | **mocked** | Earlier full suite preserved; this pass focused tests exit 0 (see 06) |
| Analyzer | **live tooling** | `flutter analyze` exit 0; settings not weakened |
| Android debug APK | **live tooling** | `flutter build apk --debug` exit 0 after compileSdk 37 + `android-37` → `android-37.0` symlink |
| iOS simulator compile | **live tooling** | prior `flutter build ios --simulator --debug` exit 0; not re-run this continuation |
| Profile payment methods isolation | **mocked** | `account_hub_flow_test` |
| Cart `cartReady` CTA | **mocked** | same |
| Orders list parse + pagination + filters | **mocked** | `orders_list_test` |
| OTP cooldown stay-on-phone | **mocked** | `widget_test.dart` |
| Token refresh single-flight / store-read | **mocked** + **code-inspected** | `token_refresher_test` |
| BigInt money | **code-inspected** + unit if present | `money_calc.dart` |
| Order ownership / mass-assignment | **code-inspected** | `order.controller.ts` |
| Cart ownership by customerId | **code-inspected** | cart service/repo |
| Populated Stitch HTML vs Flutter | **mocked** | Chrome HTML renders + widget goldens + overlays; **not** pixel-identical; **not** live |
| Stitch `screen.png` overlay | **unavailable** | no `screen.png` in tree |
| Catalog image HTTP 200 after storage rebind | **live** (HTTP script, earlier this day) | not a Flutter gesture |
| Revue home/catalog/checkout/orders (prior sessions) | **historical live** | not current-session gesture proof |
| iPhone SE live product photo | **live** | Croissant au beurre menu+detail `authenticated-catalog-image`. Pain khobz unbound = content gap. `product-photo-gestures.json` |
| iPhone 17 Pro live UI | **unverified** | Simulator Shutdown; widget 402×874 only |
| COD place-order this session | **unverified** | not re-run live |
| Ratings submit | **unverified** | needs COMPLETED synthetic order |
| Support create/reply live | **unverified** | OTP rate-limit risk |
| Socket.IO tracking LIVE | **unverified** | no LIVE synthetic delivery |
| Chargily | **unavailable** | keys absent; flag default false |
| Admin/Driver/Merchant apps | **not audited** | |
