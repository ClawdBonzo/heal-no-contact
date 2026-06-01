# App Store Submission — What You Need To Do

Everything you can paste, copy, or verify is already in this folder. The checklist below is only the things that physically require your hands, your credentials, or your judgment.

---

## 🔴 Must-do blockers (app won't ship without these)

### 1. Set signing team in Xcode (2 minutes)

Open the project in Xcode:

```bash
open /Users/robgoldstein/Desktop/HealNoContact/HealNoContact.xcodeproj
```

For **both** `HealNoContact` and `HealNoContactWidgetExtension` targets:
1. Click the target in the sidebar
2. Go to **Signing & Capabilities**
3. Set **Team** to your Apple Developer account
4. Verify **Automatically manage signing** is checked
5. Confirm the Bundle ID shows as `com.clawdbonzo.HealNoContact` (main) and `com.clawdbonzo.HealNoContact.widget` (widget)

If the bundle IDs aren't registered on developer.apple.com yet, Xcode will offer to register them automatically — approve that.

### 2. Replace the RevenueCat placeholder key

Open [RevenueCatService.swift:14](../HealNoContact/Services/RevenueCatService.swift:14) and swap the placeholder:

```swift
#else
return "REPLACE_WITH_appl_PRODUCTION_KEY"  // ← paste your appl_xxx key here
#endif
```

Get the key from RevenueCat Dashboard → Apps → [your app] → API Keys → **Public app SDK key** (NOT the secret key). Format is `appl_xxxxxxxxxxxxxxxxxxxx`.

**Safety net already in place**: if you forget, Release builds crash at launch with a clear error. You physically can't ship the placeholder.

### 3. Create the four in-app purchase products in App Store Connect

Go to ASC → Heal → Features → In-App Purchases. Create:

| Product ID (use EXACTLY) | Type | Suggested Price |
|---|---|---|
| `com.healnocontact.premium.weekly` | Auto-Renewable Subscription | $6.99/week |
| `com.healnocontact.premium.monthly` | Auto-Renewable Subscription | $14.99/month |
| `com.healnocontact.premium.yearly` | Auto-Renewable Subscription | $59.99/year |
| `com.healnocontact.premium.lifetime` | Non-Consumable | $99.99 |

All three subscriptions go in one Subscription Group (name it "Heal Premium"). Each needs a display name, description, and review screenshot (for ASC reviewers — a screenshot of the paywall suffices).

Once created in ASC, they automatically appear in RevenueCat within ~15 min. In RevenueCat Dashboard, map them to the `pro` entitlement and add them to an Offering.

### 4. Host the privacy policy

The ASC submission form requires a **public URL** for your privacy policy. Paste the contents of [PRIVACY_POLICY.md](PRIVACY_POLICY.md) anywhere public — options in order of effort:

- **GitHub Pages** (free, 5 min): create a repo, put the markdown in an `index.md`, enable Pages, done. URL becomes `https://yourusername.github.io/heal-privacy/`
- **Notion public page** (free, 2 min): paste into a Notion doc, click Share → publish to web
- **Carrd / simple static host** (free-ish): one-page hosting
- **Your own domain** (if you have one): `https://yourdomain.com/heal-privacy.html`

Whatever you pick, also host a tiny support page. Can be a single paragraph: *"For help with Heal: No Contact Recovery, email rgoldstein45@gmail.com. We respond within 2 business days."* A mailto URL alone is accepted by ASC.

Once hosted:
- Edit the `[YOUR-DOMAIN]` placeholders in [METADATA.md](METADATA.md)
- Fill in the `[DATE TO INSERT]` lines at the top of `PRIVACY_POLICY.md`

### 5. Archive and upload

With signing fixed and the RevenueCat key set:

1. Xcode → Product → Scheme → Edit Scheme → set Run + Archive to `Release`
2. Xcode → Product → Destination → **Any iOS Device (arm64)**
3. Xcode → Product → **Archive**
4. In the Organizer window that opens → **Distribute App** → **App Store Connect** → **Upload**
5. Wait ~15 min for ASC to process the build

