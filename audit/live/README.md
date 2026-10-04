# Live gate: `blocked_home` resolved

## What the old report hid

`audit/live/read-only-gestures.json` previously recorded `status=blocked_home` with **exit 0**. That was a harness defect, not proof that Home was showing.

The old test:

- Waited **8s** for `searchHint` / phone title / language title only.
- Splash has none of those strings. Splash also waits on `GET /health` (up to 5s) before `restore()`.
- `SessionPhase.restoring` was never assigned, so `/restore` never appeared during hydrate.
- If none of the three finders hit, it wrote JSON and **returned** — Flutter counted a pass.

No screenshot was stored for that first run.

## Actual displayed state (not a Home finder miss)

| Run | Displayed screen | Evidence | OTP |
| --- | --- | --- | --- |
| Diagnostic (fail on miss) | **phone** | `reauthRequired` — local session invalidated | Not sent |
| After that | **phone** | No `reauthRequired` (`signed_out`) | One in-app request |
| That request | **phone** | `AppStrings.offline` | **Not retried** |
| After Redis 6381 recovered | **phone** then **Home** | One in-app Revue OTP, then restore | One success; later runs restored |

`reauthRequired` is set only by `invalidateLocalSession()`. That is **not** a Home search-hint miss and **not** assumed refresh-token reuse from an external client.

Host `GET /health` was **200** while OTP showed offline. Health does not prove Redis. SpeedyGo Redis (`127.0.0.1:6381`) was unresponsive (TCP open / PING hung, then Docker engine down). Default Redis `:6379` PONG is a different process. After Docker Desktop relaunch (volumes kept) Redis 6381 **PONG** and Postgres 5433 answered.

Revue sessions in `speedygo_dev` (counts only, no tokens): **13 active unexpired**, **16 revoked**. The Revue **account** was not fully revoked. The **local** Keychain session had been invalidated; recovery used the normal in-app OTP once. Later live runs restored to Home without another OTP.

## This session live acceptance

SE `E342AC62-…`, one `flutter test` instance, real taps:

Home → Tout voir → Boulangeries → Four de Didouche → Pain khobz → Back ×4 → Commandes → Profil → addresses → Mes demandes → Alertes.

## Photographed product (content gap closed for bound SKUs)

Pain khobz `…30402` has **no** `product_images` row — placeholder is correct (content gap).

Croissant au beurre `…30421` and Pain au chocolat `…30422` have bound JPEGs under `/tmp/speedygo-private-storage/product-images/`.

Focused live (`audit_live_product_photo_test.dart`) **exit 0**: Viennoiseries → Croissant au beurre; `menuThumbnailPhotographed=true`, `productPhotographed=true`. Shots: `live-photo-menu.png`, `live-photo-product.png`. JSON: `product-photo-gestures.json`.

Do not use storefront cover as product photo evidence.

