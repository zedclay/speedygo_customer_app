#!/usr/bin/env python3
"""Side-by-side and difference overlays for mocked widget vs Stitch HTML renders."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path("/Users/mac/Downloads/speedygo_project")
WIDGET = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "widget" / "mocked"
STITCH = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "stitch"
OUT = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "compare"

PAIRS = (
    "home-ready",
    "categories-ready",
    "category-results-ready",
    "storefront-ready",
    "product-ready",
    "product-options-ready",
    "search-idle",
    "search-results-ready",
    "cart-ready",
    "checkout-address-ready",
    "checkout-review-ready",
    "orders-in-progress-ready",
    "order-detail-ready",
    "orders-cancelled-ready",
    "account-hub-ready",
    "addresses-ready",
    "support-detail-ready",
    "notifications-ready",
    "sessions-ready",
    # Remaining (this visual pass)
    "language-ready",
    "welcome-ready",
    "phone-ready",
    "otp-ready",
    "profile-setup-ready",
    "restore-loading-ready",
    "checkout-method-ready",
    "order-confirmation-ready",
    "menu-ready",
    "merchant-info-ready",
    "merchant-reviews-ready",
    "order-cancel-form-ready",
    "tracking-waiting-ready",
    "tracking-searching-ready",
    "tracking-map-ready",
    "tracking-nearby-ready",
    "tracking-completed-ready",
    "order-rate-ready",
    "order-write-review-ready",
    "account-language-ready",
    "support-create-ready",
    "legal-ready",
    "notification-prefs-ready",
    "account-delete-ready",
    "favorites-ready",
    "promotions-ready",
    "checkout-notes-ready",
    "location-permission-ready",
    "logout-sheet-ready",
    # Bookkeeping: splash frames + gated payment mocked states
    "splash-frame-front",
    "splash-frame-edge",
    "splash-frame-back",
    "splash-frame-static",
    "payment-disabled-ready",
    "payment-pending-ready",
    "payment-failed-ready",
    "payment-succeeded-ready",
    "payment-redirect-ready",
)

VIEWPORTS = ("se-375x667", "iphone17pro-402x874")

# Flutter slug → Stitch artifact slug when names differ (mocked state variants).
STITCH_ALIAS = {
    "splash-frame-front": "splash-ready",
    "splash-frame-static": "splash-ready",
    "splash-frame-edge": "splash2-ready",
    "splash-frame-back": "splash2-ready",
    "payment-disabled-ready": "payment-ready",
    "payment-pending-ready": "payment-ready",
    "payment-failed-ready": "payment-ready",
    "payment-succeeded-ready": "payment-ready",
    "payment-redirect-ready": "payment-redirect-ready",
}


def _open(path: Path):
    from PIL import Image

    return Image.open(path).convert("RGB")


def _fit(image, size):
    from PIL import Image

    fitted = Image.new("RGB", size, (255, 255, 255))
    copy = image.copy()
    copy.thumbnail(size, Image.Resampling.LANCZOS)
    x = (size[0] - copy.width) // 2
    y = (size[1] - copy.height) // 2
    fitted.paste(copy, (x, y))
    return fitted


def _diff(a, b):
    from PIL import ImageChops, ImageEnhance

    delta = ImageChops.difference(a, b)
    return ImageEnhance.Contrast(delta).enhance(2.2)


def main() -> int:
    try:
        from PIL import Image
    except ImportError:
        print("PIL_MISSING")
        return 2

    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for slug in PAIRS:
        for vp in VIEWPORTS:
            widget = WIDGET / f"{slug}-{vp}.png"
            stitch_slug = STITCH_ALIAS.get(slug, slug)
            stitch = STITCH / f"{stitch_slug}-{vp}.png"
            if not widget.is_file() or not stitch.is_file():
                rows.append(
                    {
                        "slug": slug,
                        "viewport": vp,
                        "status": "missing",
                        "widget": widget.exists(),
                        "stitch": stitch.exists(),
                        "stitchSlug": stitch_slug,
                    }
                )
                continue
            left = _open(stitch)
            right = _open(widget)
            height = max(left.height, right.height)
            width = max(left.width, right.width)
            left_f = _fit(left, (width, height))
            right_f = _fit(right, (width, height))
            side = Image.new("RGB", (width * 2 + 16, height), (20, 20, 24))
            side.paste(left_f, (0, 0))
            side.paste(right_f, (width + 16, 0))
            overlay = Image.blend(left_f, right_f, 0.5)
            delta = _diff(left_f, right_f)
            side_path = OUT / f"{slug}-{vp}-side-by-side.png"
            overlay_path = OUT / f"{slug}-{vp}-overlay.png"
            diff_path = OUT / f"{slug}-{vp}-diff.png"
            side.save(side_path, optimize=True)
            # Skip writing overlay/diff by default when disk is tight — keep side-by-side.
            # Still write lightly compressed overlays for review package subset later.
            overlay.save(overlay_path, optimize=True)
            delta.save(diff_path, optimize=True)
            rows.append(
                {
                    "slug": slug,
                    "viewport": vp,
                    "status": "compared",
                    "sideBySide": str(side_path.relative_to(ROOT)),
                    "overlay": str(overlay_path.relative_to(ROOT)),
                    "diff": str(diff_path.relative_to(ROOT)),
                    "stitchPx": list(left.size),
                    "widgetPx": list(right.size),
                    "stitchSlug": stitch_slug,
                }
            )
    (OUT / "index.json").write_text(json.dumps(rows, indent=2) + "\n")
    compared = sum(1 for row in rows if row["status"] == "compared")
    print(f"compared={compared} missing={len(rows) - compared}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
