# UI alignment matrix (authoritative tracker)

**Updated:** 2026-09-14. Stitch = visual source of truth. Backend contracts = data source of truth.  
Review package target: `audit/customer-ui-alignment-review.zip`.  
Do **not** use `customer-visual-review.zip` as acceptance evidence.  
Statuses: `not_reviewed` · `evidence_invalid` · `needs_visual_correction` · `implementer_reviewed` · `human_accepted` · `blocked`.

Hidden design previews (`/directory*`, `HomeDesignPreviewScreen`) are **out of production review**.

## Legend (difference classes)

| Class | Meaning |
| --- | --- |
| A | Presentation defect — fix in Flutter |
| B | Supported data not wired — use existing contract |
| C | Fixture / content differs from Stitch sample — label only |
| D | Missing capability — honest UI, document |
| E | Contradictory Stitch copy — accurate wording, keep hierarchy |

## Shell / design system

| Feature | Widget | Route | Stitch | State | Status | Diffs | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Tokens | `AppTheme` / `AppColors` | — | `algerian_velocity` | Inter + `#0A4096` + surfaces | `implementer_reviewed` | A: textTheme sizes aligned to DESIGN.md (2026-09-12) | theme source |
| Tab shell | `HomeShell` | tabs | `profil_speedygo_1` chrome | 5 FR tabs | `implementer_reviewed` | E: Stitch EN 4-tab | `visuals/alignment/flutter/account-hub-ready-se-375x667.png` |

## Auth / onboarding

| Feature | Widget | Route | Stitch | State | Status | Diffs | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Splash | `SplashScreen` | `/splash` | `splash_speedygo` (+`splash_speedygo2`) | brand | `implementer_reviewed` | A: splash2 composition; E: splash1 loading/version omitted | `visuals/alignment/flutter/splash-frame-static-se-375x667.png` |
| Language first-run | `LanguageScreen` | `/language` | `s_lection_de_la_langue_speedygo_c_002` | FR only | `implementer_reviewed` | D: AR disabled + badge | `visuals/alignment/flutter/language-ready-se-375x667.png` |
| Welcome | `WelcomeScreen` | `/welcome` | `bienvenue_speedygo` + onboarding 01–03 | carousel | `implementer_reviewed` | E: onboarding 01–03 preferred | `visuals/alignment/flutter/welcome-ready-se-375x667.png` |
| Phone | `PhoneScreen` | `/phone` | `num_ro_de_t_l_phone_speedygo` | entry | `implementer_reviewed` | A: sticky frosted CTA | `visuals/alignment/flutter/phone-ready-se-375x667.png` |
| OTP | `OtpScreen` | `/otp` | `v_rification_otp_speedygo` | entry | `implementer_reviewed` | A: cells + sticky verify | `visuals/alignment/flutter/otp-ready-se-375x667.png` |
| Restore | `RestoreScreen` | `/restore` | `r_cup_ration_de_session_speedygo` | refresh | `implementer_reviewed` | D: no in-progress order card | `visuals/alignment/flutter/restore-loading-ready-se-375x667.png` |
| Profile setup | `ProfileSetupScreen` | `/profile` | `profil_speedygo_2` | create | `implementer_reviewed` | D: no email/avatar upload | `visuals/alignment/flutter/profile-setup-ready-se-375x667.png` |

## Home / catalog

