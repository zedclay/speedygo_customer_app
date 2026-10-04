# Missing comparison-row classification (closed)

Source baseline: `audit/visuals/compare/index.json` at start of bookkeeping  
(`compared=57`, `missing=39`, `PAIRS×VIEWPORTS=96`).

Aborted capture/render shell jobs are **not** counted as completed coverage.

## Baseline 39 missing rows → classification

| Classification | Unique screens | Row count (slug×viewport) |
| --- | --- | --- |
| Implemented, **Stitch render missing/timeout** | 18 | 34 |
| Implemented, **Flutter capture missing** (17 Pro) | 3 (`menu-ready`, `merchant-info-ready`, `restore-loading-ready`) | 3 |
| Implemented, **Flutter + Stitch missing** | 1 (`merchant-reviews-ready` 17 Pro) | 1 |
| **Unsupported** (outside the 39) | splash/payment artboards were not in prior `PAIRS`; delivery-code / receipt / live Chargily | — |
| **Duplicate / incorrect mapping** | `annuler_la_commande_speedygo` → list + form alias; `menu_speedygo` ≈ storefront | noted, not double-counted as gaps |

### Unique screens (22) behind the 39 rows

Stitch-timeout (Flutter present):  
`account-delete`, `account-language`, `checkout-method`, `checkout-notes`, `favorites`, `legal`, `location-permission`, `logout-sheet`, `notification-prefs`, `order-rate`, `order-write-review`, `promotions`, `support-create`, `tracking-completed`, `tracking-map`, `tracking-nearby`, `tracking-searching`, `tracking-waiting` (17 Pro only).

Flutter-missing 17 Pro: `menu-ready`, `merchant-info-ready`, `restore-loading-ready`.  
Both missing 17 Pro: `merchant-reviews-ready`.

## After bounded Stitch retry + focused Flutter capture

| Metric | Value |
| --- | --- |
| Stitch missing-render script | **rendered=44 failed=0** (`stitch/missing-render-report.json`) |
| Flutter bookkeeping capture | menu/info/reviews/restore 17 Pro; splash frames SE; payment mocks SE; padding after-shots |
| Compare now | **compared=105 missing=9** (expanded PAIRS include splash/payment) |
| Remaining 9 missing | Splash frames + payment mocks on **17 Pro only** (SE Flutter present; Stitch present) — **implemented, Flutter capture missing** for that viewport |

## Padding inspection

- Confirmation + cancel **140px** bottom padding: CTAs reachable on SE and text 1.3; scroll does not hide sticky actions.
- **No further padding change.**
- Concrete SE defect found/fixed separately: confirmation total row horizontal overflow → `Flexible` + ellipsis.
- Support create keyboard: submit remains pinned (`bottomNavigationBar`).

## Package

`audit/customer-visual-review.zip` — INDEX + labeled side-by-sides + live Croissant + before/after notes.  
**Comparison generated ≠ visual match accepted.**
