# Findings (current tree)

Classes: **A** presentation fixable now · **B** backend exists, Flutter missing · **C** missing backend/external · **D** intentional dynamic/fixture · **E** reference contradiction.

Severity: **P0** session/money/destructive · **P1** blocked journey · **P2** misleading copy / visual · **P3** polish.

Evidence: **fixed this pass** or **open**. Line numbers from the tree after this audit’s Flutter edits.

## Fixed this pass (were confirmed defects)

| ID | Sev | Class | Finding | Location | Repro | Impact |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | P1 | A | Profile **Méthodes de paiement** opened checkout method and could change the pending checkout payment selection. | `account_hub_screen.dart:79-80` → `/account/payment-methods` `app_router.dart:328-334` | Profil → Méthodes de paiement | Checkout payment method mutated from a non-checkout screen. |
| F2 | P1 | A | Cart CTA not gated on `cartReady`. | `cart_screen.dart:82-88, 108-112` | Cart with `cartReady: false` | User could enter checkout while backend would reject `ORDER_CART_NOT_READY`. |
| F3 | P1 | B | Orders list ignored list DTO `paymentMethod` / `createdAt` / `financial` and had no pagination. | `order_models.dart:53-81`; `orders_list_controller.dart:71-120`; `orders_tab_screen.dart:54-67, 197-213` | Commandes tab | Wrong/missing totals; older orders unreachable. |
| F4 | P2 | A | Live account/legal/delete/notifications/checkout-notes used `NavScaffold` chrome instead of honest destinations. | `app_router.dart:317-357` + `account_status_screen.dart` | Profil rows | Looked like working settings; no API. |
| F5 | P2 | A | Review CTA “Publier l’avis” implied a public feed. | `app_strings.dart:74` | Write-review | Comments are author-only; summaries only. |
| F6 | P2 | A | COD/cancel copy used “encaissé”. | `app_strings.dart:390-391, 462-463` | Confirmation / cancel COD | Implied cash already taken. |
| F7 | P2 | A | Preview catalog used “Paiement réussi”. | `nav_catalog.dart:533` + `app_strings.dart:433` | Nav preview receipt | PSP success not authoritative. |
| F8 | P2 | A | Stitch 2FA copy vs OTP-only app. | `active_sessions_screen.dart:73-94`; `app_strings.dart:789-791` | Sécurité | False 2FA claim. |
| F9 | P2 | A | `/categories` was not the live verticals screen. | `app_router.dart` categories route | Deep link `/categories` | Dead/placeholder vs Home → catégories. |
| F10 | P2 | A | Logout hub used a filled style without `account-logout` key in some paths. | `account_hub_screen.dart:138-139` | Profil → Se déconnecter | Tests/automation + visual CTA hierarchy. |
| F11 | P2 | A | Search results lacked Stitch-like field in AppBar when `showBack`. | `search_screen.dart:54-70` | Search → results | Weaker Back + query chrome. |
| F12 | P2 | A | Product configure price `Row` + `Spacer` + quantity stepper overflowed **20px** on SE 375. | `product_configure_screen.dart` | Configure on 375×667 | Horizontal overflow. |
| F13 | P2 | A | Support list AppBar had no explicit Back on the pushed `/support` route. | `support_list_screen.dart` | Profil → Mes demandes | Back affordance missing. |
| F14 | P2 | A | Address form and checkout promo field lacked keyboard `scrollPadding` / bottom inset. | `address_form_screen.dart`; `checkout_review_screen.dart` | Forms at text 1.3 | Fields hidden behind keyboard. |
| F15 | P2 | A | Stored-session hydrate never set `SessionPhase.restoring`, so `/restore` never showed and live tests stayed on splash. | `session_controller.dart` `restore()` | Cold start with Keychain tokens | Splash with no search/phone/language copy until hydrate finished. |

## Open — not faked

Honest unsupported Stitch destinations remain **unfinished capabilities**. They are **not** automatically P1 MVP defects. `docs/architecture/CUSTOMER_ONBOARDING.md` **Out** includes Favorites, Wallet, Loyalty, avatar, and Customer/Account deletion. Saved cards are not a v1 checkout requirement (COD vs gated ELECTRONIC). Legal copy has no public API; a CMS is **not** a documented MVP requirement.

