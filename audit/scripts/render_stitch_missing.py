#!/usr/bin/env python3
"""Bounded Stitch render: only missing slug×viewport pairs, with retries."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path("/Users/mac/Downloads/speedygo_project")
SCREENS = ROOT / "screens" / "CustomerScreens"
WIDGET = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "widget" / "mocked"
STITCH = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "stitch"
COMPARE_INDEX = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "compare" / "index.json"
REPORT = ROOT / "apps" / "customer_app" / "audit" / "visuals" / "stitch" / "missing-render-report.json"

CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
MAX_ATTEMPTS = 3
TIMEOUT_S = 50

# folder → slug (from render_stitch.MAPPED + cancel-form alias)
FOLDER_FOR_SLUG = {
    "home-ready": "accueil_speedygo",
    "categories-ready": "toutes_les_cat_gories_speedygo_c_012",
    "category-results-ready": "restaurants_speedygo",
    "storefront-ready": "d_tails_du_marchand_speedygo",
    "product-ready": "d_tails_du_produit_speedygo",
    "product-options-ready": "configuration_du_produit_speedygo",
    "search-idle": "recherche_speedygo",
    "search-results-ready": "r_sultats_de_recherche_speedygo",
    "cart-ready": "panier_speedygo_c_025",
    "checkout-address-ready": "s_lection_de_l_adresse_speedygo",
    "checkout-review-ready": "r_vision_de_la_commande_speedygo",
    "orders-in-progress-ready": "historique_des_commandes_speedygo",
    "order-detail-ready": "d_tails_de_la_commande_speedygo",
    "orders-cancelled-ready": "annuler_la_commande_speedygo",
    "account-hub-ready": "profil_speedygo_1",
    "addresses-ready": "adresses_enregistr_es_speedygo",
    "support-detail-ready": "d_tails_du_ticket_support_speedygo",
    "notifications-ready": "notifications_speedygo",
    "sessions-ready": "s_curit_et_sessions_actives_speedygo",
    "language-ready": "s_lection_de_la_langue_speedygo_c_002",
    "welcome-ready": "bienvenue_speedygo",
    "phone-ready": "num_ro_de_t_l_phone_speedygo",
    "otp-ready": "v_rification_otp_speedygo",
    "profile-setup-ready": "profil_speedygo_2",
    "restore-loading-ready": "r_cup_ration_de_session_speedygo",
    "checkout-method-ready": "mode_de_paiement_speedygo",
    "order-confirmation-ready": "confirmation_de_commande_speedygo",
    "menu-ready": "menu_speedygo",
    "merchant-info-ready": "infos_sur_le_marchand_speedygo",
    "merchant-reviews-ready": "avis_speedygo",
    "order-cancel-form-ready": "annuler_la_commande_speedygo",
    "tracking-waiting-ready": "attente_de_confirmation_speedygo",
    "tracking-searching-ready": "recherche_de_livreur_speedygo",
    "tracking-map-ready": "suivi_de_livraison_speedygo",
    "tracking-nearby-ready": "livreur_proximit_speedygo",
    "tracking-completed-ready": "commande_termin_e_speedygo",
    "order-rate-ready": "noter_la_commande_speedygo",
    "order-write-review-ready": "r_diger_un_avis_speedygo",
    "account-language-ready": "param_tres_de_la_langue_speedygo",
    "support-create-ready": "signaler_un_probl_me_speedygo",
    "legal-ready": "l_gal_et_confidentialit_speedygo",
    "notification-prefs-ready": "param_tres_des_notifications_speedygo",
    "account-delete-ready": "suppression_du_compte_speedygo",
    "favorites-ready": "favoris_speedygo",
    "promotions-ready": "promotions_speedygo",
    "checkout-notes-ready": "instructions_sp_ciales_speedygo",
    "location-permission-ready": "permission_de_localisation_speedygo",
    "logout-sheet-ready": "d_connexion_speedygo",
    "splash-ready": "splash_speedygo",
    "splash2-ready": "splash_speedygo2",
    "payment-ready": "paiement_speedygo",
    "payment-redirect-ready": "redirection_vers_le_paiement_speedygo",
}

VIEWPORTS = {
    "se-375x667": (375, 667),
    "iphone17pro-402x874": (402, 874),
}

FILL_CSS = (
    "html, body { margin:0!important;padding:0!important;width:100%!important;"
    "height:100%!important;} "
    "main{width:100%!important;height:100vh!important;max-width:none!important;"
    "box-shadow:none!important;overflow:hidden!important;}"
)


def _jobs_from_compare_missing() -> list[tuple[str, str]]:
    rows = json.loads(COMPARE_INDEX.read_text(encoding="utf-8"))
    jobs: list[tuple[str, str]] = []
    for row in rows:
        if row.get("status") != "missing":
            continue
        if row.get("stitch"):
            continue  # stitch present; flutter gap handled elsewhere
        slug = row["slug"]
        vp = row["viewport"]
        jobs.append((slug, vp))
    return jobs


def _extra_splash_payment() -> list[tuple[str, str]]:
    extras = []
    for slug in (
        "splash-ready",
        "splash2-ready",
        "payment-ready",
        "payment-redirect-ready",
    ):
        for vp in VIEWPORTS:
            dest = STITCH / f"{slug}-{vp}.png"
            if not dest.is_file():
                extras.append((slug, vp))
    return extras


def _chrome(html: Path, dest: Path, width: int, height: int) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(CHROME),
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--force-device-scale-factor=2",
        f"--window-size={width},{height}",
        f"--screenshot={dest}",
        "--virtual-time-budget=10000",
        html.resolve().as_uri(),
    ]
    subprocess.run(cmd, check=True, capture_output=True, text=True, timeout=TIMEOUT_S)


def main() -> int:
    if not CHROME.is_file():
        print("CHROME_MISSING", file=sys.stderr)
        return 2
    jobs = _jobs_from_compare_missing() + _extra_splash_payment()
    # de-dupe preserving order
    seen: set[tuple[str, str]] = set()
    ordered: list[tuple[str, str]] = []
    for job in jobs:
        if job in seen:
            continue
        seen.add(job)
        ordered.append(job)

    results = []
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        for slug, vp in ordered:
            folder = FOLDER_FOR_SLUG.get(slug)
            width, height = VIEWPORTS[vp]
            dest = STITCH / f"{slug}-{vp}.png"
            entry: dict = {"slug": slug, "viewport": vp, "folder": folder}
            if not folder:
                entry["status"] = "unmapped"
                results.append(entry)
                print("unmapped", slug, vp, flush=True)
                continue
            src = SCREENS / folder / "code.html"
            if not src.is_file():
                entry["status"] = "html_missing"
                results.append(entry)
                print("html_missing", slug, vp, flush=True)
                continue
            html = src.read_text(encoding="utf-8")
            if "</head>" in html:
                html = html.replace("</head>", f"<style>{FILL_CSS}</style></head>", 1)
            else:
                html = f"<style>{FILL_CSS}</style>" + html
            injected = tmp_path / f"{slug}-{vp}.html"
            injected.write_text(html, encoding="utf-8")
            ok = False
            last_err = None
            for attempt in range(1, MAX_ATTEMPTS + 1):
                try:
                    if dest.is_file():
                        dest.unlink()
                    _chrome(injected, dest, width, height)
                    if dest.is_file() and dest.stat().st_size > 1000:
                        ok = True
                        entry["status"] = "rendered"
                        entry["attempts"] = attempt
                        entry["bytes"] = dest.stat().st_size
                        print("ok", dest.name, f"attempt={attempt}", flush=True)
                        break
                    last_err = "empty_or_tiny"
                except Exception as exc:  # noqa: BLE001
                    last_err = f"{type(exc).__name__}:{exc}"
                    print("retry", slug, vp, attempt, last_err, flush=True)
                    time.sleep(1.5 * attempt)
            if not ok:
                entry["status"] = "failed"
                entry["error"] = last_err
                print("fail", slug, vp, last_err, flush=True)
            results.append(entry)

    summary = {
        "rendered": sum(1 for r in results if r.get("status") == "rendered"),
        "failed": sum(1 for r in results if r.get("status") == "failed"),
        "html_missing": sum(1 for r in results if r.get("status") == "html_missing"),
        "unmapped": sum(1 for r in results if r.get("status") == "unmapped"),
        "results": results,
    }
    REPORT.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(
        f"summary rendered={summary['rendered']} failed={summary['failed']} "
        f"html_missing={summary['html_missing']} unmapped={summary['unmapped']}"
    )
    return 0 if summary["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
