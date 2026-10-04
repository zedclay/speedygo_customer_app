#!/usr/bin/env python3
"""Side-by-side labeled Stitch|Flutter JPEGs for UI alignment visual batch."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FLUTTER = ROOT / "audit" / "visuals" / "alignment" / "flutter"
STITCH = ROOT / "audit" / "visuals" / "alignment" / "stitch"
OUT = ROOT / "audit" / "visuals" / "alignment" / "compare"

SLUGS = (
    "product-detail-ready",
    "product-options-ready",
    "storefront-ready",
    "categories-ready",
    "cart-ready",
    "home-ready",
    "merchant-reviews-ready",
    "merchant-info-ready",
    "order-rate-ready",
    "order-write-review-ready",
    "support-create-ready",
    "support-detail-ready",
    "orders-in-progress-ready",
    "order-detail-ready",
    "account-hub-ready",
    "account-language-ready",
    "sessions-ready",
    "promotions-ready",
    "addresses-ready",
    "checkout-method-ready",
    "tracking-waiting-ready",
)

FLUTTER_ONLY = {
    "checkout-review-ready",
    "checkout-review-scrolled",
    "product-options-unselected",
    "product-options-selected",
    "product-detail-plain-ready",
}

STRUCTURE_ONLY = {
    # Stitch tracking artboard is préparation / ETA, not CREATED+PENDING_ACCEPTANCE.
    "tracking-waiting-ready": "Stitch stage is préparation; Flutter waiting is contract-accurate",
    "order-detail-ready": "Stitch is delivered + Recommander; Flutter capture is awaiting merchant",
    "support-detail-ready": "Stitch is in-progress with photo/linked order; Flutter is OPEN thread without photos",
    "support-create-ready": "Stitch has order card + chips; Flutter honest create without chips/photos",
}

# Stitch `r_vision_de_la_commande_speedygo` is a Recommander board, not checkout.

VIEWPORTS = ("se-375x667", "iphone17pro-402x874")

LABEL_HEIGHT = 36
LABEL_BG = (20, 20, 24)
LABEL_FG = (240, 240, 245)


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


def _label_bar(text: str, width: int):
    from PIL import Image, ImageDraw, ImageFont

    bar = Image.new("RGB", (width, LABEL_HEIGHT), LABEL_BG)
    draw = ImageDraw.Draw(bar)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    draw.text(
        ((width - text_w) // 2, (LABEL_HEIGHT - text_h) // 2),
        text,
        fill=LABEL_FG,
        font=font,
    )
    return bar


def main() -> int:
    try:
        from PIL import Image  # noqa: F401
    except ImportError:
        print("PIL_MISSING")
        return 2

    OUT.mkdir(parents=True, exist_ok=True)
    rows = []

    for slug in SLUGS:
        for viewport in VIEWPORTS:
            artifact = f"{slug}-{viewport}"
            stitch_path = STITCH / f"{artifact}.png"
            flutter_path = FLUTTER / f"{artifact}.png"
            if slug in FLUTTER_ONLY:
                rows.append(
                    {
                        "slug": slug,
                        "viewport": viewport,
                        "artifact": artifact,
                        "status": "reference_missing"
                        if not flutter_path.is_file()
                        else "flutter_only",
                        "stitch": False,
                        "flutter": flutter_path.is_file(),
                        "note": "Stitch r_vision_de_la_commande_speedygo is Recommander, not checkout"
                        if slug.startswith("checkout-review")
                        else "Flutter-only evidence",
                    }
                )
                continue
            if not stitch_path.is_file() or not flutter_path.is_file():
                rows.append(
                    {
                        "slug": slug,
                        "viewport": viewport,
                        "artifact": artifact,
                        "status": "missing",
                        "stitch": stitch_path.is_file(),
                        "flutter": flutter_path.is_file(),
                    }
                )
                continue

            left = _open(stitch_path)
            right = _open(flutter_path)
            panel_w = max(left.width, right.width)
            panel_h = max(left.height, right.height)
            left_f = _fit(left, (panel_w, panel_h))
            right_f = _fit(right, (panel_w, panel_h))

            gap = 12
            canvas_w = panel_w * 2 + gap
            canvas_h = LABEL_HEIGHT + panel_h
            canvas = Image.new("RGB", (canvas_w, canvas_h), LABEL_BG)
            stitch_label = (
                "STITCH STRUCTURE (INCOMPATIBLE STATE)"
                if slug in STRUCTURE_ONLY
                else "STITCH REFERENCE"
            )
            canvas.paste(_label_bar(stitch_label, panel_w), (0, 0))
            canvas.paste(_label_bar("MOCKED FLUTTER", panel_w), (panel_w + gap, 0))
            canvas.paste(left_f, (0, LABEL_HEIGHT))
            canvas.paste(right_f, (panel_w + gap, LABEL_HEIGHT))

            out_path = OUT / f"{artifact}-side-by-side.jpg"
            canvas.save(out_path, "JPEG", quality=85)
            status = "structure_only" if slug in STRUCTURE_ONLY else "compared"
            row = {
                "slug": slug,
                "viewport": viewport,
                "artifact": artifact,
                "status": status,
                "path": out_path.name,
                "bytes": out_path.stat().st_size,
            }
            if slug in STRUCTURE_ONLY:
                row["note"] = STRUCTURE_ONLY[slug]
            rows.append(row)

    (OUT / "index.json").write_text(json.dumps(rows, indent=2) + "\n")
    compared = sum(1 for row in rows if row["status"] == "compared")
    structure = sum(1 for row in rows if row["status"] == "structure_only")
    missing = sum(1 for row in rows if row["status"] in {"missing", "reference_missing"})
    print(f"compared={compared} structure_only={structure} missing={missing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
