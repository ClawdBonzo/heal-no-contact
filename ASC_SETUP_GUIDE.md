# HealNoContact App Store Connect Setup Guide

Complete setup for HealNoContact on App Store Connect with 4 subscription products.

---

## STEP 1: Register Bundle ID in Apple Developer Portal

**URL:** https://developer.apple.com/account/resources/identifiers/list

1. Click **"Identifiers"** in left sidebar
2. Click **"+"** button (top left)
3. Select **"App IDs"** → Click **"Continue"**
4. Select **"App"** → Click **"Continue"**
5. Fill in:
   - **Description:** `HealNoContact`
   - **Bundle ID:** `com.clawdbonzo.HealNoContact` (exact match)
   - **Capabilities:** Check `In-App Purchase` and `Push Notifications`
6. Click **"Register"**
7. Click **"Confirm"**

✅ **Bundle ID registered:** `com.clawdbonzo.HealNoContact`

---

## STEP 2: Create App in App Store Connect

**URL:** https://appstoreconnect.apple.com/apps

1. Click **"My Apps"** (top left)
2. Click **"+"** button → Select **"New App"**
3. Select **"iOS"** → Click **"Create"**
4. Fill in:
   - **Platform:** iOS
   - **Name:** `Heal No Contact` (or `HealNoContact: No Contact Healing`)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** `com.clawdbonzo.HealNoContact` (dropdown)
   - **SKU:** `HealNoContact2026`
   - **User Access:** Leave default
5. Click **"Create"**

✅ **App created in ASC**

---

## STEP 3: Create Subscription Group

**Location:** App Store Connect → HealNoContact → In-App Purchases

1. Navigate to your app in App Store Connect
2. Click **"In-App Purchases"** in left sidebar
3. Click **"Subscription Groups"** (top of page)
4. Click **"Create New"**
5. Fill in:
   - **Reference Name:** `HealNoContact Pro`
6. Click **"Create"**

✅ **Subscription Group created:** `HealNoContact Pro`

---

## STEP 4: Create 4 Subscription Products

**Base URL:** App Store Connect → HealNoContact → In-App Purchases → HealNoContact Pro → Create New

### Product 1: Weekly Subscription

1. Click **"+"** (under HealNoContact Pro group)
2. Select **"Recurring Subscription"** → Click **"Create"**
3. Fill in:
   - **Reference Name:** `Weekly Premium`
   - **Product ID:** `com.healnocontact.premium.weekly` (exact match)
   - **Subscription Duration:** `1 Week`
   - **Free Trial Period:** `3 Days` ← IMPORTANT
   - **Price Tier:** `Tier 1` ($4.99 USD)
   - **Localization (English - U.S.):**
     - Display Name: `Weekly`
     - Description: `Unlimited access for 1 week`
4. Click **"Save"**

✅ **Product 1 created:** `com.healnocontact.premium.weekly` ($4.99/week, 3-day trial)

### Product 2: Monthly Subscription (BEST VALUE)

1. Click **"+"** (under HealNoContact Pro group)
2. Select **"Recurring Subscription"** → Click **"Create"**
3. Fill in:
   - **Reference Name:** `Monthly Premium`
   - **Product ID:** `com.healnocontact.premium.monthly` (exact match)
   - **Subscription Duration:** `1 Month`
   - **Free Trial Period:** `3 Days` ← IMPORTANT
   - **Price Tier:** `Tier 2` ($9.99 USD)
   - **Localization (English - U.S.):**
     - Display Name: `Monthly (BEST VALUE)`
     - Description: `Unlimited access for 1 month`
4. Click **"Save"**

✅ **Product 2 created:** `com.healnocontact.premium.monthly` ($9.99/month, 3-day trial, BEST VALUE)

### Product 3: Yearly Subscription

1. Click **"+"** (under HealNoContact Pro group)
2. Select **"Recurring Subscription"** → Click **"Create"**
3. Fill in:
   - **Reference Name:** `Yearly Premium`
   - **Product ID:** `com.healnocontact.premium.yearly` (exact match)
   - **Subscription Duration:** `1 Year`
   - **Free Trial Period:** `3 Days` ← IMPORTANT
   - **Price Tier:** `Tier 12` ($49.99 USD)
   - **Localization (English - U.S.):**
     - Display Name: `Yearly (Save 58%)`
     - Description: `Unlimited access for 1 year`
4. Click **"Save"**

✅ **Product 3 created:** `com.healnocontact.premium.yearly` ($49.99/year, 3-day trial)

### Product 4: Lifetime (Non-Consumable)

1. Click **"+"** (NOT under subscription group, at top level)
2. Select **"Non-Consumable"** → Click **"Create"**
3. Fill in:
   - **Reference Name:** `Lifetime Premium`
   - **Product ID:** `com.healnocontact.premium.lifetime` (exact match)
   - **Price Tier:** `Tier 20` ($79.99 USD)
   - **Localization (English - U.S.):**
     - Display Name: `Lifetime`
     - Description: `One-time purchase for lifetime access`