| Feature | Widget | Route | Stitch | State | Status | Diffs | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Home | `HomeScreen` | `/home` | `accueil_speedygo` | ready | `implementer_reviewed` | Logo + category icons kept. Promo code uses Inter (not missing `monospace`). Cover decode asserted before Pro recapture. C fixture names; D no ETA/proximity; E **Commerces** vs nearby | `visuals/alignment/flutter/home-ready-se-375x667.png`, `home-ready-iphone17pro-402x874.png`, `home-ready-se-375x667-text-1.3.png`; compare `visuals/alignment/compare/home-ready-se-375x667-side-by-side.jpg` |
| Categories | `CommerceVerticalsScreen` | `/home/categories` | `toutes_les_cat_gories_speedygo_c_012` | loaded | `implementer_reviewed` | C grid names; feature photo asserted before capture | `visuals/alignment/flutter/categories-ready-se-375x667.png` |
| Category results | `StorefrontListScreen` | `/home/categories/results` | `restaurants_speedygo` | list | `implementer_reviewed` | C fixture | `visuals/alignment/flutter/category-results-ready-se-375x667.png` |
| Storefront | `StorefrontDetailScreen` | `/merchants/:id` | `d_tails_du_marchand_speedygo` | menu | `implementer_reviewed` | A overlapping identity card + tab underline; D no cuisine/ETA/fees/min/promo-apply; rating from GET summary | `visuals/alignment/flutter/storefront-ready-se-375x667.png` |
| Merchant info | `StorefrontInfoScreen` | `/merchants/:id/info` | `infos_sur_le_marchand_speedygo` | hours | `implementer_reviewed` | D no map/payments | `visuals/alignment/flutter/merchant-info-ready-se-375x667.png` |
| Reviews summary | `MerchantReviewsScreen` | `/merchants/:id/reviews` | `avis_speedygo` | summary + empty | `implementer_reviewed` | D no public comments/filters; empty copy does not claim a moyenne | `visuals/alignment/flutter/merchant-reviews-ready-se-375x667.png`, `merchant-reviews-empty-se-375x667.png` |
| **Product detail** | `ProductDetailScreen` | `/merchants/:b/products/:p` | `d_tails_du_produit_speedygo` | with/without options | `implementer_reviewed` | SE / text 1.3 stacks title then price; croissant name+photo coherent; sticky « Personnaliser »; D no fav/share/ETA/nutrition | `visuals/alignment/flutter/product-detail-ready-se-375x667.png`, `product-detail-ready-se-375x667-text-1.3.png`, `product-detail-plain-ready-se-375x667.png`; compare `visuals/alignment/compare/product-detail-ready-se-375x667-side-by-side.jpg` |
| Product configure | `ProductConfigureScreen` | `…/configure` | `configuration_du_produit_speedygo` | unselected + selected | `implementer_reviewed` | Summary: name full width; price + qty on lower row; D no special instructions | unselected: `product-options-unselected-se-375x667.png`; selected: `product-options-ready-se-375x667.png` |
| Favorites | status | `/favorites` | `favoris_speedygo` | empty | `blocked` | D no favorites API | `visuals/alignment/flutter/favorites-ready-se-375x667.png` |
| Promotions list | `PromotionsListScreen` | `/promotions` | `promotions_speedygo` | list | `implementer_reviewed` | B wired `GET /customer/promotions`; D stitch filters/apply-from-list; checkout remains discount authority | `visuals/alignment/flutter/promotions-ready-se-375x667.png` |

## Cart / addresses / checkout

