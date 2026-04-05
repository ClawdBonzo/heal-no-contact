# Heal — No-Contact & Breakup Recovery Enforcer

A beautifully designed iOS app that helps people maintain no-contact after a breakup, with streak tracking, journaling, emergency SOS support, mood analytics, and gentle accountability.

**100% private. 100% on-device. No data ever leaves your phone.**

## Features

### Core
- **No-Contact Streak Tracker** — Animated ring showing your progress toward your goal (14–365 days)
- **Daily Check-Ins** — Log your mood, intensity, and whether you stayed strong
- **Emergency SOS Mode** — Full-screen intervention with breathing exercises, coping strategies, and an urge wave timer when you feel like reaching out
- **Streak Reset with Compassion** — Honest self-reporting with encouragement, not punishment

### Journaling
- **Mood-Tagged Entries** — Write journal entries tagged with 7 mood states (Devastated through Grateful)
- **Unsent Letters** — Write everything you want to say without sending it — letters are sealed and saved privately
- **Writing Prompts** — Tap for a random prompt when you don't know where to start
- **Search & Filter** — Find entries by text search or mood filter

### Progress & Insights
- **10 Milestone Badges** — From Day 1 ("First Step") to Day 365 ("One Year Free")
- **Healing Score** — Composite 0–100 score based on streak, mood trend, and consistency
- **Mood Trend Analysis** — See if you're trending up, down, or stable
- **Pattern Detection** — Identifies your hardest time of day and most common mood
- **Weekly Summaries** — Journal entries, check-ins, and SOS sessions at a glance

### Emergency Support
- **Breathing Exercise Bubble** — Visual guided breathing animation
- **Coping Strategy Carousel** — 15 evidence-based strategies served randomly
- **Urge Wave Timer** — Real-time timer showing how long you've resisted
- **Personal Mantra Display** — Your commitment shown when you need it most
- **Streak Reminder** — Shows your current streak to motivate you not to break it

### Personalization
- **Gentle 4-Step Onboarding** — Welcome → Reason → Setup → Commitment pledge
- **Personal Mantra** — Custom text displayed on dashboard and during emergencies
- **Configurable Goal** — Choose from 14, 21, 30, 60, 90, 180, or 365 days
- **Daily Notification Scheduling** — Set your preferred check-in time

### Monetization
- **StoreKit 2 Integration** — Monthly, yearly, and lifetime premium options
- **Premium Features** — Advanced insights, widgets, custom themes, smart reminders, data export

### Widgets
- **Streak Widget** — Small and medium home screen widgets showing your current streak
- **Mantra Widget** — Small widget displaying your personal healing mantra

## Onboarding Flow

1. **Welcome** — App introduction with 4 key feature highlights and "Begin Your Healing" CTA
2. **Why No Contact** — Select from 6 common reasons (stored privately for personalization)
3. **Setup** — Enter ex's name (optional), breakup date, relationship duration, and no-contact goal
4. **Commitment** — Write a personal mantra + agree to a healing pledge

## Tech Stack

- **Swift 6** + **SwiftUI** (iOS 18+)
- **SwiftData** for 100% local/private persistence
- **StoreKit 2** for native subscriptions (no RevenueCat dependency)
- **UserNotifications** for daily check-ins and milestone alerts
- **WidgetKit** for home screen widgets
- **MeshGradient** for animated background effects
- **SF Symbols** throughout (no custom icon assets needed)

## Architecture

- `@Observable` macro for app state management
- `@Model` macro for SwiftData entities
- MVVM-ish with view-level state management
- Service singletons for notifications, haptics, quotes, and StoreKit
- Dark-first UI with custom color theme system

## Project Structure

```
HealNoContact/
├── App/                     # Entry point + app state
├── Models/                  # SwiftData models (6 entities)
├── Views/
│   ├── Onboarding/         # 4-page gentle onboarding flow
│   ├── Dashboard/          # Home screen with streak ring
│   ├── Journal/            # Entry list, editor, unsent letters
│   ├── Emergency/          # SOS mode with breathing + coping
│   ├── Progress/           # Milestones + mood trends
│   ├── Insights/           # Healing score + patterns
│   ├── Settings/           # Profile, notifications, paywall
│   └── Components/         # Shared UI (glass cards, tab bar)
├── Services/               # Notifications, haptics, quotes, StoreKit
├── Extensions/             # Color theme, Date helpers
└── Resources/              # Asset catalog
```

## Build Instructions

1. Open Xcode 16+
2. Create a new iOS App project named "HealNoContact"
   - Interface: SwiftUI
   - Language: Swift
   - Storage: SwiftData
   - Minimum deployment: iOS 18.0
3. Delete the auto-generated files
4. Copy all files from this repo into the project, matching the folder structure
5. Add all `.swift` files to the main target in Build Phases → Compile Sources
6. Add widget files to a new Widget Extension target
7. Build and run on simulator or device

## StoreKit Setup

1. In App Store Connect, create 3 in-app purchase products:
   - `com.healnocontact.premium.monthly` — Auto-renewable, $4.99/month
   - `com.healnocontact.premium.yearly` — Auto-renewable, $29.99/year
   - `com.healnocontact.premium.lifetime` — Non-consumable, $49.99
2. For local testing, create a `StoreKit Configuration` file in Xcode:
   - File → New → StoreKit Configuration File
   - Add the 3 products with matching identifiers
   - Enable in scheme: Edit Scheme → Run → Options → StoreKit Configuration

## Screenshots

> Screenshots placeholder — add your own App Store screenshots here.

| Dashboard | Journal | Emergency SOS | Progress |
|-----------|---------|---------------|----------|
| ![](screenshots/dashboard.png) | ![](screenshots/journal.png) | ![](screenshots/emergency.png) | ![](screenshots/progress.png) |

## Privacy

This app stores **all data exclusively on-device** using SwiftData. No analytics, no telemetry, no server calls (except Apple's StoreKit for purchases). Your journal entries, mood data, and personal information never leave your phone.

## License

All rights reserved.
