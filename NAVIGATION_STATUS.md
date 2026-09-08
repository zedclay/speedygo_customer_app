# Customer navigation status

This is a **navigation skeleton**. `NavScaffold` screens are **PLACEHOLDER_UI**, not completed Stitch implementations.

Statuses may overlap. They are not a single “done” flag.

| Status | Meaning |
| --- | --- |
| `ROUTE_MAPPED` | A route, tab, or modal exists |
| `PLACEHOLDER_UI` | Generic / honest chrome, not the Stitch layout |
| `DESIGN_IMPLEMENTED` | Native Flutter matches the approved auth visual pass |
| `API_INTEGRATED` | Live backend contract |
| `BACKEND_UNSUPPORTED` | No Customer API / schema |
| `PREVIEW_ONLY` | Fixture or fabricated state; debug/profile preview only |

Preview access (never in release):

- `--dart-define=CUSTOMER_NAV_PREVIEW=true`
- Long-press the home logo in a non-release build, then confirm

Fixture ids (`nav-branch`, `nav-order`, `nav-product`, `nav-ticket`, …) are never sent to APIs.

Back: pop the originating stack when possible. If there is no history, use the documented parent in `NavParents` (not always Home).

## Unresolved product decisions

Do not treat both variants as approved product screens.

| Pair | Notes |
| --- | --- |
| `profil_speedygo_1` vs `_2` | `_2` is the live first-time gate. `_1` is the signed-in hub chrome (placeholder). Which hub chrome is final is unresolved. |
| `s_lecteur_d_adresse_speedygo_reference` vs `s_lection_de_l_adresse_speedygo` | Two address pickers. `_reference` is not a rank. |
| `param_tres_de_la_langue_speedygo` vs `s_lection_de_la_langue_speedygo_c_002` | First-run picker vs in-app settings. Same locale rule: French only. |
| `panier_speedygo_c_025` | Only cart screen in the export. |
| `toutes_les_cat_gories_speedygo_c_012` | Only categories screen; API is per-branch. |

## Matrix

