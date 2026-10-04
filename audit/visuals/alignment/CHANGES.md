# CHANGES.md — UI alignment session (production files)

Concise list of production UI surfaces touched for Stitch alignment leading into this review package (2026-09-12). Audit scripts/tests/docs omitted.

## Design system

- `lib/app/theme/app_theme.dart` — textTheme sizes / tokens aligned to DESIGN.md (`algerian_velocity`); **contrast fix:** every textTheme style sets explicit `color: AppColors.onSurface` (was inheriting white → white-on-white titles on light surfaces)

## Catalog / shopping (2026-09-13 follow-up)

- `lib/features/catalog/presentation/widgets/hero_overlay_button.dart` — `HeroOverlayBar` top-positioned
- `lib/features/catalog/presentation/product_detail_screen.dart` — viewport hero reserve so customize card stays above stacked CTA
- `lib/features/catalog/presentation/storefront_detail_screen.dart` — overlapping identity card, hours, rating summary, underline tabs
- `lib/features/cart/presentation/widgets/sticky_qty_action_bar.dart` — stack on viewport width / text scale; optional qty
- `lib/features/cart/presentation/product_configure_screen.dart` — qty in summary card; sticky CTA only
- `lib/features/cart/presentation/cart_screen.dart` — merchant icon hierarchy; merchandise subtotal copy
- `lib/features/home/presentation/widgets/home_chrome.dart` — logo without ColorFilter; greeting color-emoji fallback
- `lib/features/addresses/presentation/address_form_screen.dart` — coords hint by fields; no default copy under sticky Save
- `lib/features/orders/presentation/order_tracking_screen.dart` — single hashed public reference
- `lib/features/orders/data/tracking_socket.dart` — Socket.IO reconnection + resubscribe (re-auth token)
- `lib/features/orders/application/order_tracking_controller.dart` — autoDispose family so tracking timers do not leak
- `lib/features/promotions/presentation/promotions_list_screen.dart` — `GET /customer/promotions`


- `lib/features/catalog/presentation/product_detail_screen.dart` — hero overlays, ~45vh media, Description, merchant row, customize card, sticky CTA split (with/without options); **contrast fix:** product title + Description heading force `AppColors.onSurface`
- `lib/features/catalog/presentation/storefront_detail_screen.dart` — frosted hero overlays (back/info/reviews); no invented share/fav/rating/ETA
- `lib/features/catalog/presentation/storefront_info_screen.dart` — identity / address / hours cards
- `lib/features/cart/presentation/product_configure_screen.dart` — sticky bordered qty + primaryContainer CTA split; no special-instructions field

## Account / orders chrome

- `lib/features/account/presentation/account_hub_screen.dart` — header card, section labels, row chrome, logout/delete
- `lib/features/account/presentation/logout_sheet.dart` — identity card, note icons, surface notes, CTA spacing
- `lib/features/orders/presentation/orders_tab_screen.dart` — tab weight/indicator, card chrome, status pills, empty typography
- `lib/features/orders/presentation/order_detail_screen.dart` — status card, items, payment totals, sticky actions; no invented delivery code / driver / reorder / receipt / service fee (capture still TBD for this package)

## Auth / onboarding (prior same-day alignment)

- `lib/features/auth/presentation/splash_screen.dart` (+ backdrop)
- `lib/features/auth/presentation/language_screen.dart`
- `lib/features/auth/presentation/welcome_screen.dart`
- `lib/features/auth/presentation/phone_screen.dart`
- `lib/features/auth/presentation/otp_screen.dart`
- `lib/features/auth/presentation/restore_screen.dart`
- `lib/features/auth/presentation/profile_setup_screen.dart`

## Capture harness (evidence only)

- `test/audit/audit_shopping_capture_test.dart` — `product-detail-ready` + `product-detail-plain-ready` (empty optionGroups → plain add-to-cart)
- `audit/scripts/render_stitch_alignment.py`
- `audit/scripts/compare_alignment_visuals.py`

## Home / reviews / location (2026-09-12)

- `lib/features/home/presentation/home_screen.dart` — category/promo/storefront spacing
- `lib/features/home/presentation/widgets/home_chrome.dart` — borderless search + Stitch padding
- `lib/features/ratings/presentation/merchant_reviews_screen.dart` — summary-card hierarchy; honest no-feed
- `lib/features/addresses/presentation/location_confirm_screen.dart` — frosted bar, pin, bottom sheet, GPS-only

## Account-adjacent / tracking / support (2026-09-12)

- `lib/features/auth/presentation/language_screen.dart` — settings chrome (FR radio, LTR preview, sticky save)
- `lib/features/account/presentation/active_sessions_screen.dart` — OTP guidance + session list chrome
- `lib/features/notifications/presentation/notification_inbox_screen.dart` — inbox card chrome
- `lib/features/orders/presentation/order_tracking_screen.dart` — soft-lift vs tracking artboards (no map)
- `lib/features/ratings/presentation/order_rate_screen.dart` / `order_write_review_screen.dart` / `star_rating_bar.dart`
- `lib/features/support/presentation/support_create_screen.dart` / list / detail — Stitch chrome, no invented chips/photos/close
