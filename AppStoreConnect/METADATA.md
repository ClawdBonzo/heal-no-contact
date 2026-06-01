# App Store Connect — Metadata Copy

Paste these values into App Store Connect. All character counts are App Store limits.

---

## App Information

**Name** (30 chars max)
```
Heal: No Contact Recovery
```
(25/30)

**Subtitle** (30 chars max)
```
Breakup healing & no-contact
```
(28/30)

**Primary Category**: Health & Fitness
**Secondary Category**: Lifestyle

**Bundle ID**: `com.clawdbonzo.HealNoContact`

**Privacy Policy URL**: `https://gwlabs.app/privacy` (live ✅)

**Support URL**: `https://gwlabs.app/support` (live ✅ — support email: support@gwlabs.app)

**Marketing URL** (optional): `https://gwlabs.app/` (live ✅)

---

## Promotional Text (170 chars max — editable anytime without review)
```
Your no-contact streak, in your pocket. Journal the hard days, feel less alone in the urges, and watch yourself heal — one day at a time.
```
(137/170)

---

## Description (4000 chars max)

```
You set the intention. No contact. And then the urge hits at 2am and you don't know what to do with your hands.

Heal is the app that holds the line for you.

Track every day you didn't reach out. Journal the feelings you can't send. Get support in the moment when the urge wins over your best intentions. And slowly, quietly, watch yourself become someone who doesn't need them anymore.

— TRACK YOUR NO-CONTACT STREAK
See every day you stayed strong. Your streak ring fills up, your flame grows, your level climbs. Little proof, every day, that you're doing something hard and doing it anyway.

— EMERGENCY SUPPORT WHEN THE URGE HITS
Tap one button when you feel yourself about to text, call, or check their page. Get grounded. Remember why. Log the moment. Resisting it counts — and it adds up.

— JOURNAL WITHOUT AN AUDIENCE
Write the letter you'll never send. Log the mood you don't want to explain to anyone. Everything stays on your device, private to you. No cloud, no sharing, no algorithm deciding what to do with your grief.

— GAMIFY YOUR HEALING
Daily quests. XP. Badges for every milestone — from Day 1 to a full year. Streak multipliers that grow with your flame. Because sometimes the only thing that works is turning "don't reach out today" into a game you want to win.

— SEE YOUR OWN PROGRESS
A healing score. Weekly summaries. Mood patterns over time. The days you almost broke — and didn't. Evidence, in your own data, that time is doing what it said it would.

— PRIVATE BY DESIGN
Everything stored locally on your phone. No account to create, no email to give, no data sold. Your grief is yours.

Built for the people who already know no-contact is the right call and just need something in their pocket on the bad nights.

You can do this. Heal is the quiet friend that reminds you — one day at a time.

---
SUBSCRIPTION TERMS

Heal offers the following auto-renewing subscriptions and a one-time purchase to unlock full features:
• Weekly subscription
• Monthly subscription
• Yearly subscription
• Lifetime (one-time purchase)

Subscriptions auto-renew unless turned off at least 24 hours before the end of the current period. You can manage and cancel subscriptions in your App Store account settings after purchase. Any unused portion of a free trial is forfeited when purchasing a subscription.

Privacy Policy: https://gwlabs.app/privacy
Terms of Use: https://gwlabs.app/terms
```

---

## Keywords (100 chars max, comma-separated, no spaces after commas)
```
breakup,no contact,heal,recovery,heartbreak,divorce,ex,journal,streak,healing,therapy,self care
```
(97/100)

**Keyword strategy notes:**
- Avoid repeating words from the title/subtitle (App Store indexes those automatically)
- "Heal" is in the title so not in keywords
- No plurals (Apple indexes singular + plural together)
- Space after comma is not allowed — saves characters

---

## What's New in This Version (4000 chars max)

**For first release (v1.0):**
```
Welcome to Heal.

A private, judgment-free companion for getting through a breakup and staying no-contact — one day, one streak, one badge at a time.
```

---

## Age Rating

Complete the App Store Connect questionnaire. Expected result: **17+**.

