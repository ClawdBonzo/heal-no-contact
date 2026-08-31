import sys, json, collections, datetime
sys.path.insert(0,'.')
from asc import *

LIFETIME_START = datetime.date(2026,6,9)   # first App Store release
out = {"generated": str(today()), "coverage_through": str(yesterday())}

# ---- SALES (downloads + units), day by day, lifetime ----
days = list(daterange(LIFETIME_START, yesterday()))
per_day, statuses = {}, collections.Counter()
for d in days:
    rows, st = sales_report(d)
    statuses[st] += 1
    rec = [r for r in rows if ours(r)]
    per_day[str(d)] = rec
out["sales_status_counts"] = dict(statuses)

def units(rows, types=None):
    n=0
    for r in rows:
        t=r.get("Product Type Identifier","")
        if types and t not in types: continue
        n += int(r.get("Units") or 0)
    return n

# Apple product type ids: 1/1F/1T = first-time app, 3/3F = update, 7/7F = redownload
FIRST  = {"1","1F","1T"}         # 1T = tvOS; keep for completeness
UPDATE = {"7","7F","7T"}
REDL   = {"3","3F","3T"}
allrows = [r for v in per_day.values() for r in v]
seen_types = collections.Counter((r.get("Product Type Identifier"), ) for r in allrows)
out["observed_product_types"] = {str(k[0]): v for k,v in seen_types.items()}

def slice_window(a,b):
    return [r for d,v in per_day.items() if a <= datetime.date.fromisoformat(d) <= b for r in v]

w0a,w0b = window(7)                 # this week
w1a,w1b = w0a - datetime.timedelta(days=7), w0a - datetime.timedelta(days=1)
cur, prev = slice_window(w0a,w0b), slice_window(w1a,w1b)
out["windows"] = {"this_week": [str(w0a), str(w0b)], "prior_week": [str(w1a), str(w1b)]}

def bucket(rows):
    b=collections.Counter()
    for r in rows:
        t=r.get("Product Type Identifier","")
        u=int(r.get("Units") or 0)
        if t in FIRST: b["first_time"]+=u
        elif t in UPDATE: b["update"]+=u
        elif t in REDL: b["redownload"]+=u
        else: b[f"other:{t}"]+=u
    return dict(b)
out["downloads"] = {"lifetime": bucket(allrows), "this_week": bucket(cur), "prior_week": bucket(prev)}

def by_country(rows, types=FIRST):
    c=collections.Counter()
    for r in rows:
        if r.get("Product Type Identifier") in types:
            c[r.get("Country Code")] += int(r.get("Units") or 0)
    return dict(c)
out["country"] = {"lifetime": by_country(allrows), "this_week": by_country(cur), "prior_week": by_country(prev)}

# revenue from sales rows (proceeds)
def proceeds(rows):
    tot=0.0
    for r in rows:
        try: tot += float(r.get("Developer Proceeds") or 0) * int(r.get("Units") or 0)
        except Exception: pass
    return round(tot,2)
out["sales_proceeds"] = {"lifetime": proceeds(allrows), "this_week": proceeds(cur), "prior_week": proceeds(prev)}

# ---- SUBSCRIPTION reports (active/state) ----
sub_rows, sub_status, sub_dates = [], None, []
for back in range(1, 8):
    d = yesterday() - datetime.timedelta(days=back-1)
    rows, st = sales_report(d, report_type="SUBSCRIPTION", sub_type="SUMMARY", version="1_4")
    if st=="ok" and rows:
        sub_rows, sub_status, sub_dates = rows, st, [str(d)]
        break
    sub_status = st
out["subscription_report"] = {"status": sub_status, "date": sub_dates,
    "rows": [r for r in sub_rows if "Heal" in (r.get("App Name","")+r.get("Subscription Name",""))
             or r.get("Subscription Apple ID") in ("6761851628","6761851880","6761851605")]}

# ---- SUBSCRIPTION EVENT report (trials, cancels, reasons) ----
ev_all, ev_status = [], None
for d in daterange(*window(14)):
    rows, st = sales_report(d, report_type="SUBSCRIPTION_EVENT", sub_type="SUMMARY", version="1_3")
    ev_status = st if st!="ok" else "ok"
    if st=="ok":
        ev_all += [r for r in rows if "Heal" in (r.get("App Name","") + r.get("Subscription Name",""))]
out["subscription_events"] = {"status": ev_status, "count": len(ev_all), "rows": ev_all}

json.dump(out, open("raw_sales.json","w"), indent=1)
print("sales day statuses:", dict(statuses))
print("observed product types:", out["observed_product_types"])
print("downloads lifetime:", out["downloads"]["lifetime"])
print("this week:", out["downloads"]["this_week"], "| prior:", out["downloads"]["prior_week"])
print("country this week:", out["country"]["this_week"])
print("proceeds:", out["sales_proceeds"])
print("subscription report:", out["subscription_report"]["status"], out["subscription_report"]["date"], "rows:", len(out["subscription_report"]["rows"]))
print("subscription events:", ev_status, len(ev_all))
