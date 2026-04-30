# App Store Launch Checklist — Rhythms
**Last Updated:** April 2026 | Cici

---

## ✅ Completed

- [x] **ASO Research** — Competitive analysis, keyword strategy, positioning (`ASO-RESEARCH.md`)
- [x] **App Store Description** — Full description with all feature sections written (in `ASO-RESEARCH.md`)
- [x] **App Name & Subtitle** — "Rhythms: Habit Tracker" / "Build Better Daily Routines"
- [x] **Keywords** — 100-char field optimized: `habit,tracker,routine,daily,streak,goal,reminder,productivity,wellness,schedule,ritual,mindful`

---

## 🔲 Pending — Cam's Action Required

### Privacy Policy
- [ ] Write privacy policy (similar to MelXWord — no data collected, local storage only)
- [ ] Host at GitHub Pages or similar URL

### Screenshots
- [ ] Capture 6.7" screenshots (iPhone 15 Pro Max) — requires real build on device
- [ ] Plan 8-screenshot sequence (TodayView, heatmap, stats, editor, insights, settings, widget, widget lock screen)
- [ ] Add caption overlays

### Build & TestFlight
- [ ] Archive a build in Xcode
- [ ] Upload to App Store Connect via Xcode Organizer
- [ ] Distribute to TestFlight internal testing
- [ ] Fix any TestFlight-found issues

### App Store Connect Setup
- [ ] Create new app record in App Store Connect
  - App Name: `Rhythms: Habit Tracker`
  - Bundle ID: verify matches Xcode project
  - Primary Language: English (U.S.)
- [ ] Set category: **Health & Fitness** (primary), **Productivity** (secondary)
- [ ] Set price: **$2.99** (Tier 3)
- [ ] Enter app description (from `ASO-RESEARCH.md`)
- [ ] Enter subtitle: `Build Better Daily Routines`
- [ ] Enter keywords
- [ ] Upload app icon (1024×1024 PNG, no alpha)
- [ ] Upload screenshots

### Bundle ID Verification
- [ ] Confirm bundle ID in Xcode matches App Store Connect record
- [ ] Verify signing certificates and entitlements (App Intents, UserNotifications)
- [ ] Check widget extension bundle IDs

### App Intents / Siri
- [ ] Verify App Intents work correctly in release build
- [ ] Test Siri shortcuts end-to-end on device
- [ ] Add "Works with Siri" or "App Intents" to privacy notes in submission

### Submission
- [ ] Complete App Privacy questionnaire (answer: no personal data collected)
- [ ] Submit for App Review
- [ ] Monitor review status

---

## 🚀 Launch Day (After Approval)

- [ ] Set release date (manual or automatic)
- [ ] Post to r/HabitTracking or r/habits
- [ ] Post to r/SideProject
- [ ] Twitter/X launch thread
- [ ] Personal network email
- [ ] Post in relevant faith/wellness communities (given the target audience)

---

## Notes

- Age rating: 4+ (no objectionable content)
- Pricing: one-time $2.99 — no subscriptions
- Widget extension requires separate bundle ID but same team certificate
- App Intents need to be listed in the app's privacy manifest
