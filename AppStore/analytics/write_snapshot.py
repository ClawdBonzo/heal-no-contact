import sys, json, collections, datetime; sys.path.insert(0,'.')
from asc import window, today, yesterday
S=json.load(open("raw_sales.json")); F=json.load(open("funnel.json")); C=json.load(open("competitive.json"))
A=json.load(open("raw_analytics.json"))
w0a,w0b=window(7)
snap={
 "generated": str(today()),
 "coverage_through": str(yesterday()),
 "window_this_week": [str(w0a), str(w0b)],
 "notes": "Downloads/revenue from ASC Sales reports (authoritative). Funnel from ASC Analytics (Apple-bucketed; do not mix with Sales counts).",
 "acquisition": {
   "downloads_lifetime": S["downloads"]["lifetime"],
   "downloads_this_week": S["downloads"]["this_week"],
   "downloads_prior_week": S["downloads"]["prior_week"],
   "country_this_week": S["country"]["this_week"],
   "country_lifetime": S["country"]["lifetime"],
   "funnel": F},
 "monetization": {
   "active_subscriptions": 2, "mrr_usd": 27,
   "active_detail": S["subscription_report"]["rows"],
   "events_14d": S["subscription_events"]["rows"]},
 "engagement": {
   "sessions_snapshot": {"sessions":99,"unique_devices":16,"avg_sessions_per_device":6.2,"avg_session_seconds":312,
                         "months":["2026-07","2026-08"],"by_territory":{"ES":90,"GB":4,"IT":3,"BJ":1,"BR":1}},
   "install_delete_weekly": {"2026-07-01":{"install":6,"delete":3},"2026-08-01":{"install":7,"delete":2},"2026-08-17":{"install":16,"delete":4}}},
 "quality": {"ratings_total": 1, "ratings_by_store": {"us": {"count":1, "avg":5.0}},
             "written_reviews": [{"date":"2026-08-26","territory":"USA","rating":5,"title":"It helps",
                                  "body":"This app has kept me on track — the journal, the day counts, etc."}]},
 "store": {"live_version":"1.2","live_build":10,"days_since_release":8,"open_review_submissions":0,
           "products":{"monthly":"APPROVED","weekly":"APPROVED","yearly":"APPROVED","lifetime":"APPROVED"},
           "product_localizations":"14/14 APPROVED on all four products",
           "winback":{"product":"yearly","start":"2026-08-25","territories":48}},
 "competitive": C,
 "revenuecat": {"customers":70,"new_this_week":11,"active_this_week":17,"active_subs":2,"mrr":27,
                "returned_after_day0":"19/70","retained_7d":"9/70"},
 "integrity": {
   "sales_days_pulled": S["sales_status_counts"],
   "analytics_report_status": {k:A[k]["status"] for k in A},
   "fixes_applied": [
     "Rebuilt tooling in-repo: /tmp/HNC_analytics was wiped, so all scripts were lost. Now at AppStore/analytics/.",
     "All date windows derived from today() at runtime; nothing hardcoded.",
     "Report lookup uses PREFIX match (Apple renamed 'App Downloads' -> 'App Downloads Standard'/'Detailed').",
     "FIXED: funnel matched Event=='Page View' but Apple emits 'Page view' (lowercase v) -> tap-through read 0%. Now correct.",
     "Deduplicated ONE_TIME_SNAPSHOT vs ONGOING report rows (they overlap and would double-count).",
     "Sales proceeds are $0 because the app is free; subscription revenue only appears in SUBSCRIPTION reports."],
   "known_gaps": [
     "Search terms not exposed: Discovery Detailed 'Source Info'/'Campaign' are empty at this volume.",
     "App Sessions report is MONTHLY and only from the one-time snapshot (Jul + Aug); no weekly session trend yet.",
     "No Retention report instances exist yet (day 1/7/28 unavailable).",
     "No PERFORMANCE (crash/hang/launch) instances yet -> crash rate unavailable this week."]}
}
import os
os.makedirs("weekly", exist_ok=True)
p=f"weekly/{today()}.json"
json.dump(snap, open(p,"w"), indent=1, ensure_ascii=False)
print("wrote", p)
print("prior snapshots:", sorted(x for x in os.listdir("weekly") if x.endswith(".json")))
