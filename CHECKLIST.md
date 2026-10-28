# Tuckii Clone — Feature Parity Checklist

Legend: ✅ implemented (code + CI build) · 🧪 unit-tested · ⛔ out of scope by decision · ⚠️ partial

## Onboarding
- ✅ 7-page carousel: intro, problem, intro to Tuckii (`OnboardingView`)
- ✅ Interactive save demo: mock reel → mock share sheet → mock Save-to-Tuckii sheet → "That's it" step
- ✅ Focus Mode demo deck with tag chips and progress
- ✅ Reminders pitch with phone mock + system notification permission request
- ✅ Paywall step (simulated purchase), skip/back, progress pills

## Saving
- ✅ Quick save bar with URL validation dialog ("No URL")
- ✅ Clipboard paste button
- ✅ Metadata fetch on save (title/description/OG image/favicon/site name) — `MetadataScraper` 🧪
- ✅ SAVING… badge until metadata resolves; graceful failure state; Refresh action
- ⛔ iOS share extension (decision: out of scope); How To text adapted to quick save
- ⚠️ Image saves: quota model + import paths exist; no share-sheet image entry (consequence of scope decision)

## Collections
- ✅ Implicit Unsorted (system, excluded from free limit) 🧪
- ✅ Create sheet: name 0/40, 16 colors, 24 icons 🧪 limit
- ✅ Edit collection (name/color/icon) 🧪
- ✅ Delete collection (saves move to Unsorted) 🧪
- ✅ Free limit 3 collections / Pro unlimited 🧪
- ✅ Subcollections (Pro): create + chips + navigation 🧪 gate
- ✅ Pin/save grouping, NEW ribbons, counts
- ✅ Collection focus (deck), add link dialog, sort saves (remembered per collection) 🧪

## Saves / link details
- ✅ Full-bleed hero, source row, inline title edit, collection chip + date
- ✅ Open link (domain display, external browser)
- ✅ Share (system share), Move (sheet), Refresh, Delete (confirm) 🧪 move
- ✅ Pin toggle 🧪
- ✅ Notes editor ("Tap to add notes…") 🧪 store
- ✅ Tags: crown-gated Add → Pro paywall; tag editor sheet; chips 🧪 gate/dedupe
- ✅ Bulk select: All toggle, Share (ShareLink), Move, Delete 🧪 delete/move

## Focus Mode
- ✅ New-saves scope + per-collection scope
- ✅ Progress bars, counter, deck stack with drag/swipe, arrows, Open link
- ✅ Seen marking; home review banner entry
- ⚠️ Deck visuals are a simple 3D-style stack (not the full stage choreography)

## Search
- ✅ Live search across title/description/URL 🧪
- ✅ Library stats card (Collections/Saves/Pinned/Tags)
- ✅ Recently saved grid with collection chips, tag chips
- ✅ Clear/Cancel, empty prompt

## Settings
- ✅ Free plan card with usage meters (links 3/4 etc.) and midnight countdown
- ✅ Haptics toggle (used on save + pin), Dark Mode (full dynamic palette), Reminders
- ✅ Cloud Sync row (Pro gate → explains out-of-scope after Pro)
- ✅ Backup & Restore: export JSON (Pro), restore JSON (Pro), import CSV/HTML/JSON 🧪
- ✅ How To guide, Feedback mailto, Privacy/Terms placeholders, Delete All Data 🧪
- ✅ Version footer

## Monetization
- ✅ GO PRO modal with exact comparison table and per-feature copy
- ✅ Paywall screen (Monthly ₹199 / Yearly ₹1,199; 3-day trial copy; Start with Free)
- ✅ Pro simulation unlocks: unlimited saves/collections, tags, subcollections, share collection, backup
- ⚠️ No real StoreKit billing (sideload constraints); Restore Purchases is decorative
- ⚠️ Lifetime plan card not shown (Android-observed paywall lacks it)

## Data & logic
- ✅ Local-first JSON store with atomic writes 🧪 persistence
- ✅ Daily quotas 4 links / 10 images, reset at local midnight 🧪
- ✅ Sorting model, per-collection memory, search, stats 🧪
- ✅ Import parsers (CSV/HTML/JSON) with dedupe + folder mapping 🧪
- ✅ Export backup format with tags/notes/pins 🧪 round-trip

## Platform / delivery
- ✅ SwiftPM package (xtool-ready) + XcodeGen project + `xtool.yml`
- ✅ GitHub Actions: unit tests, iOS Simulator build, 9 screenshots (incl. dark mode)
- ⛔ Share extension, iCloud/CloudKit sync, iPad sidebar layout, widgets, lifetime IAP
- ⚠️ On-device install via xtool remains a manual user step (iPhone testing opted out)

Verified by CI run #20 (commit f853dea): tests, iOS build, install, and 9 simulator screenshots (home, home-dark, onboarding, collection, details, search, settings, focus, paywall) all green; screenshots visually reviewed against the reference captures.

Evidence locations: `Sources/TuckiiCore`, `Sources/TuckiiUI`, `Tests/TuckiiCoreTests`,
`.github/workflows/simulator.yml`, screenshots artifact `simulator-screenshots`.
Original behavior reference: `.research/shots` (91 captures from the real Android 1.6.0 app).
