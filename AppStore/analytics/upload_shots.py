import sys, os, glob, hashlib, time; sys.path.insert(0,'.')
from asc import *
vid=open("/tmp/v13.txt").read().strip()
REPO="/Users/robgoldstein/Desktop/HealNoContact/AppStoreConnect/screenshots"
# locale -> source dir
MAP={"en-US":"designed","en-GB":"designed","en-AU":"designed","en-CA":"designed","tr":"designed_tr"}
locs={l["attributes"]["locale"]:l["id"] for l in gj(f"{BASE}/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=25")["data"]}
for loc,srcdir in MAP.items():
    lid=locs.get(loc)
    if not lid: print(f"{loc}: no localization"); continue
    files=sorted(glob.glob(f"{REPO}/{srcdir}/*.png"))
    # delete any existing 6.9" set so we replace rather than append
    for s in gj(f"{BASE}/v1/appStoreVersionLocalizations/{lid}/appScreenshotSets?limit=10").get("data",[]):
        if s["attributes"]["screenshotDisplayType"]=="APP_IPHONE_67":
            requests.delete(f"{BASE}/v1/appScreenshotSets/{s['id']}",headers=H())
    r=requests.post(f"{BASE}/v1/appScreenshotSets",headers=HJ(),
        json={"data":{"type":"appScreenshotSets","attributes":{"screenshotDisplayType":"APP_IPHONE_67"},
              "relationships":{"appStoreVersionLocalization":{"data":{"type":"appStoreVersionLocalizations","id":lid}}}}})
    if r.status_code>=300: print(f"{loc}: set create failed {r.status_code} {r.text[:150]}"); continue
    sid=r.json()["data"]["id"]; ok=0
    for f in files:
        data=open(f,"rb").read()
        for attempt in range(3):
            rr=requests.post(f"{BASE}/v1/appScreenshots",headers=HJ(),
                json={"data":{"type":"appScreenshots","attributes":{"fileName":os.path.basename(f),"fileSize":len(data)},
                      "relationships":{"appScreenshotSet":{"data":{"type":"appScreenshotSets","id":sid}}}}})
            if rr.status_code<300: break
            time.sleep(3)
        if rr.status_code>=300: print(f"   reserve failed {os.path.basename(f)} {rr.status_code}"); continue
        shot=rr.json()["data"]
        good=True
        for op in shot["attributes"]["uploadOperations"]:
            chunk=data[op["offset"]:op["offset"]+op["length"]]
            hdrs={h["name"]:h["value"] for h in op["requestHeaders"]}
            u=requests.request(op["method"],op["url"],headers=hdrs,data=chunk,timeout=180)
            if u.status_code>=300: good=False; break
        if not good: print("   chunk upload failed", os.path.basename(f)); continue
        pr=requests.patch(f"{BASE}/v1/appScreenshots/{shot['id']}",headers=HJ(),
            json={"data":{"type":"appScreenshots","id":shot["id"],
                  "attributes":{"uploaded":True,"sourceFileChecksum":hashlib.md5(data).hexdigest()}}})
        ok += pr.status_code<300
    print(f"{loc}: uploaded {ok}/{len(files)} from {srcdir}")