**Justification for 17+ rating:**
- Frequent/Intense Mature/Suggestive Themes — **Yes** (heartbreak, grief, emotional distress)
- Infrequent/Mild Medical/Treatment Information — **Yes** (self-care, journaling as therapy)
- All other categories — **No**
- Unrestricted Web Access — **No**
- Gambling — **No**

---

## App Review Information (shown to Apple reviewers, not users)

**Sign-in required?** No (no account; all data is local)

**Demo account:** N/A

**Notes for reviewer:**
```
This app does not require sign-in or an account. All user data is stored locally on the device using SwiftData.

In-app purchases are managed via RevenueCat. Test purchases can be made using an Apple sandbox tester account.

The "SOS / I need help now" button on the Home screen is a core feature — it's an emotional support flow for users who feel the urge to break no-contact. Tapping it opens a grounding exercise and logs the incident. It does NOT dial any phone number or contact any outside service.

The gamification (streaks, XP, levels, badges) is intentional. This app is designed to make the emotional discipline of not contacting an ex feel rewarding through positive reinforcement, not shame.

Expected reviewer flow:
1. Launch app → see splash → complete 4-page onboarding (reason, setup, commitment)
2. Land on Home tab — streak ring, mantra, SOS chip, check-in button
3. Tap Check In → log a mood → see entry in Stats tab
4. Tap Journal tab → create a journal entry
5. Tap Settings tab → view Paywall → verify the four subscription options
```

**Contact info:** Rob Goldstein, rgoldstein45@gmail.com, [your phone]

---

## Pricing and Availability

- **Price**: Free (with in-app purchases)
- **Availability**: All territories (or exclude ones that don't accept IAP if desired)
- **Pre-order**: Your choice

---

## In-App Purchases

You need to create these four products in App Store Connect BEFORE you can wire RevenueCat:

| Product ID | Reference Name | Type | Price |
|---|---|---|---|
| `com.healnocontact.premium.weekly` | Heal Weekly | Auto-Renewable Subscription | $6.99/week |
| `com.healnocontact.premium.monthly` | Heal Monthly | Auto-Renewable Subscription | $14.99/month |
| `com.healnocontact.premium.yearly` | Heal Yearly | Auto-Renewable Subscription | $59.99/year |
| `com.healnocontact.premium.lifetime` | Heal Lifetime | Non-Consumable | $99.99 |

All subscriptions go in the same Subscription Group (e.g., "Heal Premium"). Pick your prices — common patterns for this category: weekly $6.99, monthly $14.99, yearly $59.99, lifetime $99.99.

Each product needs:
- **Localized display name** (shown to users): "Weekly Access", "Monthly Access", etc.
- **Localized description**: short one-liner
- **Review notes**: "Unlocks premium features (advanced insights, extra content, etc.)"

---

## Screenshots Required

Apple accepts **one size that scales for others**. The smart default is iPhone 6.9":

| Display | Dimensions (portrait) | Covers |
|---|---|---|
| **iPhone 6.9"** | 1320 × 2868 px | iPhone 15 Pro Max, 16 Pro Max, 17 Pro Max |
| iPhone 6.5" | 1242 × 2688 px | iPhone 11 Pro Max, XS Max (older) |
| iPhone 5.5" | 1242 × 2208 px | iPhone 8 Plus (rarely needed) |

Upload at least 3, ideally 5–10, screenshots. Ordering matters — first one is shown in search results.

**Recommended order** (captured in `/screenshots/` folder):
1. Home dashboard with streak ring + SOS chip
2. Journal entry view
3. Daily quest + Your Journey strip
4. Stats tab (Progress chart)
5. Paywall

---

## What I'd Set These Benefits To (for future ASO screenshot generation)

When you install the Gemini MCP and run the `aso-appstore-screenshots` skill again, I'd pitch these headlines:

1. **TRACK YOUR NO-CONTACT STREAK** — the core habit, above the fold
2. **HELP WHEN THE URGE HITS** — SOS, the most emotionally resonant button
3. **JOURNAL WITHOUT AN AUDIENCE** — private processing
4. **EARN BADGES AS YOU HEAL** — gamification as motivation
5. **SEE HOW FAR YOU'VE COME** — progress insights

**Brand color**: `#7E57C2` (Heal Purple) — already the app's accent; bold at thumbnail size, suits the emotional/supportive tone, stops the scroll.
