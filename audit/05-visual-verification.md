# Visual verification

Populated **mocked** widget goldens vs Stitch HTML rendered at matching logical viewports. Empty-shell captures from the previous pass remain under `audit/visuals/widget/` (not Stitch proof). This pass does **not** claim pixel-identical.

## Viewports

| Target | Logical size | How obtained | Evidence |
| --- | --- | --- | --- |
| Stitch HTML | typically **390×844** artboard, rendered into the viewport | Chrome headless of `screens/CustomerScreens/*/code.html` (no `screen.png` files) | `audit/visuals/stitch/` |
| iPhone SE | **375×667** | requested; widget DPR 2 | `audit/visuals/widget/mocked/*-se-375x667.png` |
| iPhone 17 Pro | **402×874** | CoreSimulator 1206×2622 @3x | `*-iphone17pro-402x874.png`; sim still **Shutdown** |
| Text 1.3 | SE + `textScaleFactorTestValue = 1.3` | widget | `*-text-1.3.png` including keyboard insets |

Side-by-side (labeled Stitch | Flutter): `audit/visuals/compare/` — prior full-matrix **compared=105** remains on disk but many goldens are **INVALID for acceptance** (Ahem tofu, wrong routes, etc.). Human review for sign-off: use [`customer-visual-review-pilot.zip`](customer-visual-review-pilot.zip) (six SE pilots with repaired fonts/routes). Full-matrix re-capture deferred. Classification: [`missing-comparison-classification.md`](missing-comparison-classification.md).

Widget engines: prior `AUDIT_CAPTURE` suite preserved; pilots via `audit_pilot_capture_test.dart` + `test/flutter_test_config.dart` (Inter, Material Icons, Noto Emoji). All fixture captures are labelled **mocked**.

## Live photographed product (content + gesture)

| Product | `product_images` | Live evidence |
| --- | --- | --- |
| Pain khobz `…30402` | **none** | Placeholder is correct (**content gap**, not a layout bug). |
| Croissant au beurre `…30421` | JPEG object `6dd65ff2…` on local storage | Live gestures: menu thumbnail + detail `authenticated-catalog-image`. |
| Pain au chocolat `…30422` | JPEG object `685d95c1…` | Bound; available as alternate. |

Focused live: `integration_test/audit_live_product_photo_test.dart` **exit 0**, `audit/live/product-photo-gestures.json` `status=passed`, shots `live-photo-menu.png` / `live-photo-product.png`. Do not treat storefront cover as product photography.

## Compared — prior pass (still valid)

| Stitch HTML | Route / state | Comparison | Remaining differences |
| --- | --- | --- | --- |
| `accueil_speedygo` | `/home` populated | `compare/home-ready-*-side-by-side.png` | 5 FR tabs vs Stitch 4 EN; **Commerces** vs nearby claim; no invented ETA/ratings. |
| `toutes_les_cat_gories_speedygo_c_012` | `/home/categories` | `categories-ready-*` | Search + explorer cards; 5-tab shell. |
| `restaurants_speedygo` | category results | `category-results-ready-*` | Live names/hours; no Stitch ETA/“Populaire”. |
| `d_tails_du_marchand_speedygo` | storefront | `storefront-ready-*` | Cover may be placeholder in mocks. |
| `d_tails_du_produit_speedygo` / `configuration_du_produit_speedygo` | product + options | `product-ready-*` / `product-options-ready-*` | Sticky CTA; SE overflow fixed earlier. |
| `recherche_speedygo` / `r_sultats_de_recherche_speedygo` | search | `search-idle-*` / `search-results-ready-*` | No fabricated recents. |
| `panier_speedygo_c_025` | `/cart` | `cart-ready-*` | Title **Panier** vs “Merchant Details” (E). |
| `s_lection_de_l_adresse_speedygo` | address picker | `checkout-address-ready-*` | |
| `r_vision_de_la_commande_speedygo` | checkout review | `checkout-review-ready-*` | **E:** HTML reorder board ≠ live review. |
| `historique_des_commandes_speedygo` / detail / Annulées list | orders | `orders-*-ready-*` | Cancel **form** compared separately below. |
| `profil_speedygo_1` / addresses / support detail / notifications / sessions | account + inbox | `account-hub-*`, `addresses-*`, `support-detail-*`, `notifications-*`, `sessions-*` | 5 FR tabs vs Stitch 4 EN. |

## Compared — this visual completion pass (mocked)

