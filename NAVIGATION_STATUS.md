# Customer navigation status

Statuses may overlap. They are not a single “done” flag.

| Status | Meaning |
| --- | --- |
| `ROUTE_MAPPED` | A route, tab, or modal exists |
| `PLACEHOLDER_UI` | Generic / honest chrome, not the Stitch layout |
| `DESIGN_IMPLEMENTED` | Native Flutter matches the approved visual pass for reachable chrome |
| `API_INTEGRATED` | Live backend contract |
| `BACKEND_UNSUPPORTED` | No Customer API / schema |
| `PREVIEW_ONLY` | Fixture or fabricated state; debug/profile preview only |

Five-tab shell (live): **Accueil / Recherche / Commandes / Alertes / Profil**.

Stitch `profil_speedygo_1` uses English four-tab labels (Home / Orders / Search / Profile) and omits Alertes. That is a **reference contradiction (E)**. Live keeps the five French tabs.

Preview access (never in release):

- `--dart-define=CUSTOMER_NAV_PREVIEW=true`
- Long-press the home logo in a non-release build, then confirm

Back: pop the originating stack when possible. If there is no history, use the documented parent in `NavParents` (not always Home).

Pushed details (storefront, product, cart, checkout, order, support, addresses, legal, security) sit **above** the tab shell. Tab roots do not invent a Back affordance.

## Tracking / payment gaps (keep visible)

| Gap | Notes |
| --- | --- |
| Active-delivery live verification | No synthetic Delivery/`SEARCHING_DRIVER`/LIVE location in `speedygo_dev` for end-to-end socket proof |
| Map provider | No `google_maps_flutter` / Mapbox / API keys — status + coords only |
| Customer delivery-code API | No Customer contract; screen reports product decision |
| Chargily sandbox | Local `PAYMENT_PROVIDER` empty → in-process `test` adapter (`test://checkout/...`); Chargily keys/URLs absent — not a real sandbox |
| ELECTRONIC checkout flag | App `ELECTRONIC_PAYMENT_ENABLED` default **false**. Do not enable against `test://` only |
| Legal CMS | Honest unsupported copy; **no** public legal API. A CMS is **not** a documented MVP requirement |
| Favorites | No Customer favorites table/API. Onboarding **Out** — optional, not mandatory MVP |
| Saved payment methods | No stored cards; checkout method is COD vs gated ELECTRONIC. **Not** agreed MVP |
| Account deletion | No Customer close/delete route. Onboarding **Out** |
| Notification preferences / OS push | Inbox API exists; preference storage and OS permission request do not |
| Public review feed | Summaries only; comments are author-only. Public list is not v1 |
| Special order instructions | Address snapshot `instructions` is null in v1.0; no checkout notes field |

Fixture ids (`nav-branch`, `nav-order`, `nav-product`, `nav-ticket`, …) are never sent to APIs.

## Unresolved product decisions

| Pair | Notes |
| --- | --- |
| `profil_speedygo_1` vs `_2` | `_2` is the live first-time profile gate. `_1` is the signed-in hub. Five-tab French shell is the live product choice. |
| `s_lecteur_d_adresse_speedygo_reference` vs `s_lection_de_l_adresse_speedygo` | Two address pickers. Live uses one `AddressPickerScreen`. |
| `param_tres_de_la_langue_speedygo` vs `s_lection_de_la_langue_speedygo_c_002` | First-run picker vs in-app settings. Same locale rule: French only. |
| `panier_speedygo_c_025` | Cart title in HTML is “Merchant Details” (E). Live title is **Panier**. |
| `toutes_les_cat_gories_speedygo_c_012` | Live categories: `/home/categories` and alias `/categories` → `CommerceVerticalsScreen`. |

## Matrix