---

## 🟡 In App Store Connect (data entry, not engineering)

Everything below is a copy-paste job from [METADATA.md](METADATA.md):

- App name + subtitle
- Description + promotional text
- Keywords
- Primary/secondary categories
- Age rating questionnaire (answers in METADATA.md)
- App Review Information / notes for reviewer
- Screenshots → upload all 8 PNGs from `/screenshots/` folder

Take 30 min, do it all in one sitting.

---

## 📸 Screenshots — included, upload as-is

8 clean screenshots at **1320 × 2868** (iPhone 6.9" / 17 Pro Max), ASC-compliant, status bar set to 9:41/full signal:

| # | File | What it shows |
|---|---|---|
| 1 | `01-welcome.png` | Onboarding hero with brand icon + feature list |
| 2 | `02-commitment.png` | "Make your commitment" — pledge + mantra |
| 3 | `03-home-hero.png` | **HERO** — streak ring + mantra + SOS chip + Check In/Journal |
| 4 | `04-home-quests.png` | Today's Quest + Your Journey strip (Level/Flame/Next) |
| 5 | `05-unsent-letter.png` | Unsent Letter — unique feature |
| 6 | `06-stats-progress.png` | Stats tab with Milestones timeline |
| 7 | `07-stats-insights.png` | Insights with Healing Score + weekly summary |
| 8 | `08-settings.png` | Settings showing premium upgrade prompt + data controls |

**Upload order matters**: use them in this order. Screenshot 3 (`03-home-hero.png`) should be your **featured screenshot** — it's shown in search results and is the single biggest conversion lever.

**Want designer-enhanced versions** (bold headlines, zoom-outs, branded background)? The `aso-appstore-screenshots` skill can generate them, but requires installing the Gemini MCP server first. Run `npm install -g gemini-mcp`, add to `~/.claude/settings.json`, restart Claude Code, then re-run the skill pointing at these same raw screenshots.

---

## ⚪ Optional polish, can ship without

- **Real-device test**: after signing is set, do a Release build to a real phone before archiving. Catches simulator-only bugs.
- **Subscription localization**: ASC lets you localize display names/descriptions per territory. English-only is fine for v1.
- **Promotional artwork**: 1024×1024 app icon is set; optional App Preview video adds conversion but isn't required.
- **GameificationDashboardView.swift**: now orphaned after the tab consolidation — can be deleted in a cleanup commit.
- **`PrivacyInfo.xcprivacy` audit**: I generated one covering the Required Reason APIs SwiftData uses. If you add other SDKs later (Sentry, Firebase, Mixpanel), each needs updating.

---

## Recap — what I did in this session

- Rebuilt Home dashboard from sparse 4-component view to rich unified dashboard (hero, quests, journey strip, badges, quotes)
- Consolidated 6 tabs → 4 (Home / Journal / Stats / Settings), merged Growth into Home and Insights into Stats
- Fixed splash screen double-icon overlap
- Removed the teal/gold background from `Onboarding-4.png` via Vision foreground-mask; tightened commitment screen
- Dropped the awkward "Dear them," default in Unsent Letter; now only shows greeting if user provided an ex name
- Fixed widget extension bundle (`Info.plist` with proper `NSExtension` dict)
- Hardened RevenueCat key pipeline: Debug uses test key, Release crashes at launch if placeholder isn't replaced
- Added `PrivacyInfo.xcprivacy` for Required Reason API declarations
- Drafted full ASC metadata (description, keywords, age rating answers, review notes)
- Drafted privacy policy template
- Captured 8 clean screenshots at ASC 6.9" dimensions

**Time to submission: ~2–3 hours of your focused work** (signing + IAP setup in ASC + copy/paste metadata + host privacy policy + archive upload).
