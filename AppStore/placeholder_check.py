"""Format-placeholder check for every translation in the String Catalogs.
A translation whose placeholders differ from its key's (count, type, or a stray '%'
that the formatter reads as a specifier) prints garbage or crashes at runtime — the
widget's "%lld % des …" was exactly this. Run after any catalog edit."""
import json, re, sys
SPEC = re.compile(r"%(?:(\d+)\$)?([-+ #0]*\d*(?:\.\d+)?)(ll|l|h|hh|q|L|z|t|j)?([@dDuUxXoOfFeEgGcCsSp%])")
def specs(s):
    out, i = [], 0
    for m in SPEC.finditer(s):
        pos, flags, length, conv = m.groups()
        if conv == "%": continue
        out.append((int(pos) if pos else None, (length or "") + conv, flags))
    return out
def stray(s):
    # a '%' that doesn't start a valid spec and isn't '%%'
    t = SPEC.sub("", s)
    return "%" in t
def signature(sp):
    if any(p is not None for p, _, _ in sp):
        return sorted((p, c) for p, c, _ in sp)
    return [(i + 1, c) for i, (_, c, _) in enumerate(sp)]
bad = 0
for cat in sys.argv[1:]:
    S = json.load(open(cat))["strings"]
    for key, v in S.items():
        if v.get("shouldTranslate") is False: continue
        # Only format keys are run through the formatter: ones Xcode generated from string
        # interpolation (they carry %lld/%@/%% etc.). A literal like "Save 58%" or
        # "100% on-device" is displayed verbatim, so a '%' in its translations is fine.
        if not ("%%" in key or any(f.strip() == f for _, _, f in specs(key))):
            continue
        ks = signature(specs(key))
        for lang, loc in v.get("localizations", {}).items():
            units = []
            if "stringUnit" in loc: units.append(("", loc["stringUnit"].get("value", "")))
            for vk, vv in (loc.get("variations") or {}).items():
                for case, cv in vv.items(): units.append((f"{vk}.{case}", (cv.get("stringUnit") or {}).get("value", "")))
            for tag, val in units:
                vs = signature(specs(val))
                problems = []
                if [c for _, c in vs] and sorted(c for _, c in vs) != sorted(c for _, c in ks): problems.append(f"types {sorted(c for _,c in vs)} vs key {sorted(c for _,c in ks)}")
                elif not vs and ks: problems.append(f"missing placeholders {ks}")
                elif vs != ks and not any(p for p, _, _ in specs(val) if p) and [c for _, c in vs] != [c for _, c in ks]: problems.append("order differs without positional args")
                if any(f for _, _, f in specs(val) if f.strip() == "" and f): problems.append("space-flag spec (likely an unescaped '% ')")
                if stray(val): problems.append("stray '%'")
                if problems:
                    bad += 1
                    print(f"{cat.split('/')[-2]:22} {lang:6} {key[:50]!r}{(' ['+tag+']') if tag else ''}: {'; '.join(problems)}  -> {val[:70]!r}")
print(f"\n{bad} placeholder problem(s)")
sys.exit(1 if bad else 0)