| Design | Route / modal | Statuses | Safe parent (no history) |
| --- | --- | --- | --- |
| `algerian_velocity` | tokens only | DESIGN tokens in `AppTheme` | — |
| `splash_speedygo` | `/splash` | ROUTE_MAPPED, DESIGN_IMPLEMENTED | — |
| `s_lection_de_la_langue_speedygo_c_002` | `/language` | ROUTE_MAPPED, DESIGN_IMPLEMENTED (FR only; AR disabled) | — |
| `bienvenue_speedygo` | `/welcome` | ROUTE_MAPPED, DESIGN_IMPLEMENTED | — |
| `num_ro_de_t_l_phone_speedygo` | `/phone` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | — |
| `v_rification_otp_speedygo` | `/otp` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/phone` |
| `r_cup_ration_de_session_speedygo` | `/restore` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | — |
| `profil_speedygo_2` | `/profile` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | — |
| `d_connexion_speedygo` | modal from `/account` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | dismiss |
| `accueil_speedygo` | `/home` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED (catalog, promotions banner, active order, unread) | — |
| `recherche_speedygo` | `/search` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED (tab; no fabricated recent searches) | — |
| `r_sultats_de_recherche_speedygo` | `/search/results?q=` | ROUTE_MAPPED, API_INTEGRATED (same SearchScreen, Back) | `/search` |
| `historique_des_commandes_speedygo` | `/orders` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED (list + pagination + En cours/Terminées/Annulées filters) | `/home` |
| `notifications_speedygo` | `/alerts` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | — |
| `param_tres_des_notifications_speedygo` | `/alerts/permission`, `/account/notifications` | ROUTE_MAPPED; honest unsupported prefs (no OS push request) | `/alerts` or `/account` |
| `profil_speedygo_1` | `/account` | ROUTE_MAPPED, DESIGN_IMPLEMENTED (hub chrome; 5-tab shell) | `/home` |
| `param_tres_de_la_langue_speedygo` | `/account/language` | ROUTE_MAPPED, DESIGN_IMPLEMENTED | `/account` |
| `toutes_les_cat_gories_speedygo_c_012` | `/home/categories`, `/categories` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/home` |
| `restaurants_speedygo` | `/home/categories/results?verticalId=`, `/restaurants` | ROUTE_MAPPED, API_INTEGRATED | `/home/categories` |
| `d_tails_du_marchand_speedygo` | `/merchants/:branchId` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/home` |
| `infos_sur_le_marchand_speedygo` | `/merchants/:id/info` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | merchant |
| `menu_speedygo` | `/merchants/:id/menu` | ROUTE_MAPPED, API_INTEGRATED (same storefront detail) | merchant |
| `avis_speedygo` | `/merchants/:id/reviews` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED (summary only) | merchant |
| `d_tails_du_produit_speedygo` | `/merchants/:branchId/products/:id`, `/products/:id` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | merchant |
| `configuration_du_produit_speedygo` | `.../configure` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | product |
| `favoris_speedygo` | `/favorites` | ROUTE_MAPPED, PLACEHOLDER_UI, BACKEND_UNSUPPORTED | `/home` |
| `promotions_speedygo` | `/promotions` | ROUTE_MAPPED, PLACEHOLDER_UI, BACKEND_UNSUPPORTED as a list screen; Home banner uses GET `/customer/promotions` | `/home` |
| `panier_speedygo_c_025` | `/cart` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED (title Panier; checkout gated on `cartReady`) | `/home` |
| `instructions_sp_ciales_speedygo` | `/checkout/notes` | ROUTE_MAPPED, honest unsupported (no write field) | `/cart` |
| `r_vision_de_la_commande_speedygo` | `/checkout/review` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/cart` |
| `s_lection_de_l_adresse_speedygo` / `_reference` | `/checkout/address`, `/checkout/address-picker` | ROUTE_MAPPED, API_INTEGRATED (`AddressPickerScreen`) | review or `/home` |
| `adresses_enregistr_es_speedygo` | `/account/addresses` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/account` |
| `ajouter_ou_modifier_une_adresse_speedygo` | `/addresses/form` | ROUTE_MAPPED, API_INTEGRATED | `/account/addresses` |
| `confirmation_de_l_emplacement_speedygo` | `/addresses/confirm-location` | ROUTE_MAPPED, API_INTEGRATED | `/account/addresses` |
| `permission_de_localisation_speedygo` | `/location-permission` | ROUTE_MAPPED, API_INTEGRATED | `/account/addresses` |
| `mode_de_paiement_speedygo` | `/checkout/method` | ROUTE_MAPPED, API_INTEGRATED (checkout only — not Profile) | `/checkout/review` |
| Profile “Méthodes de paiement” | `/account/payment-methods` | ROUTE_MAPPED, honest unsupported saved cards | `/account` |
| `paiement_speedygo` | `/orders/:id/payment` | ROUTE_MAPPED, API_INTEGRATED | order |
| `redirection_vers_le_paiement_speedygo` | `/orders/:id/payment/redirect` | ROUTE_MAPPED, API_INTEGRATED | payment |
| `soumission_de_la_commande_speedygo` | `/checkout/review` place-order | ROUTE_MAPPED, API_INTEGRATED | `/checkout/method` |
| `confirmation_de_commande_speedygo` | `/orders/:id/confirmation` | ROUTE_MAPPED, API_INTEGRATED (copy: **envoyée**, not merchant-confirmed; no “encaissé”) | order detail |
| `d_tails_de_la_commande_speedygo` | `/orders/:orderId` | ROUTE_MAPPED, API_INTEGRATED | `/orders` |
| `d_tails_de_l_tat_speedygo` | `/orders/:id/status` | ROUTE_MAPPED, API_INTEGRATED (`OrderTrackingScreen`) | order detail |
| `annuler_la_commande_speedygo` | `/orders/:id/cancel` | ROUTE_MAPPED, API_INTEGRATED (no 48h bank claim) | order detail |
| `attente_de_confirmation_speedygo` / `recherche_de_livreur_speedygo` / `suivi_de_commande_speedygo` / `suivi_de_livraison_speedygo` / `livreur_proximit_speedygo` / `commande_termin_e_speedygo` | `/orders/:id/waiting` … `/completed` | ROUTE_MAPPED, API_INTEGRATED (same tracking screen, focus states) | order detail |
| `code_de_livraison_speedygo` | `/orders/:id/delivery-code` | ROUTE_MAPPED, productDecision | order detail |
| `instructions_de_livraison_speedygo` | `/orders/:id/delivery-notes` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | order detail |
| `re_u_speedygo` | `/orders/:id/receipt` | ROUTE_MAPPED, PLACEHOLDER_UI, PREVIEW_ONLY | order detail |
| `noter_la_commande_speedygo` | `/orders/:id/rate` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | order detail |
| `r_diger_un_avis_speedygo` | `/orders/:id/write-review` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED (CTA **Envoyer l’avis**, not public publish) | `/orders/:id/rate` |
| `s_curit_et_sessions_actives_speedygo` | `/account/security` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED (OTP guidance; logout-all includes this session) | `/account` |
| `l_gal_et_confidentialit_speedygo` | `/legal/terms`, `/legal/privacy`, `/account/legal` | ROUTE_MAPPED, honest “contenu non servi” | `/account` |
| `suppression_du_compte_speedygo` | `/account/delete` | ROUTE_MAPPED, honest unsupported (no password field) | `/account` |
| `signaler_un_probl_me_speedygo` | `/support/new` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/support` |
| `d_tails_du_ticket_support_speedygo` | `/support/:ticketId` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/support` |
| Mes demandes | `/support` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/account` |
| directory | `/directory` | PREVIEW_ONLY | `/home` |

## This session completed (do not treat as remaining)

| Item | Notes |
| --- | --- |
| iPhone SE live gestures | Integration `audit_live_read_gestures_test` **exit 0** (`status=passed`). Restored Home. Catalog/account read gestures. |
| iPhone SE live product photo | `audit_live_product_photo_test` **exit 0**. Croissant au beurre photographed; Pain khobz unbound content gap. |
| Android APK | Preserved earlier **exit 0** (not re-run). |

## Outstanding checks (do not clear)

| Item | Notes |
| --- | --- |
| Ratings live submission | Needs an eligible **COMPLETED** synthetic order for Revue |
| Support live UI create/reply | Still unverified when OTP rate-limits |
| Active-delivery tracking / map / delivery code | No LIVE synthetic delivery; no map SDK; no Customer delivery-code API |
| Real payment sandbox | Chargily keys absent; `ELECTRONIC_PAYMENT_ENABLED` default false |
| iPhone 17 Pro live UI | Simulator `4A1C3481-…` Shutdown (not launched). Widget captures at **402×874**. |
