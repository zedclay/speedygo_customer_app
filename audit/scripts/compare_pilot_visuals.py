#!/usr/bin/env python3
"""Side-by-side JPEG comparisons for pilot Flutter vs Stitch captures."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FLUTTER = ROOT / "audit" / "visuals" / "pilot" / "flutter"
STITCH = ROOT / "audit" / "visuals" / "pilot" / "stitch"
OUT = ROOT / "audit" / "visuals" / "pilot" / "compare"

SLUGS = (
    "home-ready-se-375x667",
    "profile-setup-ready-se-375x667",
    "order-confirmation-ready-se-375x667",
    "product-ready-se-375x667",
    "support-create-keyboard-se-375x667",
    "payment-success-to-confirmation-se-375x667",
)

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
        from PIL import Image
    except ImportError:
        print("PIL_MISSING")
        return 2

    OUT.mkdir(parents=True, exist_ok=True)
    rows = []

    for slug in SLUGS:
        stitch_path = STITCH / f"{slug}.png"
        flutter_path = FLUTTER / f"{slug}.png"
        if not stitch_path.is_file() or not flutter_path.is_file():
            rows.append(
                {
                    "slug": slug,
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
        canvas.paste(_label_bar("Stitch", panel_w), (0, 0))
        canvas.paste(_label_bar("Flutter", panel_w), (panel_w + gap, 0))
        canvas.paste(left_f, (0, LABEL_HEIGHT))
        canvas.paste(right_f, (panel_w + gap, LABEL_HEIGHT))

        out_path = OUT / f"{slug}-side-by-side.jpg"
        canvas.save(out_path, "JPEG", quality=85)
        rows.append(
            {
                "slug": slug,
                "status": "compared",
                "path": out_path.name,
                "bytes": out_path.stat().st_size,
            }
        )

    (OUT / "index.json").write_text(json.dumps(rows, indent=2) + "\n")
    compared = sum(1 for row in rows if row["status"] == "compared")
    print(f"compared={compared} missing={len(rows) - compared}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
