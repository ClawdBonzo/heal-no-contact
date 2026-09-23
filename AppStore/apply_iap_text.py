#!/usr/bin/env python3
"""Apply the reviewed product-text edits in iap_text_edits.json (Yearly "save 58%" removal,
localized best-value badges, Dutch/German/Indonesian Lifetime wording).

WHY a separate script: App Store Connect refuses edits to approved product localizations
(409 UNMODIFIABLE / "version is not editable") while an app version is in review. Run this
after 1.5 clears review; it is idempotent and exits 2 while the products are still locked.
Afterwards the products need to be submitted (subscriptionSubmissions / inAppPurchaseSubmissions).
"""
import json, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "analytics"))
from asc import BASE, gj, HJ, requests   # noqa: E402

APP = "6761851731"
HERE = os.path.dirname(os.path.abspath(__file__))
EDITS = json.load(open(os.path.join(HERE, "iap_text_edits.json")))

def locs():
    ids, prod_ids = {}, {}
    grp = gj(f"{BASE}/v1/apps/{APP}/subscriptionGroups")["data"][0]
    for x in gj(f"{BASE}/v1/subscriptionGroups/{grp['id']}/subscriptionGroupLocalizations?limit=50")["data"]:
        ids[(x["attributes"]["locale"], "group")] = ("subscriptionGroupLocalizations", x["id"], x["attributes"])
    pmap = {"com.healnocontact.premium.weekly": "weekly", "com.healnocontact.premium.monthly": "monthly",
            "com.healnocontact.premium.yearly": "yearly"}
    for s in gj(f"{BASE}/v1/subscriptionGroups/{grp['id']}/subscriptions")["data"]:
        prod_ids[pmap[s["attributes"]["productId"]]] = ("subscriptions", s["id"])
        for x in gj(f"{BASE}/v1/subscriptions/{s['id']}/subscriptionLocalizations?limit=50")["data"]:
            ids[(x["attributes"]["locale"], pmap[s["attributes"]["productId"]])] = ("subscriptionLocalizations", x["id"], x["attributes"])
    for i in gj(f"{BASE}/v1/apps/{APP}/inAppPurchasesV2?limit=50")["data"]:
        prod_ids["lifetime"] = ("inAppPurchases", i["id"])
        for x in gj(f"{BASE}/v2/inAppPurchases/{i['id']}/inAppPurchaseLocalizations?limit=50")["data"]:
            ids[(x["attributes"]["locale"], "lifetime")] = ("inAppPurchaseLocalizations", x["id"], x["attributes"])
    return ids, prod_ids

def main():
    ids, prod_ids = locs()
    done = locked = failed = 0
    touched = set()
    for e in EDITS:
        typ, iid, cur = ids[(e["asc_locale"], e["product"])]
        if cur.get(e["field"]) == e["new_value"]:
            done += 1; continue
        r = requests.patch(f"{BASE}/v1/{typ}/{iid}", headers=HJ(), json={"data": {"type": typ, "id": iid,
                           "attributes": {e["field"]: e["new_value"]}}})
        if r.status_code < 300:
            done += 1; touched.add(e["product"])
        elif r.status_code == 409:
            locked += 1
        else:
            failed += 1; print("FAIL", e["asc_locale"], e["product"], e["field"], r.status_code, r.text[:200])
    print(f"applied/already-correct {done}, locked {locked}, failed {failed} of {len(EDITS)}")
    # Changed products must be submitted again (allowed because each was approved before).
    for p in sorted(touched):
        kind, pid = prod_ids.get(p, (None, None))
        if kind == "subscriptions":
            r = requests.post(f"{BASE}/v1/subscriptionSubmissions", headers=HJ(), json={"data": {"type": "subscriptionSubmissions",
                              "relationships": {"subscription": {"data": {"type": "subscriptions", "id": pid}}}}})
            print("submit", p, r.status_code, "" if r.status_code < 300 else r.text[:160])
        elif kind == "inAppPurchases":
            r = requests.post(f"{BASE}/v1/inAppPurchaseSubmissions", headers=HJ(), json={"data": {"type": "inAppPurchaseSubmissions",
                              "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": pid}}}}})
            print("submit", p, r.status_code, "" if r.status_code < 300 else r.text[:160])
    sys.exit(0 if (locked == 0 and failed == 0) else 2)

if __name__ == "__main__":
    main()