| Feature | Widget | Route | Stitch | State | Status | Diffs | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Cart | `CartScreen` | `/cart` | `panier_speedygo_c_025` | filled | `implementer_reviewed` | E Stitch app bar “Merchant Details”; merchandise subtotal only | `visuals/alignment/flutter/cart-ready-se-375x667.png` |
| Checkout review | `CheckoutReviewScreen` | `/checkout/review` | — (`r_vision_de_la_commande_speedygo` is Recommander) | COD preview | `implementer_reviewed` | **reference_missing** for Stitch pair; sticky `checkout-sticky-total` | `flutter/checkout-review-ready-se-375x667.png`, `flutter/checkout-review-scrolled-se-375x667.png` |
| Promo | `CheckoutReviewScreen` | `/checkout/review` | — | keyboard | `implementer_reviewed` | Flutter-only; sticky payable kept | `visuals/alignment/flutter/checkout-review-keyboard-se-375x667-text-1.3.png` |
| Payment method | `CheckoutPaymentMethodScreen` | `/checkout/method` | `mode_de_paiement_speedygo` | COD / gated | `implementer_reviewed` | D ELECTRONIC gated | `visuals/alignment/flutter/checkout-method-ready-se-375x667.png` |
| Address list | `AddressListScreen` | `/account/addresses` | `adresses_enregistr_es_speedygo` | list | `implementer_reviewed` | | `visuals/alignment/flutter/addresses-ready-se-375x667.png` |
| Address form | `AddressFormScreen` | `/addresses/form` | `ajouter_ou_modifier_une_adresse_speedygo` | create | `implementer_reviewed` | Helper above sticky Save; SE/1.3 keyboard: `viewInsets.bottom=280`, Save hittable with `rect.bottom ≤ viewHeight−inset`; D no recipient/phone/wilaya | `visuals/alignment/flutter/address-form-ready-se-375x667.png`, `address-form-ready-iphone17pro-402x874.png`, `address-form-scrolled-se-375x667.png`, `address-form-scrolled-iphone17pro-402x874.png`, `address-form-keyboard-se-375x667.png`, `address-form-keyboard-iphone17pro-402x874.png`, `address-form-ready-se-375x667-text-1.3.png`, `address-form-scrolled-se-375x667-text-1.3.png`, `address-form-keyboard-se-375x667-text-1.3.png` |
| Location permission | `LocationPermissionScreen` | `/location-permission` | `permission_de_localisation_speedygo` | prompt | `implementer_reviewed` | E Stitch nearby merchants | `visuals/alignment/flutter/location-permission-ready-se-375x667.png` |
| Location confirm | `LocationConfirmScreen` | `/addresses/confirm-location` | `confirmation_de_l_emplacement_speedygo` | map | `implementer_reviewed` | D no map tiles | `visuals/alignment/flutter/location-confirm-ready-se-375x667.png` |
| Checkout notes | status | `/checkout/notes` | `instructions_sp_ciales_speedygo` | — | `blocked` | D no field | honest |

## Orders / payment / tracking

| Feature | Widget | Route | Stitch | State | Status | Diffs | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Orders tab | `OrdersTabScreen` | `/orders` | `historique_des_commandes_speedygo` | filters | `implementer_reviewed` | Badge on title row; `date · Paiement à la livraison` full width (no squeeze); D no merchant/ETA/reorder | `visuals/alignment/flutter/orders-in-progress-ready-se-375x667.png` |
| Order detail | `OrderDetailScreen` | `/orders/:id` | `d_tails_de_la_commande_speedygo` | awaiting merchant | `structure_only` vs Stitch | Stitch is delivered + Recommander; Flutter is awaiting merchant (contract-accurate). Back via Commandes tab → tile. D no delivery code/driver/reorder/receipt | `visuals/alignment/flutter/order-detail-ready-se-375x667.png`; compare `visuals/alignment/compare/order-detail-ready-se-375x667-side-by-side.jpg` (STITCH STRUCTURE) |
| Confirmation | `OrderConfirmationScreen` | `/orders/:id/confirmation` | `confirmation_de_commande_speedygo` | created | `implementer_reviewed` | E wording | `visuals/alignment/flutter/order-confirmation-ready-se-375x667.png` |
| Payment | `OrderPaymentScreen` | `/orders/:id/payment` | `paiement_speedygo` | gated | `implementer_reviewed` | D gate off | `visuals/alignment/flutter/payment-disabled-ready-se-375x667.png`, `payment-pending-ready-se-375x667.png`, `payment-succeeded-ready-se-375x667.png` |
| Tracking | `OrderTrackingScreen` | `/orders/:id/tracking` | `suivi_de_commande_*` | mocked waiting | `structure_only` vs Stitch | One `#publicReference`; Flutter waiting ≠ Stitch préparation; D no map/ETA. Timeline steps 0–4 reachable by ListView scroll on SE/Pro (not shrunk). Socket.IO reconnection + resubscribe preserved | `visuals/alignment/flutter/tracking-waiting-ready-se-375x667.png`, `tracking-waiting-ready-iphone17pro-402x874.png`; compare `visuals/alignment/compare/tracking-waiting-ready-se-375x667-side-by-side.jpg` (STITCH STRUCTURE) |
| Cancel | `OrderCancelScreen` | `/orders/:id/cancel` | `annuler_la_commande_speedygo` | form | `implementer_reviewed` | Single ref in summary card (no duplicate `#ref` under status); E no 48h bank SLA | `visuals/alignment/flutter/order-cancel-form-ready-se-375x667.png` |
| Rate / write review | `OrderRateScreen` / `OrderWriteReviewScreen` | `/orders/:id/rate` | `noter_*` / `r_diger_*` | ready | `implementer_reviewed` | D no tag chips | `visuals/alignment/flutter/order-rate-ready-se-375x667.png`, `order-write-review-ready-se-375x667.png` |
| Delivery code | status | `/orders/:id/delivery-code` | `code_de_livraison_speedygo` | — | `blocked` | D no API | honest |
| Receipt | status | `/orders/:id/receipt` | `re_u_speedygo` | — | `blocked` | P / incomplete | honest |

