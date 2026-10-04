#!/usr/bin/env python3
"""Render shopping Stitch HTML at SE + iPhone 17 Pro with nested-width normalization."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path("/Users/mac/Downloads/speedygo_project")
SCREENS = ROOT / "screens" / "CustomerScreens"
OUT = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "shopping" / "stitch"
REPORT = OUT / "render-report.json"

SHOPPING = (
    ("toutes_les_cat_gories_speedygo_c_012", "categories-ready"),
    ("restaurants_speedygo", "category-results-ready"),
    ("d_tails_du_marchand_speedygo", "storefront-ready"),
    ("r_sultats_de_recherche_speedygo", "search-results-ready"),
    ("configuration_du_produit_speedygo", "product-options-ready"),
    ("panier_speedygo_c_025", "cart-ready"),
    ("s_lection_de_l_adresse_speedygo", "checkout-address-ready"),
    ("r_vision_de_la_commande_speedygo", "checkout-review-ready"),
)

VIEWPORTS = (
    ("se-375x667", 375, 667, 2),
    ("iphone17pro-402x874", 402, 874, 3),
)

# Normalize nested fixed artboard widths (often 390) into the target viewport.
FILL_CSS = """
html, body {
  margin: 0 !important;
  padding: 0 !important;
  width: 100% !important;
  max-width: 100% !important;
  height: 100% !important;
  overflow-x: hidden !important;
  overflow-y: auto !important;
  background: #f9f9ff !important;
  box-sizing: border-box !important;
}
*, *::before, *::after { box-sizing: border-box !important; }
body { display: block !important; }
main,
[data-purpose="mobile-container"],
[data-purpose="mobile-screen-container"] {
  width: 100% !important;
  max-width: 100% !important;
  min-width: 0 !important;
  height: 100vh !important;
  max-height: none !important;
  box-shadow: none !important;
  margin: 0 !important;
  border-radius: 0 !important;
  overflow-x: hidden !important;
}
.w-\\[390px\\],
.max-w-\\[390px\\],
.min-w-\\[390px\\] {
  width: 100% !important;
  max-width: 100% !important;
  min-width: 0 !important;
}
.max-w-md, .max-w-2xl, .max-w-lg, .max-w-xl {
  max-width: 100% !important;
}
.fixed.bottom-0, footer.fixed, nav.fixed {
  left: 0 !important;
  right: 0 !important;
  width: 100% !important;
  max-width: 100% !important;
}
input, textarea, button, .w-full {
  max-width: 100% !important;
}
"""


def _measure(page) -> dict:
    return page.evaluate(
        """() => {
          const doc = document.documentElement;
          const body = document.body;
          const main = document.querySelector('main') || body;
          const inputs = [...document.querySelectorAll('input, textarea, button')]
            .slice(0, 12)
            .map((el) => {
              const r = el.getBoundingClientRect();
              return {
                tag: el.tagName.toLowerCase(),
                right: Math.round(r.right),
                width: Math.round(r.width),
                clipped: r.right > (window.innerWidth + 1),
              };
            });
          return {
            innerWidth: window.innerWidth,
            scrollWidth: Math.max(doc.scrollWidth, body.scrollWidth, main.scrollWidth),
            clientWidth: doc.clientWidth,
            mainScrollWidth: main.scrollWidth,
            overflowX: Math.max(doc.scrollWidth, body.scrollWidth) > window.innerWidth + 1,
            clippedControls: inputs.filter((i) => i.clipped),
          };
        }"""
    )


def main() -> int:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("PLAYWRIGHT_MISSING", file=sys.stderr)
        return 2

    OUT.mkdir(parents=True, exist_ok=True)
    results = []
    with sync_playwright() as p:
        try:
            browser = p.chromium.launch(channel="chrome")
        except Exception:
            browser = p.chromium.launch()
        for folder, slug in SHOPPING:
            html = SCREENS / folder / "code.html"
            entry = {"folder": folder, "slug": slug, "html": html.is_file()}
            if not html.is_file():
                entry["status"] = "html_missing"
                results.append(entry)
                print("html_missing", folder, flush=True)
                continue
            for vp_name, width, height, dpr in VIEWPORTS:
                failed: list[dict] = []
                context = browser.new_context(
                    viewport={"width": width, "height": height},
                    device_scale_factor=dpr,
                )
                page = context.new_page()

                def on_response(response):
                    if response.status >= 400:
                        failed.append(
                            {
                                "url": response.url,
                                "status": response.status,
                                "resourceType": response.request.resource_type,
                            }
                        )

                page.on("response", on_response)
                page.goto(html.resolve().as_uri(), wait_until="networkidle", timeout=90000)
                page.add_style_tag(content=FILL_CSS)
                page.evaluate(
                    """() => {
                      const vw = window.innerWidth;
                      document.querySelectorAll('*').forEach((el) => {
                        const style = window.getComputedStyle(el);
                        const w = parseFloat(style.width);
                        const mw = parseFloat(style.maxWidth);
                        const minw = parseFloat(style.minWidth);
                        if (w > vw + 1 && style.display !== 'none') {
                          el.style.setProperty('width', '100%', 'important');
                          el.style.setProperty('max-width', '100%', 'important');
                        }
                        if (mw > vw + 1) {
                          el.style.setProperty('max-width', '100%', 'important');
                        }
                        if (minw > vw * 0.5 && minw > 120) {
                          el.style.setProperty('min-width', '0', 'important');
                        }
                      });
                    }"""
                )
                page.wait_for_timeout(1500)
                page.evaluate(
                    """async () => {
                      if (document.fonts && document.fonts.ready) {
                        await document.fonts.ready;
                      }
                    }"""
                )
                page.wait_for_timeout(500)
                metrics = _measure(page)
                dest = OUT / f"{slug}-{vp_name}.png"
                page.screenshot(
                    path=str(dest),
                    full_page=False,
                    clip={"x": 0, "y": 0, "width": width, "height": height},
                )
                context.close()
                critical = [
                    f
                    for f in failed
                    if f["resourceType"] in ("stylesheet", "font", "image")
                    or "fonts.googleapis" in f["url"]
                    or "fonts.gstatic" in f["url"]
                ]
                defects = []
                if metrics.get("overflowX"):
                    defects.append(
                        "original_html_horizontal_overflow:"
                        f"scrollWidth={metrics.get('scrollWidth')}"
                        f">innerWidth={metrics.get('innerWidth')}"
                    )
                clipped = metrics.get("clippedControls") or []
                form_clipped = [
                    c
                    for c in clipped
                    if c.get("tag") in ("input", "textarea")
                    or (c.get("tag") == "button" and c.get("width", 0) >= 200)
                ]
                chip_clipped = [c for c in clipped if c not in form_clipped]
                if form_clipped:
                    defects.append(
                        "clipped_form_controls:"
                        + ",".join(
                            f"{c['tag']}@right={c['right']}" for c in form_clipped[:4]
                        )
                    )
                if chip_clipped and not form_clipped:
                    defects.append(
                        "intentional_horizontal_chip_overflow:"
                        f"{len(chip_clipped)}_chip_buttons_clip_at_right_edge"
                    )
                vp_entry = {
                    "viewport": vp_name,
                    "status": "rendered" if dest.is_file() else "failed",
                    "bytes": dest.stat().st_size if dest.is_file() else 0,
                    "failedResources": critical,
                    "failedCount": len(critical),
                    "metrics": metrics,
                    "htmlDefects": defects,
                    "path": dest.name,
                }
                entry.setdefault("viewports", []).append(vp_entry)
                print(
                    "ok" if vp_entry["status"] == "rendered" else "fail",
                    f"{slug}-{vp_name}",
                    f"failed_resources={len(critical)}",
                    f"defects={len(defects)}",
                    flush=True,
                )
            entry["status"] = (
                "rendered"
                if all(v.get("status") == "rendered" for v in entry.get("viewports", []))
                else "partial"
            )
            results.append(entry)
        browser.close()

    REPORT.write_text(json.dumps({"shopping": results}, indent=2) + "\n")
    bad = sum(1 for r in results if r.get("status") != "rendered")
    print(f"shopping_stitch rendered={len(results)-bad} failed={bad}")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