4. Click **"Save"**

✅ **Product 4 created:** `com.healnocontact.premium.lifetime` ($79.99 one-time)

---

## STEP 5: Verify All Products in ASC

**Checklist:**
- [ ] Weekly subscription created with ID `com.healnocontact.premium.weekly`
- [ ] Monthly subscription created with ID `com.healnocontact.premium.monthly` (marked BEST VALUE)
- [ ] Yearly subscription created with ID `com.healnocontact.premium.yearly`
- [ ] Lifetime product created with ID `com.healnocontact.premium.lifetime`
- [ ] All subscriptions have **3-day free trial** enabled
- [ ] All products have correct prices (Weekly $4.99, Monthly $9.99, Yearly $49.99, Lifetime $79.99)

---

## STEP 6: Configure RevenueCat Project

**In RevenueCat Dashboard:** https://app.revenuecat.com

1. Create/select **HealNoContact** project
2. Create **Entitlement:** `pro`
3. Create **Products** (attach to App Store):
   - `com.healnocontact.premium.weekly` → Weekly Premium
   - `com.healnocontact.premium.monthly` → Monthly Premium
   - `com.healnocontact.premium.yearly` → Yearly Premium
   - `com.healnocontact.premium.lifetime` → Lifetime Premium
4. Create **Offering:** `default`
5. Add all 4 products to `default` offering
6. Link iOS app (com.clawdbonzo.HealNoContact)

---

## STEP 7: Verify Code Configuration

**File:** `HealNoContact/Services/RevenueCatService.swift`

✅ Already configured with:
```swift
private static let apiKey = "test_AFpuFmRxwiYCSJV0rgzxFqKjZDa"
static let premiumEntitlement = "pro"

static let premiumWeekly = "com.healnocontact.premium.weekly"
static let premiumMonthly = "com.healnocontact.premium.monthly"
static let premiumYearly = "com.healnocontact.premium.yearly"
static let premiumLifetime = "com.healnocontact.premium.lifetime"
```

---

## STEP 8: Add RevenueCat SPM Package (if needed)

In Xcode:

1. Select HealNoContact project
2. **File → Add Package Dependencies**
3. Paste URL: `https://github.com/RevenueCat/purchases-ios-spm`
4. Version: `Exact` → `5.0.0` (or latest)
5. Click **"Add Package"**
6. Select target: **HealNoContact**
7. Click **"Add Package"**

✅ RevenueCat framework linked to target

---

## STEP 9: Verify Build Succeeds

In Xcode:

1. Select **HealNoContact** scheme
2. Press **Cmd+B** to build
3. Wait for build to complete
4. ✅ Build should succeed with no errors

---

## SUMMARY TABLE

| Item | Value | Status |
|------|-------|--------|
| **Bundle ID** | `com.clawdbonzo.HealNoContact` | ✅ Register in Developer Portal |
| **App Name** | Heal No Contact | ✅ Create in ASC |
| **SKU** | HealNoContact2026 | ✅ Set in ASC |
| **Subscription Group** | HealNoContact Pro | ✅ Create in ASC |
| | | |
| **Product 1** | `com.healnocontact.premium.weekly` | ✅ $4.99/week, 3-day trial |
| **Product 2** | `com.healnocontact.premium.monthly` | ✅ $9.99/month, 3-day trial, BEST VALUE |
| **Product 3** | `com.healnocontact.premium.yearly` | ✅ $49.99/year, 3-day trial |
| **Product 4** | `com.healnocontact.premium.lifetime` | ✅ $79.99 one-time |
| | | |
| **RevenueCat API** | test_AFpuFmRxwiYCSJV0rgzxFqKjZDa | ✅ Already in code |
| **Entitlement** | pro | ✅ Create in RevenueCat |
| **SPM Package** | purchases-ios-spm | ✅ Add to Xcode target |

---

## NEXT STEPS

After completing the setup above:

1. ✅ Run `xcodebuild -scheme HealNoContact -configuration Debug` to verify build
2. ✅ Test in Xcode simulator: Open app → Settings → Tap "Upgrade to Premium"
3. ✅ Paywall should display all 4 products
4. ✅ Create git commit documenting ASC configuration

---

## TROUBLESHOOTING

**Build fails after adding RevenueCat SPM?**
- Clean build: Cmd+Shift+K
- Rebuild: Cmd+B

**Products don't appear in app?**
- Verify Product IDs match exactly in both ASC and code
- Check entitlement `pro` is set in both ASC and RevenueCat
- Ensure offering in RevenueCat includes all 4 products

**Paywall shows "Loading..."?**
- Use test API key (already configured)
- Check internet connection
- Verify RevenueCat project linked to bundle ID

