# SpeedyGo COD order lifecycle — local acceptance

Date: 2026-09-15 (defect-close + Customer UI read-only verify).  
Scope: existing synthetic COD order on `speedygo_dev` — **no new order**.  
Order: `01a0a2d5-70c9-76a9-8a6d-a6a77b54645d` / `sgo_01a0a2d570c97b46834e0c23e071634c`.  
No commit / push / schema / `.env` / queue flush / volume reset / business-data edits.

## Verdict

| Area | Result |
| --- | --- |
| Prior COD lifecycle (API-only ops) | **PASS** (unchanged terminal state) |
| BullMQ job-ID strategy | **FIXED** + isolated tests **PASS** |
| Souk openNow night gap | **Not a schedule/SQL defect** — live list returns Souk+Pharmacie; night/24h regressions **PASS** |
| Completed-order status label on detail | **FIXED** (`COMPLETED`/`DELIVERED` → `Livrée`) |
| Customer UI read-only gestures | **PASS** (live Revue session) |

Merchant/Driver product UIs remain shells — not in scope this pass.

## Environment checks

| Check | Result |
| --- | --- |
| Docker / Postgres `:5433` / `speedygo_dev` | intact |
| Redis `:6381` | `PONG` |
| API `:3000` | ok |
| Payment on order | `SUCCEEDED` / `COD` / `240500` (DB) |

## 1. Queue job IDs (BullMQ 6.3.3)

### Root cause

BullMQ `6.3.3` `Job.validateOptions`: custom `jobId` may contain `:` **only** if `jobId.split(':').length === 3` (legacy repeatable form).  

Legacy ids `matching:recovery` and `notifications:recovery` are **two** segments → `Custom Id cannot contain :`. That broke repeatable recovery schedules after API restart (matching rematch stalled). Three-segment ids such as `matching:start:<uuid>` were accepted, which masked the bug until recovery mattered.

### Strategy (finalized)

Hyphen-separated custom ids via shared helper — **no `:`**, uniqueness preserved:

| Job | jobId |
| --- | --- |
| Matching recovery (repeatable) | `matching-recovery` |
| Matching start | `matching-start-<orderId>` |
| Matching timeout | `matching-timeout-<assignmentId>` |
| Matching retry | `matching-retry-<deliveryId>` |
| Notifications recovery | `notifications-recovery` |

Already-queued Redis keys under `bull:matching:*` were **not** flushed. New ids do not collide with old colon forms.

### Files

- `apps/backend/src/infrastructure/queue/bull-job-id.ts` (+ `.spec.ts`)
- `apps/backend/src/modules/matching/infrastructure/matching-queue.service.ts`
- `apps/backend/src/modules/notifications/infrastructure/notification-queue.service.ts`

### Commands / exits

```text
pnpm exec jest src/infrastructure/queue/bull-job-id.spec.ts \
  src/modules/catalog/domain/customer-catalog-open-now.spec.ts --runInBand
→ Test Suites: 2 passed; Tests: 20 passed; exit 0

node --experimental-vm-modules ./node_modules/jest/bin/jest.js \
  --config ./test/jest-e2e.json --runInBand --forceExit \
  test/merchant-opening-hours.e2e-spec.ts \
  --testNamePattern='openNow at night includes 24h'
→ Tests: 1 passed, 5 skipped; exit 0
```

(Logs: `audit/cod-lifecycle-acceptance/logs/jest-jobid-opennow.log`, `e2e-opennow-night4.log`.)

## 2. Souk El Khemis openNow night gap

### Investigation (same night window as acceptance)

| Probe | Result |
| --- | --- |
| Africa/Algiers local | ISO dow=2, minute≈235 (~03:55) |
| SQL openNow `EXISTS` predicate | **Pharmacie Atlas + Souk El Khemis** |
| `GET /customer/branches?openNow=true` (no vertical) | **total 2**, both `isOpenNow: true` |
| Fixture hours | identical 24h `00:00→00:00` `closes_next_day` for both |
| Verticals | Souk → Épiceries; Pharmacie → Pharmacies |

