# SpeedyGo Customer App

Flutter application for SpeedyGo customers.

GitHub: https://github.com/zedclay/speedygo_customer_app.git

This app consumes backend APIs. It must never independently calculate authoritative financial values (pricing, fees, totals that the backend owns).

## Stack

- Flutter / Dart
- Riverpod 3
- go_router
- Dio
- Freezed + json_serializable (code generation ready, unused until models exist)

## Architecture

```
lib/
  app/        # router, theme, providers, shell
  core/       # constants, errors, network, storage, utils, widgets
  features/   # product features (empty during foundation)
```

## Local setup

```bash
flutter pub get
flutter run
```

The app talks to the backend **API on port 3000**, never PostgreSQL or Redis.

Pass the API prefix exactly once via dart-define:

```bash
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# Physical device — LAN HTTP is not supported by the current allowlist.
# iOS ATS and Android debug/profile cleartext permit only localhost,
# 127.0.0.1, and Android emulator 10.0.2.2. A command such as
# `--dart-define=API_BASE_URL=http://<Mac-LAN-IP>:3000/api/v1` will fail
# unless you add a *debug-only* ATS / network exception for that host.
# Do not hardcode a LAN IP. Do not add LAN or blanket cleartext exceptions
# to release builds. Prefer HTTPS or the iOS simulator / Android emulator.
```

`GET /health` is called at the server origin (`http://127.0.0.1:3000/health`), not `/api/v1/health`.

Interactive login uses the development API (`speedygo_dev`) with `OTP_TRANSPORT=console`. The OTP is read from **server stdout**, never from the app. Do not use Redis DB15 or `speedygo_test` for this app.

### Electronic payment (deployment flag)

There is **no** Customer API that advertises provider readiness. ELECTRONIC checkout is gated by an explicit compile-time flag (**default off**):

```bash
# Normal Customer builds — leave unset / false. COD only; ELECTRONIC shows « Bientôt disponible ».
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1

# Only after a verified Chargily sandbox is configured on the backend:
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1 \
  --dart-define=ELECTRONIC_PAYMENT_ENABLED=true
```

Backend prerequisites for that flag: `PAYMENT_PROVIDER=chargily`, `CHARGILY_MODE=test`, `CHARGILY_SECRET_KEY`, `PAYMENT_RETURN_URL`, `PAYMENT_CANCEL_URL`, `PAYMENT_WEBHOOK_URL`. Do **not** enable the flag against the empty/`test` adapter (`test://checkout/...`).

Optional review-only (never production): `--dart-define=ELECTRONIC_PAYMENT_ALLOW_TEST_CHECKOUT=true` acknowledges `test://` URLs without opening them.

Checkout URLs must be **HTTPS** on `pay.chargily.net`. HTTP, other hosts, and `test://` are rejected in normal mode. SpeedyGo Bearer tokens are never sent to the provider. Browser return never marks paid.

Firebase, Maps, and production signing are not configured yet.

## Scripts

| Command | Purpose |
| --- | --- |
| `flutter pub get` | Install packages |
| `flutter analyze` | Static analysis |
| `flutter test` | Tests |
| `dart run build_runner build --delete-conflicting-outputs` | Codegen when models exist |
