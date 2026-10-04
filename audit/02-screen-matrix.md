# Screen / reference / route / contract matrix

Live tracker: [`../NAVIGATION_STATUS.md`](../NAVIGATION_STATUS.md). Several Stitch artboards are **states of one Flutter screen** (tracking, search, storefront, address picker). Do not expect one route per HTML folder.

Verification keys: **W** widget/unit this tree · **V** populated **mocked** Stitch HTML comparison (see [05-visual-verification.md](05-visual-verification.md)) · **C** code-inspected · **L** historical live Revue · **G** this-session live gestures (`audit/live/`, catalog/account `status=passed`) · **P** photo live (`product-photo-gestures.json`, Croissant) · **U** unverified live (ratings write, support write, payment, tracking) · **X** unsupported / preview-only.

Do not collapse: **W/V** ≠ live acceptance. **G/P** are SE read-only gestures, not pixel visual completion. Whole UI is **not** complete while human review of generated comparisons is pending and payment **live** remains gated. Review package: [`customer-visual-review.zip`](customer-visual-review.zip).

| Stitch directory | Flutter | Route | Backend | Class | Status |
| --- | --- | --- | --- | --- | --- |
| `algerian_velocity` | `AppTheme` / `AppColors` `#0A4096` | tokens | — | D | W |
| `splash_speedygo` / `splash_speedygo2` | `SplashScreen` | `/splash` | none | A/D | W, V (SE frames mocked; 17 Pro Flutter still missing) |
| onboarding 01–03 | `WelcomeScreen` | `/welcome` | none | D | W, V |
| `s_lection_de_la_langue_speedygo_c_002` | `LanguageScreen` | `/language` | none (FR only) | D | W, V |
| `param_tres_de_la_langue_speedygo` | same, `settings: true` | `/account/language` | none | D | W, V |
| `num_ro_de_t_l_phone_speedygo` | `PhoneScreen` | `/phone` | `POST /auth/otp/request` | — | W, V, L hist. |
| `v_rification_otp_speedygo` | `OtpScreen` | `/otp` | `POST /auth/otp/verify` | — | W, V, L hist. |
| `r_cup_ration_de_session_speedygo` | restore flow | `/restore` | `POST /auth/refresh` + `GET /customer/me` | — | W, V, C |
| `profil_speedygo_2` | `ProfileSetupScreen` | `/profile` | `POST /customer/profile` | — | W, V |
| `d_connexion_speedygo` | `LogoutSheet` | modal from `/account` | `POST /auth/logout` | — | W, V |
| `accueil_speedygo` | `HomeScreen` | `/home` | verticals, branches, promotions, active order, unread | D names | W, V, G |
| `d_tails_du_marchand_speedygo` | storefront | `/merchants/:id` | branch + categories + products | D | W, V, G |
| `toutes_les_cat_gories_speedygo_c_012` | `CommerceVerticalsScreen` | `/home/categories`, `/categories` | `GET /customer/commerce-verticals` | — | W, V, G |
| `restaurants_speedygo` | category results | `/home/categories/results` | `GET /customer/branches` | D | W, V, G (Boulangeries) |
| `recherche_speedygo` | `SearchScreen` | `/search` | search API | no fake recents | W, V |
| `r_sultats_de_recherche_speedygo` | same + Back field in AppBar | `/search/results` | same | — | W, V |
| `menu_speedygo` / `infos_sur_le_marchand_speedygo` / `avis_speedygo` | storefront aliases | `/merchants/:id`, `/info`, `/reviews` | branch + hours + rating summary | D | W, V |
| `d_tails_du_produit_speedygo` / `configuration_du_produit_speedygo` | product + options | `/merchants/:b/products/:p` | product DTO + cart POST | — | W, V, G (Croissant photo; Pain khobz unbound content gap) |
| `favoris_speedygo` | honest placeholder | `/favorites` | **none** (onboarding **Out**) | optional | W, V, X |
| `promotions_speedygo` | placeholder list; Home banner live | `/promotions` vs Home | `GET /customer/promotions` on Home only | C | W, V, X list |
| `panier_speedygo_c_025` | `CartScreen` title **Panier** | `/cart` | cart GET/PATCH/DELETE | E title | W, V |
| `instructions_sp_ciales_speedygo` | `AccountStatusScreen` | `/checkout/notes` | no write field | C | W, V, X |
| `r_vision_de_la_commande_speedygo` | checkout review (Stitch HTML at 375 is a reorder board — **E**) | `/checkout/review` | `POST /checkout/preview` | E | W, V |
| `mode_de_paiement_speedygo` | checkout method (COD; ELECTRONIC gated) | `/checkout/method` | create order | C | W, V |
| Profile “Méthodes de paiement” | honest empty cards (saved cards **not** MVP) | `/account/payment-methods` | none stored | optional | W, V, X |
| address artboards (2) | `AddressPickerScreen` / form / confirm | `/checkout/address*`, `/account/addresses`, `/addresses/form` | address CRUD + default | — | W, V, G (saved list read only) |
| `permission_de_localisation_speedygo` | location permission | `/location-permission` | OS | — | W, V |
| `soumission_de_la_commande_speedygo` | place-order on review | — | `POST /customer/orders` | — | W (same as review) |
| `confirmation_de_commande_speedygo` | `OrderConfirmationScreen` **Commande envoyée** | `/orders/:id/confirmation` | GET order | E Stitch “confirmée” | W, V |
| `historique_des_commandes_speedygo` | `OrdersTabScreen` + pagination + filters | `/orders` | `GET /customer/orders` | — | W, V, G (list read) |
| `d_tails_de_la_commande_speedygo` | `OrderDetailScreen` | `/orders/:id` | GET order | — | W, V |
| tracking artboards (waiting, searching, map, nearby, completed, status) | `OrderTrackingScreen` | `/orders/:id/{waiting,tracking,…}` | GET tracking + Socket.IO | C | W, V mocked (U live delivery) |
| `code_de_livraison_speedygo` | productDecision | `/orders/:id/delivery-code` | **no Customer API** | C | W, X |
| `annuler_la_commande_speedygo` | cancel form + Annulées list | `/orders/:id/cancel` + Annulées | `POST .../cancel` | E 48h | W, V form+list |
| `paiement_speedygo` / redirect | electronic payment screens | `/orders/:id/payment*` | payment GET/initiate | C gated | W, V mocked (SE); U live (no Chargily) |
| `re_u_speedygo` | placeholder | `/orders/:id/receipt` | none | P | C, P |
| `noter_la_commande_speedygo` / `r_diger_un_avis_speedygo` | ratings; CTA **Envoyer l’avis** | `/orders/:id/rate`, `write-review` | ratings POST/GET | E “Publier” | W, V |
| `notifications_speedygo` | inbox | `/alerts` | notifications | — | W, V, G |
| `param_tres_des_notifications_speedygo` | honest prefs | `/account/notifications`, `/alerts/permission` | no prefs API | C | W, V, X |
| `profil_speedygo_1` | `AccountHubScreen` (5 FR tabs, not EN 4-tab) | `/account` | me | E tabs | W, V, G |
| `s_curit_et_sessions_actives_speedygo` | `ActiveSessionsScreen` OTP guidance; logout-all includes this session | `/account/security` | sessions + logout-all | E 2FA / “autres sessions” | W, V |
| `l_gal_et_confidentialit_speedygo` | honest unsupported copy (CMS **not** MVP) | `/legal/terms`, `/legal/privacy` | **no public legal API** | unfinished | W, V, X |
| `suppression_du_compte_speedygo` | honest; no password field (onboarding **Out**) | `/account/delete` | **no delete API** | E password | W, V, X |
| `signaler_un_probl_me_speedygo` / ticket | support create/list/detail | `/support*` | support | U live create | W, V create+list+detail, G list read |
| directory / home-design | preview | `/directory*` | fixtures | P | W |

## Shell vs pushed-detail

| Kind | Examples | Back |
| --- | --- | --- |
| Tab roots | Home, Search, Orders, Alerts, Account | no Back; tab switch |
| Pushed | storefront, product, cart, checkout, order, support, addresses, legal, security, honest status | `popOrParent` |

## Reference mismatches (summary)

See [03-findings.md](03-findings.md). Stitch English four-tab chrome, cart titled “Merchant Details”, “Commande confirmée” before merchant accept, receipt “Paiement Réussi”, 48h refund, password delete, 2FA, “autres sessions” are **E** (reference contradictions) with **A** live copy already corrected where the Flutter string was wrong.
