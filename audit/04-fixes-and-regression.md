# Fixes and regression evidence

No backend schema or `.env` changes. Customer Flutter only (plus this audit folder and `NAVIGATION_STATUS.md`).

## What changed

1. **Payment methods isolation** — Profile opens `/account/payment-methods` (`AccountStatusScreen`), not `/checkout/method`.
2. **Cart ready gate** — Checkout CTA `onPressed` is null when `!cartReady`; error text shown.
3. **Orders list contract** — `OrderSummary` requires `paymentMethod`, `createdAt`, `financial`; list paginates (`limit` 20); tabs En cours / Terminées / Annulées.
4. **Honest unsupported destinations** — delete, legal, notification prefs, checkout notes, payment methods.
5. **Copy** — Envoyer l’avis; no “encaissé”; Commande envoyée (already); OTP guidance; logout-all includes this session; PSP unconfirmed in preview.
6. **Search results AppBar field** when `showBack`.
7. **`/categories` → `CommerceVerticalsScreen`**.
8. **Logout** outlined + `Key('account-logout')`.
9. **Analyzer infos** — `prefer_const_*` / `prefer_initializing_formals` (and later unused-import / const Key) fixed in source. Analyzer settings were not weakened. Final `flutter analyze` exit 0.
10. **Android compileSdk 37** — `compileSdk = maxOf(flutter.compileSdkVersion, 37)` so `flutter_secure_storage` 11 can compile. Local SDK: symlink `platforms/android-37` → `android-37.0`. `targetSdk` still Flutter’s. Debug APK **exit 0**.
11. **Product configure overflow** on SE 375 — price row uses `Flexible` + ellipsis; stepper intrinsic width.
12. **Support list Back** — `popOrParent` leading on `/support`.
13. **Keyboard reachability** — address form `viewInsets` + `scrollPadding` 140 + dismiss on drag; checkout promo `scrollPadding`.
14. **Restore phase** — `restore()` sets `SessionPhase.restoring` when tokens exist (hydrate no longer stays on splash-only bootstrapping).
15. **Sticky CTA clearance** — confirmation + cancel form list bottom padding 140; support create submit in `bottomNavigationBar` with keyboard inset.
16. **Live product photo harness** — prefer Viennoiseries bound SKUs; classify restore before Home.
17. **Live classify** — restore copy preferred over Home while Session restaurée shows.
18. **Confirmation money row** — `Flexible` + ellipsis (SE horizontal overflow found during padding verification).

## New / focused tests

| Test | What it proves |
| --- | --- |
| `test/features/account/account_hub_flow_test.dart` | Payment methods ≠ checkout method; Back to Profil; delete has no password field and does not call API; cart CTA disabled when not ready. |
| `test/features/orders/orders_list_test.dart` | List DTO parse requires financials; pagination; cancelled filter separate. |
| Existing `test/widget_test.dart` OTP cooldown | Stay on phone while `canRequestOtp` is false (not a second OTP screen). |
| `test/audit/audit_screenshot_capture_test.dart` | Skipped unless `AUDIT_CAPTURE=1`. Populated **mocked** journeys (taps + Back) write `audit/visuals/widget/mocked/`. |
| `test/audit/audit_screenshot_capture_remaining_test.dart` | Remaining auth/tracking/ratings/honest screens (mocked). |
| `integration_test/audit_live_read_gestures_test.dart` | Read-only catalog/account. Prefer photographed products. |
| `integration_test/audit_live_product_photo_test.dart` | Bound product photo proof. This session: **passed**. |

## Widget / unit (this tree)

See [06-commands-and-results.md](06-commands-and-results.md). Earlier full suite preserved. This pass focused tests + analyze **exit 0**.

## Live this session

Catalog/account: `status=passed`. Product photo: Croissant au beurre `status=passed`. Pain khobz = unbound content gap.

## Manual steps (keep existing session)

1. Accueil → Profil → Méthodes de paiement: honest empty-cards copy; Back returns to Profil; do not see COD/ELECTRONIC checkout tiles.
2. Panier with unavailable item: checkout button disabled; `cartNotReady` text.
3. Commandes: date, payment method, total; load more if `hasMore`; Annulées tab.
4. Profil → Supprimer: no password field; confirm shows “Aucune route…”.
5. Sécurité: OTP/SMS card; logout-all dialog says this session is included.
6. Search results: query field in AppBar with Back.
7. Product configure on a narrow width: price and quantity stepper do not overflow.
8. Profil → Mes demandes: explicit Back.
9. Address form / checkout promo: fields remain reachable with keyboard + text scale 1.3.
