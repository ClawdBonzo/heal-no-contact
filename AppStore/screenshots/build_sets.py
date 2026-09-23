#!/usr/bin/env python3
"""Compose every locale's 8-shot set from raw_<lang>/ + headlines.json in one run.

WHY: sets used to be made one locale at a time by whatever tool existed then. By 1.5 the
store showed three different designs side by side (framed phone + shadowed text; flat
purple + all-caps Arial Black with 3-line overflow; the current gradient/inset look),
five different status-bar clocks, English UI in some localized sets and badge toasts in
others. One driver, one compositor, one capture run keeps them identical.

Usage:  python3 build_sets.py [lang ...]      # default: all
Raw captures come from ./capture.sh <lang> <udid> raw_<lang>; they are not committed
(reproducible, ~7 MB per locale). Output goes to AppStoreConnect/screenshots/designed*/.
"""
import json, os, sys
from compose import compose

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_ROOT = os.path.join(HERE, "..", "..", "AppStoreConnect", "screenshots")
# capture language -> (headlines.json key, output dir). ASC locales map onto these in
# upload_sets.py (en-US uses `designed`; en-GB/AU/CA have their own sets).
SETS = {
    "en":    ("en",    "designed"),
    # Same English UI and headlines, but each storefront's own prices and date format
    # (the shared set showed US$4.99 to UK, Australian and Canadian customers).
    "en-GB": ("en",    "designed_en-GB"),
    "en-AU": ("en",    "designed_en-AU"),
    "en-CA": ("en",    "designed_en-CA"),
    "de":    ("de",    "designed_de"),
    "es":    ("es",    "designed_es"),
    "es-MX": ("es",    "designed_es-MX"),   # es-MX UI strings, shared Spanish headlines
    "fr":    ("fr",    "designed_fr"),
    "it":    ("it",    "designed_it"),
    "nl":    ("nl",    "designed_nl"),
    "id":    ("id",    "designed_id"),
    "th":    ("th",    "designed_th"),
    "tr":    ("tr",    "designed_tr"),
    "ar":    ("ar",    "designed_ar"),
    "pt-BR": ("pt-BR", "designed_pt-BR"),
}

def main(langs):
    heads = json.load(open(os.path.join(HERE, "headlines.json")))
    for lang in langs:
        key, out = SETS[lang]
        raw_dir = os.path.join(HERE, f"raw_{lang}")
        dst = os.path.join(OUT_ROOT, out)
        os.makedirs(dst, exist_ok=True)
        for shot, lines in heads[key].items():
            raw = os.path.join(raw_dir, f"{shot}.png")
            if not os.path.exists(raw):
                raise SystemExit(f"ABORT: missing {raw} — run ./capture.sh {lang} <udid> raw_{lang}")
            # "Heal Premium" is the product's brand name, so it stays untranslated.
            compose(raw, os.path.join(dst, f"{shot}.png"), lines,
                    badge="Heal Premium" if shot == "04-insights" else None)
        print(f"{lang}: {len(heads[key])} shots -> {out}")

if __name__ == "__main__":
    main(sys.argv[1:] or list(SETS))
