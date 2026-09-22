# App Store screenshot pipeline

Every locale's set is rebuilt in one run, so all 15 App Store localizations share one
design, one status bar and one build of the app:

```bash
./capture.sh <lang> <simulator-udid> raw_<lang> <AppleLocale>   # e.g. ./capture.sh de <udid> raw_de de_DE
python3 build_sets.py                                           # compose every set from raw_* + headlines.json
python3 upload_sets.py <appStoreVersionId>                      # replace + verify the 6.9" set in every localization
```

* `headlines.json`: per-language headline copy, 2 lines per shot, sentence case.
* `build_sets.py`: maps capture language to headline key and output dir
  (es-MX captures the es-MX UI but shares the Spanish headlines).
* `upload_sets.py`: maps ASC localization to output dir. en-US, en-GB, en-AU and en-CA all use `designed/`.
* `raw_*/` is gitignored. Raws are reproducible (about 7 MB per locale). Only the composed
  `AppStoreConnect/screenshots/designed*/` sets are committed.

## Capture
* Use an iPhone 17 Pro simulator and a DEBUG build.
* `-seedDemo` seeds a 47-day streak. `-demoScreen` picks the screen: home, commitment,
  progress, insights, letter, welcome, settings, paywall (plus `setup` for checking onboarding).
* The harness suppresses badge toasts and unlocks premium views on `insights`, so that shot
  shows the healing score and not the upsell card.
* `capture.sh` pins the status bar to 9:41 with full signal and battery.
* The demo mantra is localized. If a localized shot shows English, suspect a `String`-typed
  label (never reaches the catalog) and run `python3 AppStore/localization_audit.py <DerivedData>`.

## Compose (compose.py)
* Canvas: 1320×2868, gradient #583C96 → #150E22.
* Device inset: x=161, w=998, top=532, corner radius 58.
* Headline: lines at y=222 and y=358.
* The Dynamic Island is stamped onto every raw. simctl includes it only in some captures,
  which is why shipped sets once had the pill on 3 of 8 shots.
* Thai and Arabic headlines are drawn by CoreText (`render_headline.swift`). PIL here has no
  HarfBuzz and no font fallback, so Thai marks stacked wrong and "100%" in Arabic became tofu.

## History
Before 1.5 the store showed three different designs side by side:
* framed phone with shadowed text (de/es/it);
* flat purple with all-caps text that ran onto 3 lines and off the crop (fr/nl/id/th);
* the current gradient style (en/tr/ar/pt-BR).

They also had five different status-bar clocks, badge toasts in frame, and English UI in
some localized sets. This pipeline previously lived in /tmp and was lost twice. Keep it here.
