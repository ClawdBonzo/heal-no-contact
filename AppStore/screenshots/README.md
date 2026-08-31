# App Store screenshot pipeline

Regenerate a locale's 8-shot set:

```bash
./capture.sh <locale> <simulator-udid>      # raw_<locale>/*.png from the DEBUG demo harness
python3 compose.py raw_xx/01-streak.png out.png "Line one" "Line two"
```

`headlines.json` holds the per-locale headline copy. Finished sets are committed to
`AppStoreConnect/screenshots/designed[_<locale>]/` — that's what gets uploaded to ASC.

## Geometry
Measured off the shipped `designed/01-streak.png` so new locales match exactly:
canvas 1320×2868, gradient #583C96 → #150E22, device inset x=161 w=998 top=532
corner radius 58, headline lines at y=222 and y=358.

Raw captures can be any modern iPhone aspect (they're scaled to a fixed 998px
device width), so a 6.3" simulator is fine — the canvas is always 6.9".

## Notes
* Capture uses the app's `-seedDemo` DEBUG harness so shots show a populated
  47-day streak instead of an empty first run. Allow ~7s settle or the badge-unlock
  toast lands in the frame.
* The demo mantra is localized — if a localized screenshot shows English copy,
  suspect a hardcoded literal in the demo harness, not the catalog.
* This pipeline previously lived in /tmp and was lost twice. Keep it here.
