# UI alignment visual review batch

**Generated:** 2026-09-14. **Package:** `audit/customer-ui-alignment-review.zip`.

**Labels:** Flutter PNGs are **MOCKED FLUTTER** (`AUDIT_CAPTURE=1`). Stitch PNGs are **STITCH REFERENCE** (Playwright, CustomerScreens HTML, SE + iPhone 17 Pro).

Do **not** treat `customer-visual-review.zip` as acceptance.  
Do **not** treat matrix `implementer_reviewed` as human sign-off.  
Live gesture: **not run**. `human_accepted`: **not claimed**.

## Authoritative tracker

`audit/06-ui-alignment-matrix.md` (copied into this zip as `06-ui-alignment-matrix.md` and `visuals/alignment/06-ui-alignment-matrix.md`).

## Findings (2026-09-14 evidence/behavior close)

| Finding | Diagnosis | Result | Evidence |
| --- | --- | --- | --- |
| Address SE 1.3 keyboard Save missing | Sticky bar ignored `viewInsets` | Pad Save by keyboard inset; assert inset=280 and hittable CTA above it | `flutter/address-form-keyboard-se-375x667-text-1.3.png` |
| Tracking steps unreachable | Sticky overlay vs hit-tests; do not shrink | ListView padding 160; steps 0–4 `ensureVisible` in list above sticky on SE/Pro | `test/features/orders/order_tracking_controller_test.dart` |
| Home Pro white promo + blank cover | Missing `monospace`; capture before decode / over-scroll | Inter on code; decode + `RenderImage`; shot at scroll 0 (logo + icons + cover) | `flutter/home-ready-iphone17pro-402x874.png` |
| Order-detail / support vs Stitch | Different business states | `structure_only`; Back via real `push`/tab stack | `compare/order-detail-ready-*-side-by-side.jpg`, `support-*-ready-*-side-by-side.jpg` |
| Socket.IO auto-reconnect | Must keep production recovery | Reconnect enabled; re-auth + resubscribe; controller disconnect/resume/dispose | `lib/features/orders/data/tracking_socket.dart` |

## Findings (2026-09-13 remaining visual pass)

| Finding | Diagnosis | Result | Evidence |
| --- | --- | --- | --- |
| SE text 1.3 title/price squeeze | Production `Row` name\|price | Stack when viewport &lt; 390 or large text; croissant name+photo | `flutter/product-detail-ready-se-375x667-text-1.3.png` |
| Configure qty vs name | Qty beside title | Name full width; price + stepper on lower row | `flutter/product-options-ready-se-375x667.png` |
| Home logo square | Asset is rounded app-icon PNG, not a decode miss | No further production swap this pass | `flutter/home-ready-se-375x667.png` |
| Category fork on groceries | Fixture keys + incomplete aliases | Aliases + slug fallback; strip uses Stitch-like keys | `flutter/home-ready-se-375x667.png` |
| Arabic tofu on settings tile | Mixed `Arabe (العربية)` had `rtl: false` so no fallback; first-run RTL tile already rendered | Fallback when Arabic script present; Geeza Pro in tests | `flutter/account-language-ready-se-375x667.png`, `flutter/language-ready-se-375x667.png` |
| Address helper vs sticky CTA | Padding + 1.3 row of lat/lng | Extra padding; stacked coords; helper visible above Save (ready/scroll/keyboard/1.3) | `flutter/address-form-*-se-375x667*.png` |
| Payment truncated / dup refs | Badge shared row; cancel `#ref` + summary | Payment on own line; cancel/tracking single ref | `flutter/orders-in-progress-ready-se-375x667.png`, `order-cancel-form-ready-se-375x667.png`, `tracking-waiting-ready-se-375x667.png` |
| Empty rating claimed a moyenne | Same copy as rated summary | Empty vs rated strings | `flutter/merchant-reviews-empty-se-375x667.png` vs `merchant-reviews-ready-se-375x667.png` |
| Tracking vs Stitch préparation | Incompatible fulfillment stage | `structure_only` — not matched | `compare/tracking-waiting-ready-se-375x667-side-by-side.jpg` |

## Findings (2026-09-13 inspect, earlier close-out)

