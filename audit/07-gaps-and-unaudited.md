# Remaining capability gaps and unaudited areas

Classification (do not collapse these):

| Class | Meaning |
| --- | --- |
| Confirmed implementation defect | Flutter/presentation bug proven on this tree |
| Unverified live behavior | Code exists; this session did not prove the gesture/API on device |
| Missing external configuration | Keys, SDK, flags, or OS services outside the app tree |
| Missing backend capability | No Customer contract in frozen v1.0 |
| Optional product enhancement | Stitch or wishlist item **not** in the agreed MVP / foundation **Out** list |
| Unfinished honest screen | Route exists with truthful empty/unsupported copy; not a fake success |

Widget-test green is **not** visual completion. Live tap/Back **passed** this session (`status=passed` — see [live/README.md](live/README.md)). The old `blocked_home` label was a harness miss (exit 0 without `fail()`), not a Home finder miss. OTP `offline` was Redis `:6381` down behind a 200 health check, not refresh-token reuse.

## Ranked remaining gaps (user impact)

### P1 — blocks a money or in-progress delivery journey

1. **Electronic payment sandbox** — missing **external config**: Chargily keys, `PAYMENT_PROVIDER=chargily`, and `ELECTRONIC_PAYMENT_ENABLED` only after a real sandbox. App correctly stays off `test://`. COD checkout is the live path.
2. **Active delivery LIVE proof** — **unverified live**: no synthetic `SEARCHING_DRIVER` / LIVE location for Revue; Socket.IO tracking not proven this session.
3. **Map provider** — missing **external config** (no Maps/Mapbox SDK or keys). Tracking shows status + coords only.
4. **Customer delivery-code API** — missing **backend**; screen is a product-decision placeholder.

### P2 — checkout/ops completeness, not fake chrome

5. **Checkout notes / address `instructions` write** — missing **backend** in v1.0.
6. **OS push + notification preference storage** — inbox API is integrated; prefs/OS permission are missing **external/config**. Honest prefs screen. Live **Alertes** tab read passed this session.
7. **Ratings submit / support create-reply** — **unverified live** (need COMPLETED order; avoid OTP rate-limit). Support **list** (`Mes demandes`) was read this session.

### P3 — honest unfinished or optional (not mandatory MVP)

8. **Legal copy** — unfinished honest screen. **No CMS requirement** in architecture docs. Do not treat “add a CMS” as P1.
9. **Favorites** — optional. `CUSTOMER_ONBOARDING.md` **Out**. Honest `/favorites` placeholder.
10. **Saved cards** — optional. Checkout is COD vs gated ELECTRONIC. Honest profile empty-cards screen.
11. **Account deletion** — optional / onboarding **Out**. Honest unsupported; Stitch password field is **E**.
12. **Public review comments** — optional vs v1 ratings (summary + author-only).
13. **Arabic/RTL** — disabled in language picker (product).
14. **Receipt / delivery-notes placeholders** — preview-only; not live acceptance.
15. **Stitch E contradictions** kept (4 EN tabs, Panier vs “Merchant Details”, confirmée, 48h, 2FA, etc.).

Do not invent ETA, ratings, payment success, public reviews, or delivery codes to match HTML fixtures.

## Explicitly not a full-platform audit

Inspected for **Customer consumption** only:

- Backend Customer/auth/catalog/cart/checkout/orders/payments/refunds/ratings/support/notifications/promotions/tracking HTTP surface (code + running `/docs` route map in the API process).
- `docs/` architecture and business-rules listed in [01-baseline.md](01-baseline.md).

**Not reviewed as product UIs or full APIs:**

| Area | Note |
| --- | --- |
| `apps/admin_web` | scaffold; no commits |
| `apps/driver_app` | scaffold; no commits |
| `apps/merchant_app` | scaffold; no commits |
| Admin HTTP (`/api/v1/admin/**`) | inventory only via boot log |
| Merchant HTTP beyond image bind used to restore catalog media | not a Merchant app audit |
| Driver matching, COD remittance, earnings, settlements, ledger, reports | not Customer UI |
| Prisma/ERD changes | frozen; not expanded |
| Physical device “iPhone De Hafid” | listed by `flutter devices` historically; not used this pass |
| Android emulator install/run | debug APK **built** (exit 0); not installed on an emulator this pass |

## External services

Chargily Pay V2, FCM/APNs, Google Maps / Mapbox, SMS OTP provider (dev OTP path used historically). Legal hosting is **not** assumed.
