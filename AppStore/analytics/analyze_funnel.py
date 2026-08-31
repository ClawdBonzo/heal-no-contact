import sys, json, collections, datetime
sys.path.insert(0,'.')
from asc import window
A=json.load(open("raw_analytics.json"))
w0a,w0b=window(7); w1a=w0a-datetime.timedelta(days=7); w1b=w0a-datetime.timedelta(days=1)
def dedup(rows):
    seen={}
    for r in rows:
        key=tuple((k,v) for k,v in sorted(r.items()) if k!="_access")
        if key not in seen or r["_access"]=="ONGOING": seen[key]=r
    return list(seen.values())
def inwin(r,a,b):
    try: d=datetime.date.fromisoformat(r["Date"])
    except Exception: return False
    return a<=d<=b
def n(r,f="Counts"):
    try: return int(r.get(f) or 0)
    except Exception: return 0
disc=dedup(A["discovery"]["rows"]); dl=dedup(A["downloads"]["rows"])
def funnel(a,b,by=None):
    imp=collections.Counter(); pv=collections.Counter(); getbtn=collections.Counter(); dls=collections.Counter()
    for r in disc:
        if not inwin(r,a,b): continue
        k=r.get(by) if by else "ALL"
        e=r["Event"]
        if e=="Impression": imp[k]+=n(r)
        elif e=="Page view" and r.get("Page Type")=="Product page": pv[k]+=n(r)
        elif e=="Tap" and r.get("Engagement Type")=="Get": getbtn[k]+=n(r)
    for r in dl:
        if not inwin(r,a,b): continue
        if r.get("Download Type")!="First-time download": continue
        k=r.get(by) if by else "ALL"
        dls[k]+=n(r)
    keys=set(imp)|set(pv)|set(getbtn)|set(dls)
    return {k:{"impressions":imp[k],"page_views":pv[k],"get_taps":getbtn[k],"first_time":dls[k]} for k in keys}
def rate(a,b): return f"{100*a/b:.1f}%" if b else "n/a"
def show(v): return (f"imp {v['impressions']:5} → views {v['page_views']:4} ({rate(v['page_views'],v['impressions']):>6}) "
                     f"→ Get taps {v['get_taps']:3} → installs {v['first_time']:3} "
                     f"(install/view {rate(v['first_time'],v['page_views']):>6})")
cur=funnel(w0a,w0b); prev=funnel(w1a,w1b)
print(f"=== FUNNEL this week ({w0a}..{w0b}) ===\n  {show(cur['ALL'])}")
print(f"=== prior week ({w1a}..{w1b}) ===\n  {show(prev['ALL'])}")
print("\n=== by SOURCE TYPE (this week) ===")
for k,v in sorted(funnel(w0a,w0b,'Source Type').items(), key=lambda x:-x[1]['impressions']):
    print(f"  {k:22} {show(v)}")
print("\n=== by SOURCE TYPE (prior week) ===")
for k,v in sorted(funnel(w1a,w1b,'Source Type').items(), key=lambda x:-x[1]['impressions']):
    print(f"  {k:22} {show(v)}")
print("\n=== by TERRITORY (this week, imp>0) ===")
tw=funnel(w0a,w0b,'Territory'); pw=funnel(w1a,w1b,'Territory')
for k,v in sorted(tw.items(), key=lambda x:-x[1]['impressions'])[:14]:
    p=pw.get(k,{"impressions":0,"page_views":0,"first_time":0})
    print(f"  {k:5} {show(v)}   (prior: imp {p['impressions']}, views {p['page_views']}, dl {p['first_time']})")
json.dump({"this_week":{"total":cur["ALL"],"by_source":funnel(w0a,w0b,'Source Type'),"by_territory":tw},
           "prior_week":{"total":prev["ALL"],"by_source":funnel(w1a,w1b,'Source Type'),"by_territory":pw},
           "windows":{"this":[str(w0a),str(w0b)],"prior":[str(w1a),str(w1b)]}}, open("funnel.json","w"), indent=1)
