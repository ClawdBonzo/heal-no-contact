#!/usr/bin/env python3
"""Replace the 6.9" screenshot set of every App Store localization with the composed sets.

Usage:  python3 upload_sets.py <appStoreVersionId> [asc-locale ...]    # default: all mapped

For each localization: delete the existing APP_IPHONE_67 set, create a new one, reserve ->
upload -> commit each PNG in order, then poll until Apple reports every asset COMPLETE and
check that the set holds exactly the files we sent (count, order, md5). A locale that fails
verification is reported, not silently left half-uploaded.

Credentials come from AppStore/analytics/asc.py (ASC API key on this Mac only).
"""
import glob, hashlib, os, sys, time
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "analytics"))
from asc import BASE, gj, H, HJ, requests   # noqa: E402

SHOTS = os.path.join(HERE, "..", "..", "AppStoreConnect", "screenshots")
# ASC localization -> composed set (see build_sets.py)
MAP = {
    "en-US": "designed", "en-GB": "designed_en-GB", "en-AU": "designed_en-AU", "en-CA": "designed_en-CA",
    "de-DE": "designed_de", "es-ES": "designed_es", "es-MX": "designed_es-MX",
    "fr-FR": "designed_fr", "it": "designed_it", "nl-NL": "designed_nl", "id": "designed_id",
    "th": "designed_th", "tr": "designed_tr", "ar-SA": "designed_ar", "pt-BR": "designed_pt-BR",
}
DISPLAY = "APP_IPHONE_67"

def md5(b): return hashlib.md5(b).hexdigest()

def upload_set(loc_id, files):
    for s in gj(f"{BASE}/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=20").get("data", []):
        if s["attributes"]["screenshotDisplayType"] == DISPLAY:
            r = requests.delete(f"{BASE}/v1/appScreenshotSets/{s['id']}", headers=H())
            if r.status_code >= 300:
                raise RuntimeError(f"delete old set failed {r.status_code} {r.text[:200]}")
    r = requests.post(f"{BASE}/v1/appScreenshotSets", headers=HJ(), json={"data": {
        "type": "appScreenshotSets", "attributes": {"screenshotDisplayType": DISPLAY},
        "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}})
    if r.status_code >= 300:
        raise RuntimeError(f"create set failed {r.status_code} {r.text[:200]}")
    set_id = r.json()["data"]["id"]
    for f in files:
        data = open(f, "rb").read()
        for attempt in range(4):
            rr = requests.post(f"{BASE}/v1/appScreenshots", headers=HJ(), json={"data": {
                "type": "appScreenshots", "attributes": {"fileName": os.path.basename(f), "fileSize": len(data)},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
            if rr.status_code < 300: break
            time.sleep(3 * (attempt + 1))
        else:
            raise RuntimeError(f"reserve {os.path.basename(f)} failed {rr.status_code} {rr.text[:200]}")
        shot = rr.json()["data"]
        for op in shot["attributes"]["uploadOperations"]:
            chunk = data[op["offset"]:op["offset"] + op["length"]]
            hdrs = {h["name"]: h["value"] for h in op["requestHeaders"]}
            u = requests.request(op["method"], op["url"], headers=hdrs, data=chunk, timeout=180)
            if u.status_code >= 300:
                raise RuntimeError(f"chunk upload {os.path.basename(f)} failed {u.status_code}")
        pr = requests.patch(f"{BASE}/v1/appScreenshots/{shot['id']}", headers=HJ(), json={"data": {
            "type": "appScreenshots", "id": shot["id"],
            "attributes": {"uploaded": True, "sourceFileChecksum": md5(data)}}})
        if pr.status_code >= 300:
            raise RuntimeError(f"commit {os.path.basename(f)} failed {pr.status_code} {pr.text[:200]}")
    return set_id

def verify(set_id, files, timeout=600):
    want = [(os.path.basename(f), md5(open(f, "rb").read())) for f in files]
    deadline = time.time() + timeout
    while True:
        got = gj(f"{BASE}/v1/appScreenshotSets/{set_id}/appScreenshots?limit=20").get("data", [])
        states = [g["attributes"].get("assetDeliveryState", {}).get("state") for g in got]
        if any(s == "FAILED" for s in states):
            errs = [g["attributes"]["assetDeliveryState"].get("errors") for g in got]
            return False, f"asset FAILED: {errs}"
        have = [(g["attributes"]["fileName"], g["attributes"].get("sourceFileChecksum")) for g in got]
        # ASC reports COMPLETE a little before it fills in sourceFileChecksum; wait for both.
        if len(got) == len(want) and all(s == "COMPLETE" for s in states) and all(c for _, c in have):
            return (have == want), ("ok" if have == want else f"mismatch: {have} vs {want}")
        if time.time() > deadline:
            return False, f"timeout: {len(got)}/{len(want)} states={states}"
        time.sleep(8)

def main():
    vid = sys.argv[1]
    only = set(sys.argv[2:])
    locs = {l["attributes"]["locale"]: l["id"] for l in
            gj(f"{BASE}/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50")["data"]}
    unmapped = sorted(set(locs) - set(MAP))
    if unmapped:
        print("WARNING: localizations with no mapped set (left untouched):", unmapped)
    bad = []
    for loc, src in MAP.items():
        if only and loc not in only: continue
        if loc not in locs:
            print(f"{loc}: no such localization on this version"); continue
        files = sorted(glob.glob(os.path.join(SHOTS, src, "*.png")))
        if len(files) != 8:
            print(f"{loc}: expected 8 files in {src}, found {len(files)} — skipped"); bad.append(loc); continue
        try:
            sid = upload_set(locs[loc], files)
            ok, msg = verify(sid, files)
        except Exception as e:
            ok, msg = False, str(e)
        print(f"{loc:6} <- {src:15} {'OK ' if ok else 'BAD'} {msg}")
        if not ok: bad.append(loc)
    print("FAILED:", bad or "none")
    sys.exit(1 if bad else 0)

if __name__ == "__main__":
    main()
