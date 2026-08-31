# Weekly health checkup — Heal (ASC app 6761851731)

Run: `python3 pull_sales.py && python3 pull_analytics.py && python3 analyze_funnel.py && python3 pull_competitive.py && python3 write_snapshot.py`

Snapshots land in `weekly/YYYY-MM-DD.json` with a `coverage_through` date.

## Data-integrity rules (learned the hard way)
1. **Never hardcode a date.** Every window comes from `today()` in `asc.py`. A frozen
   window and "no change this week" look identical in the output.
2. **Resolve report names by prefix.** Apple renamed `App Downloads` →
   `App Downloads Standard` / `Detailed`. Exact-match filters silently match nothing.
3. **Event names are case-sensitive and not what you'd guess.** Apple emits
   `Page view` (lowercase v), not `Page View`. This bug made tap-through read 0%.
4. **Deduplicate `ONE_TIME_SNAPSHOT` vs `ONGOING`** analytics rows — they overlap
   and double-count.
5. **Never mix sources in one number.** ASC *Sales* reports are authoritative for
   downloads and revenue; ASC *Analytics* download counts are Apple-bucketed and
   will disagree. RevenueCat counts SDK customers (installs that opened the app),
   which is a third, smaller population.
6. **A free app shows $0 proceeds in the Sales report.** Subscription revenue only
   appears in `SUBSCRIPTION` / `SUBSCRIPTION_EVENT` reports.
7. **Zero rows ≠ broken.** Helpers return a status string so the report can say
   which it was.

## Storage warning
This tooling previously lived in `/tmp` and was wiped between runs. Keep it in the repo.
