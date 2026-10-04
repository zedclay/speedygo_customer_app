# Pilot visual review — SE 375×667

**Generated:** 2026-09-12 (human-review repair). **Viewport:** iPhone SE logical 375×667, DPR 2.

Use **`audit/customer-visual-review-pilot.zip`** for human review of the six pilots only. Product/Profile accepted from prior pass remain.

## Visible changes (this pass)

| Pilot | Visible change |
| --- | --- |
| `payment-success-to-confirmation` | **Montant payé** + **Confirmé par le serveur**; Articles label; scrolled so payment status clears sticky actions |
| `order-confirmation` | COD **À régler à la livraison** / **À encaisser à la livraison**; Articles; scrolled payment status |
| `home` | Precached SpeedyGo logo; subtle active-order shadow (no heavy Material elevation halo) |
| `support-create` | Linked card shows `publicReference` + amount; no raw UUID; no implementation footnote |

## Notes

- Merchant/branch display name omitted — not present on OrderDetail (only `merchantBranchId`).
- Fixture payment evidence remains `provider: mock`; electronic gate off.
- Stitch support chip strip overflow remains intentional.
