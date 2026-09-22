"""In-app localization audit: every string the Swift compiler extracted from the code
(*.stringsdata, produced by any build with SWIFT_EMIT_LOC_STRINGS=YES) vs the String
Catalogs. A key used in code but absent from the catalog ships in English in every
language, silently — that is how the 1.3 trial-ending notification, "Rate Heal" and
"Write a review" went out untranslated.

Usage: python3 AppStore/localization_audit.py <DerivedData-or-build-dir>
"""
import sys, json, glob, os, collections

root = sys.argv[1]
repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOGS = {"HealNoContact": os.path.join(repo, "HealNoContact/Localizable.xcstrings"),
            "HealNoContactWidgetExtension": os.path.join(repo, "HealNoContactWidget/Localizable.xcstrings")}

def target_of(path):
    for t in ("HealNoContactWidgetExtension", "HealNoContact"):
        if f"/{t}.build/" in path:
            return t
    return None

used = collections.defaultdict(dict)     # target -> key -> "file:line"
newest = {}
# Only the build intermediates hold .stringsdata; globbing a whole DerivedData folder
# also walks SourcePackages/ (thousands of files) and took minutes.
inter = os.path.join(root, "Build", "Intermediates.noindex")
for f in glob.glob(os.path.join(inter if os.path.isdir(inter) else root, "**/*.stringsdata"), recursive=True):
    t = target_of(f)
    if not t or "/RevenueCat" in f:
        continue
    d = json.load(open(f))
    for tbl, entries in (d.get("tables") or {}).items():
        if tbl != "Localizable":
            continue
        for e in entries:
            loc = e.get("location") or {}
            used[t][e["key"]] = f"{os.path.basename(d.get('source',''))}:{loc.get('startingLine')}"

report = {}
for t, cat_path in CATALOGS.items():
    cat = json.load(open(cat_path))
    S = cat["strings"]
    langs = sorted({l for v in S.values() for l in v.get("localizations", {})} - {"en"})
    missing = {k: w for k, w in used[t].items() if k not in S}
    untranslated = {}
    for k in used[t]:
        if k not in S or S[k].get("shouldTranslate") is False:
            continue
        locs = S[k].get("localizations", {})
        gaps = [l for l in langs if l not in locs
                or (locs[l].get("stringUnit") or {}).get("state") not in ("translated", None)
                and not locs[l].get("variations")]
        if gaps:
            untranslated[k] = gaps
    unused = sorted(k for k in S if k not in used[t] and S[k].get("extractionState") != "manual")
    report[t] = {"languages": langs, "keys_used": len(used[t]), "missing_from_catalog": missing,
                 "untranslated": untranslated, "catalog_keys_not_in_code": unused}
    print(f"\n== {t}: {len(used[t])} keys used in code, {len(S)} in catalog, languages {langs}")
    print(f"  MISSING from catalog (ship in English everywhere): {len(missing)}")
    for k, w in sorted(missing.items(), key=lambda x: x[1]):
        print(f"    {w:34} {k!r}")
    print(f"  in catalog but untranslated in some language: {len(untranslated)}")
    for k, g in untranslated.items():
        print(f"    {k!r} -> {g}")
    print(f"  catalog keys not used by code: {len(unused)}")
json.dump(report, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "localization_audit.json"), "w"),
          ensure_ascii=False, indent=1)