| Stitch HTML | Route / state | Widget artifact | Notes |
| --- | --- | --- | --- |
| `s_lection_de_la_langue_speedygo_c_002` | `/language` | `language-ready-*` | FR only; AR disabled (product). |
| `bienvenue_speedygo` (+ onboarding slides) | `/welcome` | `welcome-ready-*`, `welcome-order-*`, `welcome-track-*` | Hero aspect may differ from square Stitch art on SE. |
| `num_ro_de_t_l_phone_speedygo` | `/phone` | `phone-ready-*` | |
| `v_rification_otp_speedygo` | `/otp` | `otp-ready-*` | |
| `profil_speedygo_2` | `/profile` | `profile-setup-ready-*` | |
| `r_cup_ration_de_session_speedygo` | `/restore` | `restore-loading-ready-*` | Loading / restored chrome (mocked). |
| `mode_de_paiement_speedygo` | `/checkout/method` | `checkout-method-ready-*` | ELECTRONIC gated; COD selectable. Stitch sticky total bar not implemented (capability). |
| `confirmation_de_commande_speedygo` | `/orders/:id/confirmation` | `order-confirmation-ready-*` | Copy **Commande envoyée** (not merchant-confirmed). Bottom padding raised so cards clear sticky CTAs. |
| `menu_speedygo` | storefront / menu | `menu-ready-*` | Same screen as merchant detail. |
| `infos_sur_le_marchand_speedygo` | `/merchants/:id/info` | `merchant-info-ready-*` | Hours from fixture. |
| `avis_speedygo` | `/merchants/:id/reviews` | `merchant-reviews-ready-*` | Summary only; no public comments. |
| `annuler_la_commande_speedygo` (form) | `/orders/:id/cancel` | `order-cancel-form-ready-*` | List Annulées was prior pass; form padding clears sticky footer. |
| `attente_de_confirmation_speedygo` | `/orders/:id/waiting` | `tracking-waiting-ready-*` | Mocked tracking — **not** live delivery. |
| `recherche_de_livreur_speedygo` | searching-driver | `tracking-searching-ready-*` | Mocked. |
| `suivi_de_livraison_speedygo` | map focus | `tracking-map-ready-*` | Coords only; no map SDK. |
| `livreur_proximit_speedygo` | nearby | `tracking-nearby-ready-*` | Mocked. |
| `commande_termin_e_speedygo` | completed | `tracking-completed-ready-*` | Mocked. |
| `noter_la_commande_speedygo` | `/orders/:id/rate` | `order-rate-ready-*` | COMPLETED fixture. |
| `r_diger_un_avis_speedygo` | write-review | `order-write-review-ready-*` | CTA **Envoyer l’avis**. |
| `param_tres_de_la_langue_speedygo` | `/account/language` | `account-language-ready-*` | |
| `signaler_un_probl_me_speedygo` | `/support/new` | `support-create-ready-*` | Submit pinned above keyboard (`bottomNavigationBar`). |
| `l_gal_et_confidentialit_speedygo` | legal honest | `legal-ready-*` | Unsupported copy (no CMS). |
| `param_tres_des_notifications_speedygo` | prefs honest | `notification-prefs-ready-*` | No prefs API. |
| `suppression_du_compte_speedygo` | delete honest | `account-delete-ready-*` | No password field (E vs Stitch). |
| `favoris_speedygo` | `/favorites` | `favorites-ready-*` | Honest placeholder (onboarding **Out**). |
| `promotions_speedygo` | `/promotions` | `promotions-ready-*` | List placeholder; Home banner is live path. |
| `instructions_sp_ciales_speedygo` | `/checkout/notes` | `checkout-notes-ready-*` | No write field. |
| `permission_de_localisation_speedygo` | `/location-permission` | `location-permission-ready-*` | |
| `d_connexion_speedygo` | logout sheet | `logout-sheet-ready-*` | Modal from Profil. |

Also captured (no dedicated Stitch pair / missing Stitch PNG this pass): `payment-methods-ready-*` (honest empty cards).

## Still unreviewed / viewport gaps

| Item | Why |
| --- | --- |
| Splash / payment mocks on **17 Pro** widget | SE frames + payment states captured; 17 Pro Flutter not golden’d (9 compare missing rows). |
| Electronic payment **live** | Gate off; mocks ≠ Chargily proof. |
| Human pixel acceptance | Package generated; conclusions pending reviewer in zip INDEX. |

## Unsupported / preview-only (do not implement merely for artboards)

| Stitch | Classification |
| --- | --- |
| `code_de_livraison_speedygo` | Missing Customer delivery-code API |
| `re_u_speedygo` | Preview-only NavScaffold |
| `instructions_de_livraison_speedygo` | Preview-only |
| Electronic payment success / redirect as live | Missing external Chargily config |

## Actionable Flutter fixes (bookkeeping + prior)

- Order confirmation + cancel form: scroll bottom padding **140** (kept after SE/text/keyboard verification).
- Confirmation money row: `Flexible` + ellipsis (SE overflow 60px found during padding check).
- Support create: pin submit in `bottomNavigationBar` with keyboard `viewInsets`.
- Live classify / product harness: prior pass (unchanged).

Not changed (honest): 5-tab FR shell, Panier title, no ETA/ratings/payment-success/public reviews/delivery codes, no avatar/email, no nearby claim, no map SDK.

## Live device

SE live acceptance (prior): `status=passed` catalog/account gestures.  
SE live product photo (this pass): `product-photo-gestures.json` **passed** (Croissant au beurre).  
iPhone 17 Pro sim still Shutdown. Widget goldens ≠ live gesture proof except where `audit/live/shots/` are cited.