| ID | Sev | Class | Finding | Location | Repro | Impact |
| --- | --- | --- | --- | --- | --- | --- |
| O1 | P3 | optional | No Customer favorites API. Onboarding **Out**. | `/favorites` | Accueil / hub | Honest placeholder; **not** agreed MVP. |
| O2 | P3 | optional | No saved payment methods. Checkout is COD vs gated ELECTRONIC. | `/account/payment-methods` | Profil | Honest empty cards; **not** agreed MVP. |
| O3 | P3 | optional | No account-delete route. Onboarding **Out** (Customer/Account deletion). | `/account/delete` | Delete screen | Honest unsupported; Stitch password field is **E**. |
| O4 | P3 | unfinished | No public legal content API. CMS is **not** a required MVP. | `/legal/*` | Profil légal | Honest “contenu non servi”. |
| O5 | P2 | C | No checkout notes / address `instructions` write in v1.0. | `/checkout/notes` | Checkout | Cannot send special instructions. |
| O6 | P1 | C | No Customer delivery-code API. | `/orders/:id/delivery-code` | Tracking | Product decision. |
| O7 | P1 | C | No map SDK / keys. | tracking map routes | Tracking | Coords/status only. |
| O8 | P1 | C | Chargily sandbox keys absent; `PAYMENT_PROVIDER` empty → in-process `test://`; `ELECTRONIC_PAYMENT_ENABLED` default false. | `electronic_payment_config.dart:23-27` | Checkout ELECTRONIC | Correctly gated; cannot complete real PSP. |
| O9 | P2 | C | No OS push permission / notification preference storage. | `/account/notifications` | Profil | Inbox API exists; prefs/OS push are missing **external/config**, not a fake inbox. |
| O10 | P3 | optional | No public review comment list. Ratings contract is summary + author-only comments. | merchant reviews | Storefront avis | Honest summary; public feed is not v1. |
| O11 | P2 | D/U | No synthetic LIVE delivery for Revue; Socket.IO tracking not live-proven this session. | tracking controller | Active order | HTTP polling code exists; live socket **U**. |
| O12 | P2 | D | Catalog names, hours, amounts, photos differ from Stitch fixtures. | Home / storefront | Live data | Expected. |
| O13 | P3 | E | Stitch cart title “Merchant Details”. | `panier_speedygo_c_025/code.html:93` | — | Live title Panier. |
| O14 | P3 | E | Stitch “Commande confirmée !” before merchant acceptance. | `confirmation_de_commande_speedygo/code.html:157` | — | Live “Commande envoyée”. |
| O15 | P3 | E | Stitch receipt “Paiement Réussi”. | `re_u_speedygo/code.html:141` | — | Preview string unconfirmed. |
| O16 | P3 | E | Stitch 48h bank refund. | `annuler_la_commande_speedygo/code.html:211` | — | Contract has no 48h SLA; live copy avoids it. |
| O17 | P3 | E | Stitch password delete. | `suppression_du_compte_speedygo/code.html:197` | — | OTP app; no password field. |
| O18 | P3 | E | Stitch “autres sessions” vs logout-all. | `s_curit_et_sessions_actives_speedygo/code.html:216` | — | Live body includes this session (`app_strings.dart:785-787`). |
| O19 | P3 | E | Stitch 4 English tabs vs 5 French tabs. | `profil_speedygo_1` | — | Product decision kept. |
| O20 | P2 | A/D | Stitch 390×844 vs SE 375×667 vs 17 Pro 402×874: density, last-item reachability, and bottom inset differ. | HTML `w-[390px] h-[844px]` | Widget captures | Layout, not a contract bug. |
| O21 | P3 | A | Promo Home banner uses a gradient (Stitch also uses decorative blobs). | `home_promo_banner.dart:37-41` | Home | Acceptable brand; not pixel-matched. |
| O22 | P2 | C | `re_u` / delivery-notes remain placeholders. | routes above | Preview | Not live acceptance. |

## Backend ownership / storage (code-inspected, not a pentest)

Confirmed (not hypotheses):

- Order create rejects mass-assignment of `customerId` / amounts / status (`order.controller.ts:45-51`). Ownership is JWT CustomerProfile.
- Cart is loaded by `customerId` from the authenticated profile (`cart.service.ts` / repository `findActiveCart(customerId)`).
- Customer catalog images are bound upload objects served on Customer GET cover/product image (prior catalog work; storage root `$HOME/.speedygo/dev/storage`).
- Refresh is single-flight and reads the current store token (`token_refresher.dart:11-16, 38-40`).

No new vulnerability was **confirmed** in this pass. Competing app instances against one rotating refresh token remain a known operational risk (not exploited here).

## Security hypotheses (not confirmed)

- Notification recovery / matching queue warn `Custom Id cannot contain :` on API boot (backend log). Customer impact **unverified**.
- Device-token deactivation on logout is documented as not automatic in older inventory notes — **not re-proven** this session.