| Design | Route / modal | Statuses | Safe parent (no history) |
| --- | --- | --- | --- |
| `algerian_velocity` | tokens only | DESIGN tokens in `AppTheme` | — |
| `splash_speedygo` | `/splash` | ROUTE_MAPPED, DESIGN_IMPLEMENTED · PNG missing | — |
| `s_lection_de_la_langue_speedygo_c_002` | `/language` | ROUTE_MAPPED, DESIGN_IMPLEMENTED (FR only; AR disabled) | — |
| `bienvenue_speedygo` | `/welcome` | ROUTE_MAPPED, DESIGN_IMPLEMENTED | — |
| `num_ro_de_t_l_phone_speedygo` | `/phone` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | — |
| `v_rification_otp_speedygo` | `/otp` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | `/phone` |
| `r_cup_ration_de_session_speedygo` | `/restore` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | — |
| `profil_speedygo_2` | `/profile` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | — |
| `d_connexion_speedygo` | modal from `/account` | ROUTE_MAPPED, DESIGN_IMPLEMENTED, API_INTEGRATED | dismiss |
| `accueil_speedygo` | `/home` | ROUTE_MAPPED, DESIGN_IMPLEMENTED (chrome); catalog/photos/eligibility unwired; no fabricated order | — |
| `recherche_speedygo` | `/search` | ROUTE_MAPPED, PLACEHOLDER_UI | `/home` |
| `r_sultats_de_recherche_speedygo` | `/search/results?q=` | ROUTE_MAPPED, PLACEHOLDER_UI | `/search` |
| `historique_des_commandes_speedygo` | `/orders` | ROUTE_MAPPED, PLACEHOLDER_UI | `/home` |
| `notifications_speedygo` | `/alerts`, `/alerts/permission` | ROUTE_MAPPED, PLACEHOLDER_UI | `/alerts` |
| `profil_speedygo_1` | `/account` | ROUTE_MAPPED, PLACEHOLDER_UI · variant unresolved | `/home` |
| `param_tres_de_la_langue_speedygo` | `/account/language` | ROUTE_MAPPED, PLACEHOLDER_UI · variant unresolved | `/account` |
| `toutes_les_cat_gories_speedygo_c_012` | `/categories` | ROUTE_MAPPED, PLACEHOLDER_UI | `/home` |
| `restaurants_speedygo` | `/restaurants` | ROUTE_MAPPED, PLACEHOLDER_UI | `/home` |
| `d_tails_du_marchand_speedygo` | `/merchants/:branchId` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | `/restaurants` |
| `infos_sur_le_marchand_speedygo` | `/merchants/:id/info` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | merchant |
| `menu_speedygo` | `/merchants/:id/menu` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | merchant |
| `avis_speedygo` | `/merchants/:id/reviews` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | merchant |
| `d_tails_du_produit_speedygo` | `/products/:productId` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | `/restaurants` |
| `configuration_du_produit_speedygo` | `/products/:id/configure` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | product |
| `favoris_speedygo` | `/favorites` | ROUTE_MAPPED, PLACEHOLDER_UI, BACKEND_UNSUPPORTED | `/home` |
| `promotions_speedygo` | `/promotions` | ROUTE_MAPPED, PLACEHOLDER_UI, BACKEND_UNSUPPORTED | `/home` |
| `panier_speedygo_c_025` | `/cart` | ROUTE_MAPPED, PLACEHOLDER_UI | `/home` |
| `instructions_sp_ciales_speedygo` | `/checkout/notes` | ROUTE_MAPPED, PLACEHOLDER_UI | `/cart` |
| `r_vision_de_la_commande_speedygo` | `/checkout/review` | ROUTE_MAPPED, PLACEHOLDER_UI | `/cart` |
| `s_lection_de_l_adresse_speedygo` | `/checkout/address` | ROUTE_MAPPED, PLACEHOLDER_UI · variant unresolved | `/checkout/review` |
| `s_lecteur_d_adresse_speedygo_reference` | `/checkout/address-picker` | ROUTE_MAPPED, PLACEHOLDER_UI · variant unresolved | `/checkout/review` |
| `adresses_enregistr_es_speedygo` | `/account/addresses` | ROUTE_MAPPED, PLACEHOLDER_UI | `/account` |
| `ajouter_ou_modifier_une_adresse_speedygo` | `/addresses/form` | ROUTE_MAPPED, PLACEHOLDER_UI | `/account/addresses` |
| `confirmation_de_l_emplacement_speedygo` | `/addresses/confirm-location` | ROUTE_MAPPED, PLACEHOLDER_UI | `/account/addresses` |
| `permission_de_localisation_speedygo` | `/location-permission` | ROUTE_MAPPED, PLACEHOLDER_UI | `/account/addresses` |
| `mode_de_paiement_speedygo` | `/checkout/method` | ROUTE_MAPPED, PLACEHOLDER_UI | `/checkout/review` |
| `paiement_speedygo` | `/checkout/payment` | ROUTE_MAPPED, PLACEHOLDER_UI | `/checkout/method` |
| `redirection_vers_le_paiement_speedygo` | `/checkout/redirect` | ROUTE_MAPPED, PLACEHOLDER_UI | `/checkout/payment` |
| `soumission_de_la_commande_speedygo` | `/checkout/submit` | ROUTE_MAPPED, PLACEHOLDER_UI · submit never succeeds | `/checkout/redirect` |
| `confirmation_de_commande_speedygo` | `/orders/:id/confirmation` | ROUTE_MAPPED, PLACEHOLDER_UI, PREVIEW_ONLY | order detail |
| `d_tails_de_la_commande_speedygo` | `/orders/:orderId` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | `/orders` |
| `d_tails_de_l_tat_speedygo` | `/orders/:id/status` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | order detail |
| `annuler_la_commande_speedygo` | `/orders/:id/cancel` | ROUTE_MAPPED, PLACEHOLDER_UI; cancel blocked | order detail |
| `attente_de_confirmation_speedygo` | `/orders/:id/waiting` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | order detail |
| `recherche_de_livreur_speedygo` | `/orders/:id/searching-driver` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | order detail |
| `suivi_de_commande_speedygo` | `/orders/:id/tracking` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | order detail |
| `suivi_de_livraison_speedygo` | `/orders/:id/map` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | order detail |
| `livreur_proximit_speedygo` | `/orders/:id/nearby` | ROUTE_MAPPED, PLACEHOLDER_UI, PREVIEW_ONLY | order detail |
| `code_de_livraison_speedygo` | `/orders/:id/delivery-code` | ROUTE_MAPPED, PLACEHOLDER_UI, PREVIEW_ONLY | order detail |
| `instructions_de_livraison_speedygo` | `/orders/:id/delivery-notes` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | order detail |
| `commande_termin_e_speedygo` | `/orders/:id/completed` | ROUTE_MAPPED, PLACEHOLDER_UI, PREVIEW_ONLY | order detail |
| `re_u_speedygo` | `/orders/:id/receipt` | ROUTE_MAPPED, PLACEHOLDER_UI, PREVIEW_ONLY | order detail |
| `noter_la_commande_speedygo` | `/orders/:id/rate` | ROUTE_MAPPED, PLACEHOLDER_UI; rate blocked | order detail |
| `r_diger_un_avis_speedygo` | `/orders/:id/write-review` | ROUTE_MAPPED, PLACEHOLDER_UI; publish blocked | order detail |
| `param_tres_des_notifications_speedygo` | `/account/notifications` | ROUTE_MAPPED, PLACEHOLDER_UI, BACKEND_UNSUPPORTED | `/account` |
| `s_curit_et_sessions_actives_speedygo` | `/account/security` | ROUTE_MAPPED, PLACEHOLDER_UI | `/account` |
| `l_gal_et_confidentialit_speedygo` | `/account/legal`, `/legal/terms`, `/legal/privacy` | ROUTE_MAPPED, PLACEHOLDER_UI | `/account` or `/account/legal` |
| `suppression_du_compte_speedygo` | `/account/delete` | ROUTE_MAPPED, PLACEHOLDER_UI, BACKEND_UNSUPPORTED | `/account` |
| `signaler_un_probl_me_speedygo` | `/support/new` | ROUTE_MAPPED, PLACEHOLDER_UI | `/account` |
| `d_tails_du_ticket_support_speedygo` | `/support/:ticketId` | ROUTE_MAPPED, PLACEHOLDER_UI; fixture = PREVIEW_ONLY | `/support/new` |
| directory | `/directory` | PREVIEW_ONLY | `/home` |