## Account / support

| Feature | Widget | Route | Stitch | State | Status | Diffs | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Account hub | `AccountHubScreen` | `/account` | `profil_speedygo_1` | ready | `implementer_reviewed` | E 5 FR tabs | `visuals/alignment/flutter/account-hub-ready-se-375x667.png` |
| Language settings | `LanguageScreen` | `/account/language` | `param_tres_de_la_langue_speedygo` | settings | `implementer_reviewed` | D AR disabled; mixed `Arabe (العربية)` uses Arabic fallback (Geeza Pro / Noto) | `visuals/alignment/flutter/account-language-ready-se-375x667.png` |
| Security | `ActiveSessionsScreen` | `/account/security` | `s_curit_et_sessions_actives_speedygo` | OTP + sessions | `implementer_reviewed` | E honest OTP | `visuals/alignment/flutter/sessions-ready-se-375x667.png` |
| Notifications | `NotificationInboxScreen` | `/alerts` | `notifications_speedygo` | inbox | `implementer_reviewed` | E Stitch HTML is permission artboard | `visuals/alignment/flutter/notifications-ready-se-375x667.png` |
| Notif prefs | status | `/account/notifications` | `param_tres_des_notifications_speedygo` | | `blocked` | D | `visuals/alignment/flutter/notification-prefs-ready-se-375x667.png` |
| Legal | status | `/legal/*` | `l_gal_et_confidentialit_speedygo` | | `blocked` | D | `visuals/alignment/flutter/legal-ready-se-375x667.png` |
| Delete account | status | `/account/delete` | `suppression_du_compte_speedygo` | | `blocked` | D | `visuals/alignment/flutter/account-delete-ready-se-375x667.png` |
| Support | create/list/detail | `/support*` | `signaler_*` / ticket detail | create+OPEN thread | create/detail `structure_only` vs Stitch | Stitch has order card/chips/photos; Flutter honest create + OPEN thread without photos. Back via `push` from Profil / list tile | `visuals/alignment/flutter/support-create-ready-se-375x667.png`, `support-list-ready-se-375x667.png`, `support-detail-ready-se-375x667.png`; compare `support-create-ready-*-side-by-side.jpg`, `support-detail-ready-*-side-by-side.jpg` (STITCH STRUCTURE) |
| Logout | sheet | modal | `d_connexion_speedygo` | | `implementer_reviewed` | sheet vs full-page | `visuals/alignment/flutter/logout-sheet-ready-se-375x667.png` |

## Progress notes