| Finding | Diagnosis | Result | Evidence |
| --- | --- | --- | --- |
| Home logo solid square | Production: `ColorFiltered` + `BlendMode.srcIn` white on `assets/branding/speedygo_logo.png` (500×500 mark exists). Not capture decode failure. | `HomeHeader` `ClipRRect` + `Image.asset` `BoxFit.cover`; capture precache + `_assertDecodedImage` on `home-logo` | `flutter/home-ready-se-375x667.png`, `flutter/home-ready-iphone17pro-402x874.png`, `flutter/home-ready-se-375x667-text-1.3.png`, `compare/home-ready-se-375x667-side-by-side.jpg` |
| Greeting fist | Unicode is U+1F44B (`AppStrings.homeGreeting`). Fist was **test rendering** (monochrome Noto Emoji). Production iOS uses Apple Color Emoji. | Tests load Noto Color Emoji (not mono); `fontFamilyFallback` Apple/Noto Color Emoji | same home PNGs — waving hand visible |
| Address helper under CTA | Implementation/`isDefault` wording sat in the last ListView slot under sticky Enregistrer | Coords hint stays by lat/lng; default copy removed from form (list action); extra list padding; Save sticky | `flutter/address-form-ready-se-375x667.png`, `address-form-keyboard-se-375x667.png`, `address-form-ready-iphone17pro-402x874.png`, `address-form-keyboard-iphone17pro-402x874.png`, `address-form-ready-se-375x667-text-1.3.png`, `address-form-keyboard-se-375x667-text-1.3.png` |
| Tracking duplicate public id | App bar subtitle + centered raw ref | Single `#${publicReference}` `Key('tracking-reference')`; waiting fixture CREATED+PENDING_ACCEPTANCE without SEARCHING delivery | `flutter/tracking-waiting-ready-se-375x667.png`, `tracking-waiting-ready-iphone17pro-402x874.png`, `compare/tracking-waiting-ready-se-375x667-side-by-side.jpg` |
| Analyzer infos | unused import + `prefer_const_constructors` | `flutter analyze` **exit 0**, `No issues found!` (rules unchanged) | source tree |

## Findings (2026-09-13 earlier inspect)

| Finding | Diagnosis | Result | Evidence |
| --- | --- | --- | --- |
| Hero Back/actions mid-image | Production: overlay `Row` filled the hero `Stack`. Not capture framing. | `HeroOverlayBar` `Positioned` top + SafeArea | `flutter/product-detail-ready-se-375x667.png`, `flutter/storefront-ready-se-375x667.png`, `compare/product-detail-ready-se-375x667-side-by-side.jpg` |
| SE « Personnaliser » mid-word | Sticky width used padded constraints (`< 390`) so Pro also stacked | Stack on **viewport** width `< 390` or text scale; SE stacks, Pro row; word intact at default + 1.3 | `flutter/product-detail-ready-se-375x667.png`, `flutter/product-detail-ready-iphone17pro-402x874.png`, `flutter/product-detail-ready-se-375x667-text-1.3.png` |
| Storefront identity | Missing overlapping card was layout, not missing ETA | Overlapping identity card + hours + rating from merchant summary GET; underline tabs from catalog names (no Populaires) | `flutter/storefront-ready-se-375x667.png`, `compare/storefront-ready-se-375x667-side-by-side.jpg` |
| Categories SE photo | Decode not asserted; later jobs overwrote goldens | Precache + decode assert; feature photograph present | `flutter/categories-ready-se-375x667.png`, `stitch/categories-ready-se-375x667.png` |
| Stitch categories feature card | Render omitted restaurant hero | Stitch PNG includes Restaurants feature card | `stitch/categories-ready-se-375x667.png` |
| Configure states | Only one capture | Unselected disabled CTA + selected valid CTA; qty in summary card | `flutter/product-options-unselected-se-375x667.png`, `flutter/product-options-ready-se-375x667.png` vs `compare/product-options-ready-se-375x667-side-by-side.jpg` |
| Cart chrome/copy | Duplicate headings / server-totals wording | Card surfaces, merchant icon+Commande chez, single merchandise subtotal, checkout-calc hint | `flutter/cart-ready-se-375x667.png`, `compare/cart-ready-se-375x667-side-by-side.jpg` |
| Checkout Recommander pair | `r_vision_de_la_commande_speedygo` title is Recommander | **reference_missing**; Flutter-only top + scrolled (promo field); sticky `checkout-sticky-total` | `flutter/checkout-review-ready-se-375x667.png`, `flutter/checkout-review-scrolled-se-375x667.png` |
| Promotions / ratings APIs | Must inspect contracts | `GET /customer/promotions` (`ApiEndpoints.customerPromotionsPath`); merchant summaries `GET /customer/ratings/merchant-summaries` and per-merchant summary | `flutter/promotions-ready-se-375x667.png`, `flutter/merchant-reviews-ready-se-375x667.png`, `flutter/storefront-ready-se-375x667.png` (4.7 chip) |

## Unresolved (not `human_accepted`)

