import sys, json, time, collections; sys.path.insert(0,'.')
import requests
APP=6761851731
TERMS={"us":["no contact","breakup recovery","breakup","heartbreak","get over ex"],
       "gb":["no contact","breakup"],
       "es":["contacto cero","ruptura"],
       "it":["no contact","cuore spezzato"],
       "th":["เลิกกัน","อกหัก"],
       "nl":["no contact","liefdesverdriet"],
       "tr":["ayrılık","no contact"]}
out={}
s=requests.Session()
for c,terms in TERMS.items():
    for t in terms:
        try:
            r=s.get("https://itunes.apple.com/search",params={"term":t,"country":c,"entity":"software","limit":200},timeout=30).json()
            ids=[x["trackId"] for x in r.get("results",[])]
            pos=ids.index(APP)+1 if APP in ids else None
            top=[(x["trackName"][:34],x.get("userRatingCount",0),x.get("currentVersionReleaseDate","")[:10]) for x in r.get("results",[])[:4]]
            out[f"{c}|{t}"]={"rank":pos,"n":len(ids),"top":top}
            print(f"{c:3} {t:20} rank={str(pos):5}/{len(ids):3} | top: {top[:2]}",flush=True)
        except Exception as e: print(c,t,"err",str(e)[:60],flush=True)
        time.sleep(1.2)
json.dump(out,open("competitive.json","w"))
print("DONE")
