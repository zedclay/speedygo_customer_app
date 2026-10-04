# Shopping visual review batch

**Generated:** 2026-09-12 (payable sticky-only). **Scope:** Categories explore → category results → storefront detail → search results → product options → cart → checkout review → address picker.

Use **`audit/customer-visual-review-shopping.zip`** for human review of this batch. **`customer-visual-review-pilot.zip`** and its six pilots are unchanged.

## Batch scope

Mocked widget golden capture (`AUDIT_CAPTURE=1`) through the shopping funnel:

1. Home → **Voir tout** → commerce verticals (categories)
2. **Restaurants** → storefront list (category results)
3. Storefront detail → product → configure (product options)
4. Search tab → query `es` → mixed storefront/product hits
5. Cart (pre-seeded checkout cart) → checkout review → address picker

Dense-layout extras (SE only, text scale 1.3): categories, cart, checkout review, checkout review with keyboard inset.

## Screen / state / viewport table (mocked evidence)

| Slug | Screen / state | Viewports | Flutter golden(s) | Stitch ref | Compared |
| --- | --- | --- | --- | --- | --- |
| `categories-ready` | Commerce verticals, loaded | SE 375×667, iPhone 17 Pro 402×874 | 2 + `text-1.3` | 2 | 2 |
| `category-results-ready` | Storefront list (Restaurants) | SE, Pro | 2 | 2 | 2 |
| `storefront-ready` | Storefront detail + menu | SE, Pro | 2 | 2 | 2 |
| `search-results-ready` | Search results for `es` | SE, Pro | 2 | 2 | 2 |
| `product-options-ready` | Product configure (Double selected) | SE, Pro | 2 | 2 | 2 |
| `cart-ready` | Cart with seeded line item | SE, Pro + `text-1.3` | 3 | 2 | 2 |
| `checkout-review-ready` | Checkout review (COD; payable sticky-only) | SE, Pro + `text-1.3` | 3 | 2 | 2 |
| `checkout-address-ready` | Address picker (home + work) | SE, Pro | 2 | 2 | 2 |
| `checkout-review-keyboard` | Checkout review, promo field focused + keyboard inset | SE `text-1.3` only | 1 | — | — |

**Evidence:** `audit/visuals/shopping/flutter/*.png`, `stitch/*.png`, `compare/*-side-by-side.jpg`.

Fixtures: fake catalog/cart/checkout/addresses, product photo bytes from `test/audit/fixtures/product-photo.jpg`, no live network.

## Concrete fixes applied (this batch)

| Area | Fix |
| --- | --- |
| `checkout_review_screen.dart` | Payable **Total à payer** is sticky-only (`checkout-sticky-total` above **Commander**); body totals card (`checkout-totals`) shows Sous-total / Livraison / discount only — no body `checkout-total` / duplicate Total; body bottom padding 24 (Scaffold clears bottomNav); selected options as separate lines; AppBar back via `IconButton`. |
| `audit_shopping_capture_test.dart` | Asserts `checkout-sticky-total` + `checkout-totals`; `ensureVisible` on product name (top of review) before review goldens; `ensureVisible` on `checkout-address-card` before opening the picker. |
| `checkout_flow_test.dart` | Expects `checkout-total` absent; single payable amount via `checkout-sticky-total`. |
| `storefront_detail_screen.dart` | AppBar / SliverAppBar back + share/favorite actions use `IconButton` with tooltip (Stitch parity). |
| `address_picker_screen.dart` | Address line text `maxLines: 3` + ellipsis; AppBar back via `IconButton`. |
| `search_screen.dart` | Hit rows keyed by branch/product id; cover thumbnails via `coverImageBytes` hook; embedded AppBar `IconButton` back when `showBack`. |

**Checkout review golden check:** Payable is sticky-only — body totals card has no **Total à payer** (no overlapping duplicate). Review shots `ensureVisible` the product name (top of review). `checkout-review-ready-se-375x667.png` shows items + address near the top, sticky **Total à payer** / **19,00 DZD** + **Commander** at the bottom, with no second Total line in the body card.

## Remaining differences vs Stitch

- **Product photo:** Croissant JPEG from `test/audit/fixtures/product-photo.jpg` is reused as a photographed stand-in for the espresso product — not a live espresso asset.
- **Delivery ETA / ratings:** Not shown in this batch; no ETA or rating values invented in Flutter or fixtures.
- **Category / storefront chips:** Stitch HTML reports intentional horizontal chip overflow at the right edge on category results (both viewports) and storefront detail (SE). Flutter uses scrollable chip rows — no clip.
- **Copy / data:** Flutter uses French fixture strings; Stitch HTML uses its own placeholder merchant copy — side-by-sides are structural, not pixel-identical text.
- **Electronic payment:** Compile-time gate off; checkout review shows COD path only (consistent with pilot batch).
- **Text 1.3 / keyboard shots:** Flutter-only regression captures; no Stitch pair (not in compare index).
- **Sticky total (payable sticky-only):** Flutter shows **Total à payer** only on the CTA bar (`checkout-sticky-total`); body card is subtotal/delivery(/discount) only. Stitch may still show a body total — compare JPGs are structural.
- **Checkout review board mismatch (E):** Stitch `r_vision_de_la_commande_speedygo` is a known reorder / layout board mismatch vs Flutter checkout review (section order and sticky CTA). Documented remaining; not treated as a Flutter regression in this batch.

## Validation results

| Step | Result |
| --- | --- |
| `flutter analyze` on `checkout_review_screen.dart` + `audit_shopping_capture_test.dart` | Exit **1** — 4× info `prefer_const_constructors` in the capture test only (no errors/warnings) |
| `flutter test test/features/checkout/` | **Pass** — exit **0**, 28 tests |
| `AUDIT_CAPTURE=1 flutter test … --update-goldens` (payable sticky-only) | **Pass** — exit **0**, 7 tests, **20** Flutter golden PNGs |
| `compare_shopping_visuals.py` (stitch reused) | **Pass** — exit **0**, **16** side-by-side JPEGs, 0 missing |
| Zip `customer-visual-review-shopping.zip` | **19,272,999** bytes (`audit/customer-visual-review-shopping.zip`) |

## Pilots preserved

**`audit/customer-visual-review-pilot.zip`** (2.9 MB, 2026-09-12 03:57) was not modified. Its six pilot goldens remain the onboarding/auth baseline for human review.

## Live gesture

**Live gesture proof:** **Not run.** This batch is mocked golden capture + Stitch render/compare only. No `integration_test`, no manual simulator walk, and no live shopping-funnel taps were executed in this pass.