| Surface | Status | Why | Exact paths |
| --- | --- | --- | --- |
| Checkout review Stitch pair | `reference_missing` / flutter_only | No valid checkout artboard; Recommander board not used | `visuals/alignment/flutter/checkout-review-ready-se-375x667.png`, `checkout-review-scrolled-se-375x667.png` (no `compare/checkout-review-*-side-by-side.jpg`) |
| Tracking vs Stitch préparation | `structure_only` | Incompatible stage — JPEG labeled STITCH STRUCTURE, not matched | `compare/tracking-waiting-ready-*-side-by-side.jpg` |
| Tracking SE timeline | residual layout | Waiting + one `#ref`; steps reachable by scroll (not shrunk); Stitch pair `structure_only` | `visuals/alignment/flutter/tracking-waiting-ready-se-375x667.png` vs `…-iphone17pro-402x874.png` |
| Order detail / support create+detail vs Stitch | `structure_only` | Flutter awaiting-merchant / honest support ≠ Stitch delivered / chips / photos | `compare/order-detail-ready-*-side-by-side.jpg`, `support-create-ready-*-side-by-side.jpg`, `support-detail-ready-*-side-by-side.jpg` |
| Favorites / legal / delete / notif prefs / delivery code / receipt / checkout notes | `blocked` | Honest D — no API | existing flutter honest PNGs |

## Flutter-only / reference_missing

| Slug | Path | Note |
| --- | --- | --- |
| `checkout-review-ready` | `visuals/alignment/flutter/checkout-review-ready-se-375x667.png` (and Pro) | No valid checkout Stitch board; Recommander HTML was removed from `stitch/` |
| `checkout-review-scrolled` | `visuals/alignment/flutter/checkout-review-scrolled-se-375x667.png` | Promo field + sticky payable |
| `product-options-unselected` | `visuals/alignment/flutter/product-options-unselected-*.png` | Disabled CTA |
| `product-detail-plain-ready` | `visuals/alignment/flutter/product-detail-plain-ready-*.png` | No-options add-to-cart |

There is **no** `compare/checkout-review-*-side-by-side.jpg` (invalid pair deleted).

## Paired compare JPEGs

`visuals/alignment/compare/{slug}-{viewport}-side-by-side.jpg`  
Viewports: `se-375x667`, `iphone17pro-402x874`.  
Last compare run: `compared=34` paired + `structure_only=8` (`python3 audit/scripts/compare_alignment_visuals.py`, missing=0) — 4 slugs × 2 viewports structure_only: tracking-waiting, order-detail, support-create, support-detail. Checkout review is **not** in `SLUGS` (flutter_only / `reference_missing`).

Paired slugs: `product-detail-ready`, `product-options-ready`, `storefront-ready`, `categories-ready`, `cart-ready`, `home-ready`, `merchant-reviews-ready`, `merchant-info-ready`, `order-rate-ready`, `order-write-review-ready`, `support-create-ready`, `support-detail-ready`, `orders-in-progress-ready`, `order-detail-ready`, `account-hub-ready`, `account-language-ready`, `sessions-ready`, `promotions-ready`, `addresses-ready`, `checkout-method-ready`, `tracking-waiting-ready`.

## Remaining Flutter evidence (exact slugs in `visuals/alignment/flutter/`)

Auth: `splash-frame-static-se-375x667.png`, `language-ready-*`, `welcome-ready-*`, `welcome-order-ready-*`, `welcome-track-ready-*`, `phone-ready-*`, `otp-ready-*`, `restore-loading-ready-*`, `profile-setup-ready-*`.

Home/catalog extras: `home-ready-*`, `category-results-ready-*`, `search-idle-*`, `search-results-ready-*`, `favorites-ready-*` (blocked UI).

Orders: `orders-in-progress-ready-*`, `orders-cancelled-ready-*`, `order-detail-ready-*`, `order-confirmation-ready-*`, `order-cancel-form-ready-*`, `order-rate-ready-*`, `order-write-review-ready-*`.

Ratings: `merchant-reviews-ready-*`, `merchant-reviews-empty-*`.

Account/support: `account-hub-ready-*`, `sessions-ready-*`, `notifications-ready-*`, `notification-prefs-ready-*`, `legal-ready-*`, `account-delete-ready-*`, `support-create-ready-*`, `support-list-ready-*`, `support-detail-ready-*`, `logout-sheet-ready-*`, `location-permission-ready-*`, `location-confirm-ready-*`.

## Preserved

- `audit/customer-visual-review-pilot.zip` — not modified
- `audit/customer-visual-review-shopping.zip` — not modified
- `audit/customer-visual-review.zip` — not acceptance
