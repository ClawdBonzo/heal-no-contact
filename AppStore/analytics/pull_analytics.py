import sys, json, collections, datetime
sys.path.insert(0,'.')
from asc import *
avail=json.load(open("available_reports.json"))
out={}
def grab(prefix):
    ents=[e for nm,v in avail.items() if nm.startswith(prefix) for e in v]
    rows, dates, status = [], set(), []
    for acc,rid,n,d0,d1,gran in ents:
        r,st,seen = report_rows(rid, max_instances=20)
        status.append(f"{acc}:{st}:{len(r)}rows")
        for x in r: x["_access"]=acc
        rows+=r; dates|=set(seen)
    return rows, status, sorted(dates)

for key,prefix in [("discovery","App Store Discovery and Engagement Standard"),
                   ("discovery_detail","App Store Discovery and Engagement Detailed"),
                   ("downloads","App Downloads Standard"),
                   ("downloads_detail","App Downloads Detailed"),
                   ("sessions","App Sessions Standard"),
                   ("instdel","App Store Installation and Deletion Standard"),
                   ("webpreview","App Store Web Preview Engagement Standard")]:
    rows, st, dates = grab(prefix)
    out[key]={"status":st,"instance_dates":dates,"n":len(rows),
              "columns": sorted(rows[0].keys()) if rows else [], "rows":rows}
    print(f"{key:18} {len(rows):5} rows | {st} | dates {dates[:2]}..{dates[-2:] if dates else ''}")
json.dump(out, open("raw_analytics.json","w"))
print("\nColumns:")
for k in out:
    if out[k]["columns"]: print(" ",k,":",out[k]["columns"])
