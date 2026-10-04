# SpeedyGo Customer audit — 11 September 2026

This folder is the **current-tree** Customer audit. It is not a full-platform audit.

Primary implementation: `apps/customer_app` (`feat/customer-auth-session` @ `8adae21` plus local uncommitted work).  
Customer contracts inspected in `apps/backend` (`main` @ `2be7a4d` plus local uncommitted work) and `docs/`.  
Stitch HTML: `screens/CustomerScreens/` (logical artboard typically **390×844**). **No `screen.png` files.** References were rendered from `code.html` (Chrome headless). Empty-shell widget captures are **not** Stitch fidelity proof.

| File | Contents |
| --- | --- |
| [01-baseline.md](01-baseline.md) | Repos, HEADs, inventory |
| [02-screen-matrix.md](02-screen-matrix.md) | Reference → route → contract → verification |
| [03-findings.md](03-findings.md) | A–E findings with file/line |
| [04-fixes-and-regression.md](04-fixes-and-regression.md) | Fixes + widget regression |
| [05-visual-verification.md](05-visual-verification.md) | Populated mocked vs Stitch HTML, overlays, unreviewed screens |
| [06-commands-and-results.md](06-commands-and-results.md) | Commands and exact exits |
| [07-gaps-and-unaudited.md](07-gaps-and-unaudited.md) | Ranked gaps; classification; apps not reviewed |
| [08-verification-labels.md](08-verification-labels.md) | Live / mocked / code-inspected / unverified |
| [visuals/widget/mocked/](visuals/widget/mocked/) | Populated **mocked** captures (SE 375×667, 17 Pro 402×874, text 1.3) |
| [visuals/stitch/](visuals/stitch/) | Stitch HTML renders |
| [visuals/compare/](visuals/compare/) | Side-by-side, overlay, diff (**compared=57**, missing=39 this pass) |
| [live/read-only-gestures.json](live/read-only-gestures.json) | Live SE catalog/account gestures: **`status=passed`** |
| [live/product-photo-gestures.json](live/product-photo-gestures.json) | Live SE bound product photo: **`status=passed`** (Croissant au beurre) |
| [live/README.md](live/README.md) | Live gates, photo content gap (Pain khobz), Redis notes |
| [live/shots/](live/shots/) | Named simctl captures |

Live navigation status: [`../NAVIGATION_STATUS.md`](../NAVIGATION_STATUS.md).  
`screens/CustomerScreens/SCREEN_INVENTORY.md` is **historical**. Do not treat it as current.

**Audit layers (do not collapse):**

- **Code/build:** earlier `flutter analyze` 0, full suite 0, Android debug APK 0 — **preserved** (not restarted). This pass: `flutter analyze` 0; focused tests (`live_screen_classify`, `auth_visual_layout`, order cancel/recovery, support) exit 0.
- **Visual:** mocked vs Stitch — **expanded** (auth, tracking mocks, ratings, honest placeholders, support create, …). Still partial (splash lightly unreviewed; some Stitch PNGs timed out; not pixel-identical).
- **Live acceptance:** catalog/account journey **passed**; photographed product **passed** (Croissant). Pain khobz remains an unbound **content gap**.

**Not claimed:** whole UI complete, pixel-identical Stitch, Chargily/maps/live tracking, or Pain khobz photography.