### Conclusion

**Not a 24h / midnight / overnight evaluator or SQL defect.** Prior UI assertion that only Pharmacie appeared is consistent with (a) Home `verticalId=Pharmacies` selection, and/or (b) incomplete scroll/assertion during automation — not valid exclusion by hours. No shop hours / classifications / clock edits made.

### Regression coverage added

- Unit: night 24h, local midnight 24h, overnight-after-midnight in `customer-catalog-open-now.spec.ts`
- E2e: `openNow at night includes 24h and overnight intervals (not daytime-only)` in `merchant-opening-hours.e2e-spec.ts` (fixed clock Tue 03:55 Algiers)

## 3. Customer UI read-only acceptance (live gestures)

Synthetic customer Revue `+213550000072`. No new order; ratings not resubmitted; no notification create; Bousbaa untouched. No external reuse of app refresh tokens (OTP / restored in-app session only).

### Gesture path

Home → Commandes → **Terminées** → order tile → detail → ratings read → Back → Alertes

### Results

| Check | Result | Evidence |
| --- | --- | --- |
| Login | **PASS** (`restored_revue_session`) | live UI |
| Active-order card | **PASS** — target completed order absent | `activeOrderCard: absent` |
| List status / COD / amount | **PASS** — `Livrée`, COD, `2 405,00 DZD` | shot `02-orders-list` |
| Detail status / COD / amount | **PASS** — `Livrée` after label fix | shot `03-order-detail` |
| Payment SUCCEEDED deep-link | **N/A in UI** — payment entry is ELECTRONIC-only; COD shows method `Paiement à la livraison`; DB `SUCCEEDED` | design, not gesture gap for COD |
| Ratings | **PASS** — existing `ratingAlreadyDone` (no resubmit) | shot `05-ratings-read` |
| Back | **PASS** | shot `06-orders-after-back` |
| Notifications | **PASS** — Alertes inspected, none created | shot `07-alerts-existing` |

Evidence JSON: `audit/cod-lifecycle-acceptance/logs/completed-order-ui-evidence.json`  
Log: `logs/completed-order-ui3.log` → **All tests passed**  
Screenshot names logged as `COD_COMPLETED_UI:*` (host PNG callback still often unwired under `flutter test` — treat as live gesture proof via log + evidence JSON, not mocked).

### UI defect fixed for this verify

`activeOrderStatusLabel` ignored `orderStatus == COMPLETED` and `deliveryStatus == DELIVERED`, so detail showed **« Prête pour le livreur »** for a completed order (list already showed « Livrée »).

- `apps/customer_app/lib/features/orders/data/order_models.dart`
- Unit: `test/features/home/home_live_contract_test.dart` — **8 passed**
- Analyzer on changed Dart: info-only `prefer_const_constructors` cleaned

Integration harness: `integration_test/cod_lifecycle_completed_order_ui_test.dart`

```text
flutter test integration_test/cod_lifecycle_completed_order_ui_test.dart \
  --dart-define=SPEEDYGO_DEV_OTP_FILE=$HOME/.speedygo/dev/otp-last
→ All tests passed; exit 0
```

## Explicit non-claims

- Full multi-app Merchant/Driver UI acceptance
- COD remittance / settlement
- Host-persisted PNG screenshot files (names only unless device callback wired)
- Payment-status screen for COD (no sticky entry by design)

## Remaining blockers

1. Merchant / Driver / Admin UIs are shells.
2. Optional: expose read-only COD payment status on Customer order detail (today ELECTRONIC-only payment entry).
3. Souk openNow Home observation: ensure automation clears `verticalId` before asserting unfiltered openNow (process, not backend bug).
4. Changes in this pass are **local / uncommitted** (per instructions).

## Order identity

```text
orderId: 01a0a2d5-70c9-76a9-8a6d-a6a77b54645d
publicReference: sgo_01a0a2d570c97b46834e0c23e071634c
customer: +213550000072
payableMinor: 240500 → 2 405,00 DZD
payment: SUCCEEDED COD
status: COMPLETED / Delivery DELIVERED
```