- 2026-09-14: Evidence/behavior close — SE 1.3 address Save above 280 keyboard inset; tracking timeline scroll-reachable SE/Pro; Home Pro promo Inter + decoded merchant cover; order-detail/support compares `structure_only` with real Back stack; Socket.IO reconnect + resubscribe kept. `human_accepted` not claimed.
- 2026-09-13: Remaining visual findings — SE/1.3 product title stacks above price; configure name vs qty; category icon aliases; Arabic script fallback on mixed labels; address helper above sticky CTA (incl. 1.3 keyboard/scroll); orders payment untruncated; cancel/tracking single ref; empty-rating copy. Tracking Stitch pair `structure_only`. `human_accepted` not claimed.
- 2026-09-13: Open-findings close — home logo without ColorFilter (decoded before capture); greeting U+1F44B + color-emoji test fonts; address form hint placement + keyboard/1.3 Save; tracking single `#ref` + awaiting-merchant fixture; `flutter analyze` exit 0. Checkout Stitch pair remains `reference_missing` (no Recommander compare). `human_accepted` not claimed.
- 2026-09-13: Human review follow-up — hero overlay Positioned (not capture framing); SE Personnaliser stacked CTA; storefront identity card + rating summary GET; categories decode assert + Stitch feature card render; configure unselected/selected; cart copy; checkout flutter_only vs Recommander; promotions list GET `/customer/promotions`.
- 2026-09-12: Tracking / ratings / support — `OrderTrackingScreen` soft-lift vs tracking artboards (no map provider); `OrderRateScreen` + `OrderWriteReviewScreen` + `StarRatingBar` vs `noter_*` / `r_diger_*`; support create/list/detail vs `signaler_*` / ticket detail (no chips/photos/close-ticket invented).
- 2026-09-12: Home + merchant reviews + location confirm — `HomeScreen` vs `accueil_speedygo` (Livrer à header, greeting, borderless search, category tiles + Tout voir, promo/storefront mt-8; no ETA/proximity); `MerchantReviewsScreen` vs `avis_speedygo` (summary-card hierarchy + stars; honest no-feed, no filters/distribution); `LocationConfirmScreen` vs `confirmation_de_l_emplacement_speedygo` (frosted bar, pin, bottom sheet + GPS only; no map/eligibility invent).
- 2026-09-12: Account-adjacent batch — `LanguageScreen(settings)` vs `param_tres_de_la_langue_speedygo` (FR radio + LTR preview + sticky save; AR disabled honest), `ActiveSessionsScreen` vs `s_curit_et_sessions_actives_speedygo` (OTP guidance card, no invented 2FA; session list chrome; logout-all includes this session), `NotificationInboxScreen` inbox list chrome (Stitch folder is permission artboard — not remapped to `/alerts`).
- 2026-09-12: Orders/checkout/addresses batch — `OrderDetailScreen` (status/items/payment cards + sticky actions; no invented delivery code/driver/reorder/receipt), `OrderCancelScreen` form chrome, `CheckoutPaymentMethodScreen` COD-prominent + gated ELECTRONIC (no CIB/EDAHABIA split; no sticky total), address list/form/location permission spacing & hierarchy with honest location copy.
- 2026-09-12: Auth/onboarding batch aligned to Stitch (splash2, language FR-only, welcome via onboarding 01–03, phone/OTP sticky CTAs + input chrome, restore mesh without invented order card, profile setup glow + honest photo).
- 2026-09-12: Account hub + orders list + logout sheet presentation aligned to Stitch (`profil_speedygo_1`, `historique_des_commandes_speedygo`, `d_connexion_speedygo`). Kept 5 FR tabs. No merchant/ETA/reorder/email/edit invented.
- 2026-09-12: Merchant info cards (identity/address/hours accordion), configure sticky bordered qty + CTA split, storefront hero frosted overlays (info/reviews kept; no share/fav). No invented ratings/ETA/fees.
- 2026-09-12: Product detail composition aligned to Stitch (hero overlay controls, Description heading, merchant from storefront, customize entry card, sticky split CTA). No fav/share/ETA/nutrition invented.
- Shopping batch evidence retained in `customer-visual-review-shopping.zip` (not acceptance for whole app).
- Pilot batch evidence in `customer-visual-review-pilot.zip`.
