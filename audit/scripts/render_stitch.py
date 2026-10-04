#!/usr/bin/env python3
"""Render Customer Stitch HTML at logical viewports using Playwright or Chrome headless."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path("/Users/mac/Downloads/speedygo_project")
SCREENS = ROOT / "screens" / "CustomerScreens"
OUT = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "stitch"

VIEWPORTS = (
    ("se-375x667", 375, 667),
    ("iphone17pro-402x874", 402, 874),
)

MAPPED = {
    "accueil_speedygo": "home-ready",
    "toutes_les_cat_gories_speedygo_c_012": "categories-ready",
    "restaurants_speedygo": "category-results-ready",
    "d_tails_du_marchand_speedygo": "storefront-ready",
    "d_tails_du_produit_speedygo": "product-ready",
    "configuration_du_produit_speedygo": "product-options-ready",
    "recherche_speedygo": "search-idle",
    "r_sultats_de_recherche_speedygo": "search-results-ready",
    "panier_speedygo_c_025": "cart-ready",
    "s_lection_de_l_adresse_speedygo": "checkout-address-ready",
    "r_vision_de_la_commande_speedygo": "checkout-review-ready",
    "historique_des_commandes_speedygo": "orders-in-progress-ready",
    "d_tails_de_la_commande_speedygo": "order-detail-ready",
    "annuler_la_commande_speedygo": "orders-cancelled-ready",
    "profil_speedygo_1": "account-hub-ready",
    "adresses_enregistr_es_speedygo": "addresses-ready",
    "d_tails_du_ticket_support_speedygo": "support-detail-ready",
    "notifications_speedygo": "notifications-ready",
    "s_curit_et_sessions_actives_speedygo": "sessions-ready",
    # Remaining (this visual pass)
    "s_lection_de_la_langue_speedygo_c_002": "language-ready",
    "bienvenue_speedygo": "welcome-ready",
    "num_ro_de_t_l_phone_speedygo": "phone-ready",
    "v_rification_otp_speedygo": "otp-ready",
    "profil_speedygo_2": "profile-setup-ready",
    "r_cup_ration_de_session_speedygo": "restore-loading-ready",
    "mode_de_paiement_speedygo": "checkout-method-ready",
    "confirmation_de_commande_speedygo": "order-confirmation-ready",
    "menu_speedygo": "menu-ready",
    "infos_sur_le_marchand_speedygo": "merchant-info-ready",
    "avis_speedygo": "merchant-reviews-ready",
    "attente_de_confirmation_speedygo": "tracking-waiting-ready",
    "recherche_de_livreur_speedygo": "tracking-searching-ready",
    "suivi_de_livraison_speedygo": "tracking-map-ready",
    "livreur_proximit_speedygo": "tracking-nearby-ready",
    "commande_termin_e_speedygo": "tracking-completed-ready",
    "noter_la_commande_speedygo": "order-rate-ready",
    "r_diger_un_avis_speedygo": "order-write-review-ready",
    "param_tres_de_la_langue_speedygo": "account-language-ready",
    "signaler_un_probl_me_speedygo": "support-create-ready",
    "l_gal_et_confidentialit_speedygo": "legal-ready",
    "param_tres_des_notifications_speedygo": "notification-prefs-ready",
    "suppression_du_compte_speedygo": "account-delete-ready",
    "favoris_speedygo": "favorites-ready",
    "promotions_speedygo": "promotions-ready",
    "instructions_sp_ciales_speedygo": "checkout-notes-ready",
    "permission_de_localisation_speedygo": "location-permission-ready",
    "d_connexion_speedygo": "logout-sheet-ready",
}

# Same HTML artboard, second artifact name (cancel form vs Annulées list).
EXTRA_ALIASES = (
    ("annuler_la_commande_speedygo", "order-cancel-form-ready"),
)

FILL_CSS = """
html, body { margin: 0 !important; padding: 0 !important; width: 100% !important; height: 100% !important; }
body { display: block !important; }
main { width: 100% !important; height: 100vh !important; max-width: none !important; box-shadow: none !important; overflow: hidden !important; }
"""

CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")


def _inject(src: Path, dest: Path) -> None:
    html = src.read_text(encoding="utf-8")
    snippet = f"<style>{FILL_CSS}</style>"
    if "</head>" in html:
        html = html.replace("</head>", snippet + "</head>", 1)
    else:
        html = snippet + html
    dest.write_text(html, encoding="utf-8")


def _chrome_shot(html: Path, dest: Path, width: int, height: int) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(CHROME),
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=2",
        f"--window-size={width},{height}",
        f"--screenshot={dest}",
        "--virtual-time-budget=12000",
        html.resolve().as_uri(),
    ]
    subprocess.run(cmd, check=True, capture_output=True, text=True)


def _all_jobs() -> list[tuple[str, str]]:
    jobs = list(MAPPED.items())
    jobs.extend(EXTRA_ALIASES)
    return jobs


def _playwright_render(jobs: list[tuple[str, str]]) -> list[str]:
    from playwright.sync_api import sync_playwright

    rendered: list[str] = []
    with sync_playwright() as p:
        try:
            browser = p.chromium.launch(channel="chrome")
        except Exception:
            browser = p.chromium.launch()
        for folder, slug in jobs:
            html = SCREENS / folder / "code.html"
            if not html.is_file():
                continue
            uri = html.resolve().as_uri()
            for vp_name, width, height in VIEWPORTS:
                page = browser.new_page(viewport={"width": width, "height": height})
                page.goto(uri, wait_until="networkidle", timeout=60000)
                page.add_style_tag(content=FILL_CSS)
                page.wait_for_timeout(800)
                dest = OUT / f"{slug}-{vp_name}.png"
                page.screenshot(path=str(dest), full_page=False)
                page.close()
                rendered.append(str(dest.relative_to(ROOT)))
        browser.close()
    return rendered


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    jobs = _all_jobs()
    missing_html = [
        folder for folder, _ in jobs if not (SCREENS / folder / "code.html").is_file()
    ]
    engine = "unknown"
    rendered: list[str] = []
    try:
        rendered = _playwright_render(jobs)
        engine = "playwright"
    except Exception as exc:
        if not CHROME.is_file():
            print(f"STITCH_RENDER_BLOCKED playwright={exc!r} chrome_missing", file=sys.stderr)
            return 2
        engine = "chrome-headless"
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            for folder, slug in jobs:
                src = SCREENS / folder / "code.html"
                if not src.is_file():
                    continue
                injected = tmp_path / f"{folder}-{slug}.html"
                _inject(src, injected)
                for vp_name, width, height in VIEWPORTS:
                    dest = OUT / f"{slug}-{vp_name}.png"
                    _chrome_shot(injected, dest, width, height)
                    rendered.append(str(dest.relative_to(ROOT)))
    (OUT / "index.json").write_text(
        json.dumps(
            {
                "engine": engine,
                "rendered": rendered,
                "missingHtml": missing_html,
                "mapped": MAPPED,
                "extraAliases": [list(pair) for pair in EXTRA_ALIASES],
            },
            indent=2,
        )
        + "\n"
    )
    print(f"engine={engine} rendered={len(rendered)} missing_html={len(missing_html)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
