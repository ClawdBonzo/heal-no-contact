"""App Store Connect / RevenueCat / Appfigures helpers for the weekly checkup.

DATA-INTEGRITY RULES (these exist because analytics tooling rots silently):
  * Never hardcode a date. Every window is derived from `today()` at run time.
  * Report names change (Apple renamed "App Downloads" -> "App Downloads Standard").
    Always resolve report names by PREFIX, never exact match.
  * A pull returning zero rows must be distinguishable from a pull that failed.
    Helpers return (rows, status) so callers can say which it was.
"""
import datetime, gzip, io, csv, json, time
import jwt, requests

KEY_ID = "K34HFNJTXH"
ISSUER = "69a6de84-f289-47e3-e053-5b8c7c11a4d1"
P8     = "/Users/robgoldstein/.appstoreconnect/private_keys/AuthKey_K34HFNJTXH.p8"
VENDOR = "86593604"
APP_ID = "6761851731"
BASE   = "https://api.appstoreconnect.apple.com"

RC_KEY  = None  # secret removed from history; see ~/.appstoreconnect/heal_secrets.json
RC_PROJ = "proje4ef80cd"
AF_PAT  = None  # secret removed from history; see ~/.appstoreconnect/heal_secrets.json
AF_PROD = "338571844335"

# ---------- dates: ALWAYS relative, never hardcoded ----------
def today():      return datetime.date.today()
def yesterday():  return today() - datetime.timedelta(days=1)
def window(days): 
    """Inclusive window of `days` ending yesterday (Apple has no same-day data)."""
    end = yesterday()
    return end - datetime.timedelta(days=days-1), end
def daterange(a, b):
    d = a
    while d <= b:
        yield d
        d += datetime.timedelta(days=1)

# ---------- auth ----------
def tok():
    now = int(time.time())
    return jwt.encode({"iss": ISSUER, "iat": now, "exp": now + 1200,
                       "aud": "appstoreconnect-v1"},
                      open(P8).read(), algorithm="ES256", headers={"kid": KEY_ID})
def H():  return {"Authorization": f"Bearer {tok()}"}
def HJ(): return {**H(), "Content-Type": "application/json"}
def g(u, **kw):  return requests.get(u, headers=H(), timeout=90, **kw)
def gj(u):
    r = g(u)
    try: return r.json()
    except Exception: return {"_status": r.status_code, "_text": r.text[:300]}
def paged(u, limit=200):
    """Follow links.next; returns all data rows."""
    out = []
    while u:
        d = gj(u)
        out += d.get("data", [])
        u = (d.get("links") or {}).get("next")
    return out

# ---------- sales reports (AUTHORITATIVE for downloads + revenue) ----------
def sales_report(date, report_type="SALES", sub_type="SUMMARY", version=None, freq="DAILY"):
    """Returns (rows, status). status: 'ok' | 'empty(404=no data that day)' | 'error:N'."""
    params = {"filter[frequency]": freq, "filter[reportType]": report_type,
              "filter[reportSubType]": sub_type, "filter[vendorNumber]": VENDOR,
              "filter[reportDate]": date.isoformat()}
    if version: params["filter[version]"] = version
    r = g(f"{BASE}/v1/salesReports", params=params)
    if r.status_code == 404:
        return [], "empty(no report for that date)"
    if r.status_code != 200:
        return [], f"error:{r.status_code}"
    try:
        txt = gzip.decompress(r.content).decode("utf-8", "ignore")
    except Exception:
        txt = r.content.decode("utf-8", "ignore")
    return list(csv.DictReader(io.StringIO(txt), delimiter="\t")), "ok"

def ours(rec):
    return (rec.get("Apple Identifier") == APP_ID or rec.get("SKU") == "HealNoContact2026"
            or "Heal" in (rec.get("Title") or rec.get("App Name") or ""))

# ---------- analytics reports (bucketed by Apple; do NOT mix with Sales) ----------
def analytics_requests():
    return gj(f"{BASE}/v1/apps/{APP_ID}/analyticsReportRequests").get("data", [])

def find_reports(name_prefix, access="ONGOING"):
    """PREFIX match — Apple renames reports; exact match silently returns nothing."""
    hits = []
    for q in analytics_requests():
        if access and q["attributes"].get("accessType") != access: continue
        for rp in paged(f"{BASE}/v1/analyticsReportRequests/{q['id']}/reports?limit=200"):
            if rp["attributes"]["name"].startswith(name_prefix):
                hits.append((q["attributes"]["accessType"], rp["id"], rp["attributes"]["name"]))
    return hits

def report_rows(report_id, max_instances=8):
    """Returns (rows, status, dates_seen)."""
    insts = gj(f"{BASE}/v1/analyticsReports/{report_id}/instances?limit=50").get("data", [])
    if not insts:
        return [], "no instances yet (Apple still generating)", []
    rows, seen = [], []
    for i in sorted(insts, key=lambda x: x["attributes"]["processingDate"], reverse=True)[:max_instances]:
        seen.append(i["attributes"]["processingDate"])
        segs = gj(f"{BASE}/v1/analyticsReportInstances/{i['id']}/segments").get("data", [])
        for s in segs:
            raw = requests.get(s["attributes"]["url"], timeout=180).content
            try: txt = gzip.decompress(raw).decode("utf-8", "ignore")
            except Exception: txt = raw.decode("utf-8", "ignore")
            rows += list(csv.DictReader(io.StringIO(txt), delimiter="\t"))
    return rows, ("ok" if rows else "instances exist but 0 rows"), seen

# ---------- other services ----------
def rc(path):
    r = requests.get(f"https://api.revenuecat.com/v2/projects/{RC_PROJ}{path}",
                     headers={"Authorization": f"Bearer {RC_KEY}"}, timeout=60)
    try: return r.json()
    except Exception: return {"_status": r.status_code}

def af(path, **params):
    r = requests.get("https://api.appfigures.com/v2" + path,
                     headers={"Authorization": f"Bearer {AF_PAT}"}, params=params, timeout=90)
    try: return r.json()
    except Exception: return {"_status": r.status_code, "_text": r.text[:200]}
