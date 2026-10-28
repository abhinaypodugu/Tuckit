# Tuckii — Exact Clone Plan

Status: **implementing** — SwiftUI app builds and is screenshot-verified on the iOS
Simulator via GitHub Actions. See §11 for build status and deviations.

Status: research complete (live app exploration on Android v1.6.0, 2026-10-28).
Evidence: `.research/shots/*.png` (91 screenshots, every screen/state below), `.research/ui/*.xml`.

---

## 0. Decisions (resolved)

- **Stack:** SwiftUI + SwiftPM. End target = iPhone (via xtool), but the phone will **not**
  be used for testing.
- **Out of scope:** iOS share extension (appex), iCloud/CloudKit sync.
  Quick save = in-app paste bar; optional `tuckii://save?url=` URL scheme so a Shortcut
  can act as a share substitute.
- **Testing:** there is **no iOS emulator on Windows**. Apple's Simulator is macOS-only.
  We verify on the real iOS Simulator via a **GitHub Actions macOS runner**
  (`xcodebuild` + `xcrun simctl` → launch, drive, screenshot artifacts).
  Alternatives if desired: rented cloud Mac (MacinCloud/MacStadium), device clouds
  (BrowserStack App Live / Corellium).
- Reference platform for behavior remains the observed Android v1.6.0 build (§2–§3),
  with iOS-only features (iPad sidebar, iCloud) explicitly skipped.

---

## 1. What we are cloning (facts)

- **App:** Tuckii – Save Links & Bookmark ("Tuckii — save smarter, every day.")
- **Developer:** myCku / Cuong Tran Van · site: tuckii.app
- **IDs:** Play `com.myCku.tuckii` · App Store `6776568114`
- **Versions seen:** Android 1.6.0 (explored live) · iOS 1.6.0 (App Store listing)
- **Pitch:** private, local-first bookmark / read-it-later manager. No account, no ads.
  Save from any app via the system share sheet, organize into collections, review in
  Focus Mode, search instantly. Pro unlocks tags, subcollections, sharing, backup, sync.
- **Tagline on home:** "Save now. Find anytime."
- **Monetization:**
  - Android (INR, observed in onboarding paywall): Monthly ₹199.00/mo with **3-day free trial**;
    Yearly ₹1,199.00/yr (`₹99.91/mo`, "SAVE 50%"). "Cancel anytime", "Restore Purchases", Terms, Privacy.
  - iOS store: $4.99/mo, $29.99/yr, $49.99 lifetime (lifetime card unconfirmed on Android).
- **Free limits (from in-app plan table & settings usage card):**
  - Saves: **4 links/day** (resets at local midnight; live countdown shown)
  - Images saved: **10/day**
  - Collections: **3** (Unsorted not counted)
  - Focus Mode + Reminders: free
  - Pro: unlimited saves/collections, Share collections, Tags & filters, Export & backup, Subfolders

---

## 2. Screen & feature inventory (verified live)

### 2.1 Onboarding (8 steps, skippable, back button, pill-dot progress)
1. "You saved it. Then lost it." — scattered bookmark illustration — CTA "That's me"
2. "Saved isn't the same as used." — CTA "There's a better way"
3. "Meet Tuckii." — mascot (folded bookmark with paperclip) — CTA "Show me how"
4. **Interactive demo, part 1**: mock reels UI (@tuckii.demo, "Quick dinner recipe",
   "Try it · save this reel to Tuckii", hint "Tap Share →"). Tapping the mock share
   button slides up a **mock share sheet** ("Share with", Messages/Notes/Tuckii/More).
5. **Demo, part 2**: tapping Tuckii → mock "Save to Tuckii" bottom sheet:
   URL, "Pin this link" toggle, collection list (Unsorted, Recipes 'pick this', Home ideas, Travel),
   folder-settings icon, CTA "Save to '<collection>'".
6. **Demo, part 3**: saved-state link details preview + sheet "That's it. It's in Recipes —
   Title, preview and source — filled in for you." + CTA "Now use it →".
7. **Demo, part 4**: Focus Mode tutorial deck: header "NEW SAVES 01/03", 3D card stack,
   card = source, image, collection chip, title, description, tag chips; footer copy +
   "Swipe left or right to browse"; X to close; after last card "Swipe once more to finish".
8. **Reminders pitch**: "Never forget what you save!" phone mock with notification preview
   ("Don't forget your saves — Swipe through your unseen saves now."),
   CTA "Turn on reminders" / "Maybe later" → app's own notification permission primer
   ("Allow Tuckii to send you notifications?" Allow / Don't allow) → system prompt.
9. **Paywall**: "YOUR TUCKII IS READY" · "Your saves deserve a system." (highlight on "a system")
   Pro plan card(s) with badge chips ("3-DAY FREE TRIAL", "SAVE 50%"), radio select,
   price + per-month breakdown, "Cancel anytime", primary CTA "Start your 3-day free trial",
   caption with price-after-trial, secondary "Start with Free", links Restore Purchases | Terms | Privacy.
Notes: home is NOT shown during onboarding; completing "Start with Free" lands on Home (empty state).

### 2.2 Home
- Top bar: **gear (Settings)** left; right: **folder-gear (Add new collection)** + **search**.
- H1: "Save now. Find anytime."
- **Quick save bar**: "# Paste link to quick sav..." input with clipboard icon + yellow "+" button.
  - Empty + tap "+" → custom dialog: ⚠ "No URL" / "Please enter a link to save" / OK.
  - Valid URL + "+" → saves immediately to **Unsorted** and navigates into Unsorted.
- **Review banner** (when unseen saves exist): green card, bell icon, "1 new save waiting /
  Review now >" → opens Focus Mode scoped to new saves.
- "My Collections" header + sort dropdown ("Oldest ⌄").
  - Sort options: **Oldest first / Newest first / Name A–Z / Recently saved** (remembered).
- Collection grid (2 columns): card with colored folder tab, item count ("1 item"),
  NEW ribbon (unseen), icon + name. Empty state: folder illustration, "No Collections Yet",
  "Start organizing your saves by creating your first collection." + "Create now".

### 2.3 Add / manage collection (bottom sheet "Add new collection")
- NAME field, 0/40 counter, placeholder "e.g. Travel, Design Inspiration."
- COLOR: 16 swatches (yellow-orange default, pink, purple, blue, teal, green, lime, orange,
  cream, gray, slate, mauve, brown, black, coral, indigo).
- ICON: 24 options (folder, star, heart, book, music note, camera, flag, moon, sun, cloud,
  pin, calendar, globe, gift, leaf, briefcase, cart, plane, car, coffee, film, headphones, palette, "…").
- CTA "Create collection" disabled until name entered. Close X.
- (Edit existing collection UI not captured — likely same sheet; verify.)

### 2.4 Collection screen
- Header: back, collection name, subline "1 item · 0 subcollections",
  **Focus Mode button** (stack-of-cards icon), **overflow (⋮)**.
- Sections: **PINNED (n)** then **SAVES (n)**; card grid; each card: image area
  (OG image or letter placeholder with site-colored bg), NEW ribbon (if unseen),
  pin badge, title (2 lines), favicon + source name. Tapping card → Link details.
- Overflow menu:
  - **+ Add Link** (user collections; Unsorted's menu starts at Select Links)
  - **Select Links**
  - **Create Sub-collection** 👑 (Pro; paywall copy: "Subcollections is a Pro feature.")
  - **Share Collection** (Pro)
  - **Sort saves → Newest/…** (sheet: "Sort saves — Remembered for '<collection>'":
    Newest first ✓ / Oldest first / Title A–Z / Website A–Z)
- **Select mode**: top bar "N selec… | All | Share | Move | Delete | Cancel";
  actions disabled until ≥1 selected; selected card = check overlay + yellow border; Delete pink.

### 2.5 Link details
- Full-bleed hero (OG image or letter placeholder), back + **pin toggle** overlaid,
  white sheet: favicon + source name, title + inline edit (field + Cancel/Save),
  collection chip + saved date ("28 Oct 2026, 10:43 PM"),
  **Open link** big yellow button (domain + ↗),
  action row: **Share · Move · Refresh · Delete** (Delete red; confirm dialog
  "Delete link / Permanently delete this link?" Cancel/Delete),
  **TAGS** section: "+ Add" 👑 (Pro) → "Tags is a Pro feature." paywall,
  **NOTES**: "Tap to add notes..." → inline editor with Cancel/Update.
- Move → bottom sheet "Move to Collection" (same collection list + create-collection
  button; disabled CTA until selection; empty copy "No other collections available.")
- Refresh → re-scrape metadata.

### 2.6 Focus Mode
- Dark stage screen. Header "NEW SAVES 01/03" (or collection name scoped), progress bars,
  X close. 3D stacked cards: source row (favicon + name), image, collection chip, title,
  description, hanging-tag chips for tags.
- Footer: ← prev (disabled at first), **Open link ↗** center, → next.
  Swipe left/right navigates. Viewing marks saves **seen** (NEW clears).
- Entry points: review banner (new saves scope), collection Focus button (collection scope).

### 2.7 Search (top-right magnifier)
- Field "Find collections or save..." + Clear (when text) + Cancel.
- Empty query: **YOUR LIBRARY** stat card — Collections / Saves / Pinned / Tags counts
  (colored icon per stat), then "RECENTLY SAVED" cards, then "Type something to search...".
- Query: live filter, section "SAVES (n)" with matching cards (title/description/url).

### 2.8 Settings
- **YOUR PLAN** card: FREE PLAN badge, "Tuckii Free — Save smarter, every day.",
  mascot art; **FREE PLAN USAGE** with "Links reset daily" and pill "Resets in HH:MM:SS",
  progress rows: Links today 2/4, Images saved 0/10, Collections 1/3;
  CTA "Level up to Pro →".
- **PREFERENCES**: Haptic Feedback (on), Dark Mode (off), New Save Reminders (off)
  → custom notification primer before system prompt.
- **DATA & STORAGE**: Cloud Sync → ("Sync your library across Android devices";
  screen: "SYNC — Sync Now 👑"; "GOOGLE DRIVE DATA — Delete Google Drive Data" red),
  Backup & Restore →.
- **SUPPORT**: How To → (guide list; "SHARING — Share links to Tuckii" opens a sheet with
  4 numbered steps and a mock share-sheet illustration, Done), Send Feedback ↗
  (mailto prefilled "Tuckii Feedback" to support@tuckii.app with app version, iOS version: n/a,
  User ID), Privacy Policy ↗, Terms of Service ↗.
- **ACCOUNT**: Delete All Data (red; "Permanently erase all saves, collections, and tags on this device").
- Footer: "Version 1.6.0".

### 2.9 Backup & Restore
- TUCKII BACKUPS: **Export Backup 👑** ("file you can save anywhere"),
  **Restore from Backup 👑** (".zip or .json").
- IMPORT FROM OTHER APPS: **Import Bookmarks** (free; "From CSV, HTML, or JSON exports")
  → system file picker (SAF) → (import preview/confirm — not captured; verify).

### 2.10 Save via system share (real flow)
- Share text/plain link → app's "Save to Tuckii" bottom sheet over the current screen:
  URL, "Pin this link" toggle (fills yellow + pin icon when on), collection selector
  (Unsorted default ✓), folder-settings (create collection), CTA "Save to '<collection>'".
  Saving closes the app back to the previous app/launcher.
- Share image/png → app processes the image as a save (Images quota 10/day).
  Failure path verified: dialog "Couldn't load image — The shared image is unavailable."

### 2.11 Pro paywall modal (in-app, used for all Pro actions)
- Mascot, "☆ GO PRO ☆", dynamic copy "<Feature> is a Pro feature. Here's what you get with Pro:"
- Full comparison table:
  Saves 4 links/day → Unlimited | Collections 3 → Unlimited | Focus Mode ✓✓ |
  Reminders ✓✓ | Share collections —✓ | Tags & filters —✓ | Export & backup —✓ | Subfolders —✓
- Buttons: "Maybe later" / "Show me →". (Show me → full paywall screen; capture pending.)

### 2.12 Global UI language
- Cream/off-white background, near-black ink, thick 2–3px black borders, hard offset shadows,
  chunky rounded cards (16–20 radius), bold display headings with highlighter-yellow
  underlines, yellow CTA buttons, pill status chips, playful sticker/mascot art.
- Full dark theme (near-black #111, charcoal cards #2A2B31, yellow retains, green banner).
- Custom dialogs (rounded, bordered) rather than system Material dialogs.
- Haptic feedback on actions (toggleable).

---

## 3. Behavior/logic rules to replicate

1. **Local-first**: everything works offline; DB on device; no account.
2. **Implicit "Unsorted"** collection: always exists, cannot be deleted, excluded from the
   3-collection free limit; quick-add targets it.
3. **Metadata scrape on save**: OG/Twitter tags → title, description, image, favicon,
   source name (site title); fallback: domain + first-letter placeholder with hashed
   background color; card shows "SAVING..." until resolved; `Refresh` re-runs it.
4. **Seen/NEW**: unseen saves flagged (NEW ribbon on cards + collection NEW badge +
   home review banner + Focus Mode "NEW SAVES"). Viewing details/Focus card clears it.
5. **Daily quotas (free)**: links 4/day, images 10/day; counter resets local midnight
   (countdown "Resets in HH:MM:SS"); progress bars in Settings; hitting limit → Pro upsell.
6. **Pinning**: per-save boolean; pinned group rendered first in collection and Focus ordering;
   pin visible in search cards; Pinned count in stats.
7. **Sorting**: collections global (4 options, remembered); saves per collection
   (4 options, remembered individually). Default newest.
8. **Subcollections**: `parentId` tree; header shows "n subcollections"; Pro-gated creation.
9. **Tags**: many-to-many; hanging-tag chip visual; Pro-gated add/filter; tag count in stats.
10. **Notes/title**: inline editors with explicit Cancel/[Update|Save]; autosized notes box.
11. **Delete flows**: single confirm dialog; bulk delete via select mode.
12. **Search**: substring search across title/description/url; instant; recent saves when empty.
13. **Theme switch**: instant app-wide recreate; dark palette in §2.12.
14. **Share sheet contract**: ACTION_SEND `text/plain` (URL) and `image/*` (stream);
    opens as in-app overlay; on save → finish and return to caller.
15. **Feedback mailto** includes version + User ID (sync identity).
16. **Paywall triggers**: tags, subcollections, share collection, export/restore, second
    collection beyond 3, saves beyond daily limit, images beyond 10/day, cloud sync.

---

## 4. Data model (SQLite via GRDB on iOS / Room on Android)

```
collections(id PK, name, colorHex, iconKey, parentId FK NULL, sortOrderCollections,
            sortOrderSaves, createdAt, updatedAt)
saves(id PK, url NULL, kind [link|image], title, description NULL, sourceName,
      domain, imagePath NULL, thumbnailPath NULL, faviconPath NULL,
      collectionId FK, isPinned, isSeen, seenAt NULL, notes NULL,
      createdAt, updatedAt, metadataState [pending|ok|failed])
tags(id PK, name UNIQUE)
save_tags(saveId, tagId)
usage_counters(dateKey PK, linksSaved, imagesSaved)
app_settings(key PK, value)        // theme, haptics, remindersRequested, proSimulated
```

Collections: Unsorted = special row (`isSystem=1`, hidden from limit count).
Media: images/thumbnails/favicons stored under Application Support (iOS) / filesDir (Android)
with LRU cleanup; DB stores relative paths.
Import: CSV/HTML(Netscape bookmarks)/JSON parsers → dedupe by URL → preview → import
into Unsorted or mapped folders; export: zip (db + images) or flat JSON.

---

## 5. Architecture — Stack A: SwiftUI + SwiftPM + xtool (per your choice)

### 5.1 Project layout (Swift package)
```
TuckiiClone/
  Package.swift                 // executable app target + library targets + extension target
  xtool.yml                     // bundle id, app name, min iOS, entitlements, icon
  Sources/
    TuckiiApp/                  // @main App, navigation, design system
    TuckiiCore/                 // models, DB (GRDB), scraper, usage limits, pro gating
    TuckiiUI/                   // screens (SwiftUI views + components)
    TuckiiShare/                // share extension (if xtool supports appex — see 5.4)
  Resources/                    // fonts, illustration assets (redrawn originals)
```
Deps: **GRDB.swift** (DB), **Nuke** or Kingfisher (image cache), **SwiftSoup** (OG scraping),
no analytics SDKs (privacy parity).

### 5.2 Key components
- `RootView` → Home / Search (sheet) / Settings (push) / Collection (push) / Details (sheet/fullscreen) / FocusMode (fullScreenCover).
- `SaveSheet` — used by share handler + Move + quick-add: URL header, pin toggle,
  collection rows, create-collection button, Save CTA.
- `MetadataScraper` — URLSession fetch → parse OG/twitter meta + favicon + <title> of site;
  size-capped HTML download; offline → failed state + placeholder.
- `ImageStore` — downloaded OG images; `LetterPlaceholder` hashed color from domain.
- `UsageTracker` — daily counters keyed by local date; midnight rollover via
  calendar notification + on-foreground check.
- `ProGate` — one API: `require(.tags/.subCollections/.shareCollection/.export/.sync/.extraCollection/.dailyLinks/.dailyImages)` → paywall sheet with per-feature copy.
- `FocusDeck` — 3D stacked cards (scale/offset/rotation + drag gesture, spring snap),
  progress bars, seen marking.
- `Theme` — design tokens: colors, 2.5px strokes, radii, offset shadow, heavy rounded font stack.
- `Reminders` — UNUserNotificationCenter local notifications (daily "unseen saves" nudge),
  custom primer dialog before system prompt.
- `ImportExport` — fileImporter for CSV/HTML/JSON; zip export via ZIPFoundation (add dep).

### 5.3 Sideload reality (xtool on Windows)
- Install Swift for Windows toolchain + `xtool` (SwiftPM package) — `swift build -c release`.
- Needs Apple Devices/iTunes drivers, USB pairing, an Apple ID for signing:
  free account = 7-day provisioning (re-sign weekly), paid dev account = 1 year.
- `xtool.yml` declares bundle id, entitlements, icons; build → `.ipa` → install to iPhone via xtool.
- **StoreKit**: real IAP requires App Store Connect + sandbox testers; for sideloaded builds
  implement `ProGate` with a local "simulate Pro" flag + identical paywall UI
  (and keep StoreKit 2 code paths behind a build flag for later TestFlight).
- **Sync**: none (out of scope). Export/import covers device-to-device moves.

### 5.3b Test loop without a Mac or iPhone (iOS Simulator in CI)
- **No Windows iOS emulator exists.** We run the official Simulator on a GitHub Actions
  macOS runner: `xcodebuild -scheme Tuckii -destination 'platform=iOS Simulator,name=iPhone 16'`,
  then `xcrun simctl boot`, `simctl install/launch`, `simctl io booted screenshot`
  (plus optional XCUITest tap-driving). Screenshots are uploaded as workflow artifacts
  so each iteration produces visual evidence — same role as Android's `adb screencap`.
- Repo needed: public repo = free minutes; private = charged. Alternative paid paths:
  MacinCloud/MacStadium (live macOS desktop), BrowserStack App Live / Corellium (virtual
  iPhones). xtool stays for eventual on-device install only.

### 5.4 Out of scope: share extension & iCloud sync
- No `appex`/Share Extension target. Save entry points: home quick-add bar + "Add Link"
  in collection overflow. Optional lightweight substitute: register URL scheme
  `tuckii://save?url=<link>` so an iOS Shortcut can add a share-sheet action that
  opens Tuckii's SaveSheet prefilled (no extension entitlement needed).
- No CloudKit. The Settings → "Data & Storage" section keeps Backup/Restore + Import
  but sync row is replaced with an "Export/Import across devices" explainer (or hidden).
- `project.yml` (XcodeGen) provides an Xcode build for the Simulator/CI; `xtool.yml`
  remains for on-device builds. Both compile the same SwiftPM sources.

### 5.5 Build order (also valid for Option B/C)
1. Design system + navigation shell (Home/Search/Settings skeletons).
2. DB + models + UsageTracker + ProGate (unit-tested).
3. Collection create/manage + collection screen (pinned/saves, sort memory).
4. Save pipeline: quick-add, SaveSheet, metadata scraper, placeholders, Refresh.
5. Link details: inline title, notes, move, delete confirm, pin.
6. Search + library stats.
7. Focus Mode deck + seen tracking + review banner + NEW badges.
8. Settings incl. usage card, reminders, dark mode, how-to, feedback, delete-all.
9. Import/export (CSV/HTML/JSON, zip/JSON backup) + Pro gating.
10. Paywall flows (onboarding paywall + in-context GO PRO modal with exact copy/table).
11. Onboarding 8-step carousel incl. interactive share demo (mocked UI is self-contained).
12. Optional: URL-scheme save entry (`tuckii://save`) for a Shortcut; no share extension.
13. Polish: haptics, transitions, dark theme audit, empty/error states, exact copy & type.
14. Device QA vs evidence screenshots (.research/shots) side-by-side.

### 5.6 If we switch to Android (Option B) — parity notes
- Share: `<intent-filter>` SEND text/plain + image/* → single activity overlay identical to
  the observed SaveSheet; `finish()` after save (app returns to caller).
- Import: SAF `ACTION_OPEN_DOCUMENT` with mime filters csv/html/json.
- Sync: Google Drive `appDataFolder` (matches original's "Delete Google Drive Data").
- Reminders: WorkManager + exact-alarm daily nudge; permission primer identical.
- Billing: Play Billing (₹199/₹1,199, 3-day trial); free-build fallback simulation.

---

## 6. Copy & asset inventory (rebuild, don't copy)

- All UI copy in §2 (transcribe exactly for parity; it's functional UI text).
- Assets to **redraw as originals** (avoid copying files): mascot, illustration set
  (folders, phone mock, scattered bookmarks, focus demo cards), app icon (no brand copy
  if publishing), error/empty illustrations. Keep layout/color language, not the artwork.
- Fonts: heavy rounded sans (e.g., SF Pro Rounded with .heavy weights approximates well).
- Palette tokens seen: cream `#FAF6EC`, ink `#0F0F0F`, highlighter yellow `#FFD147`,
  CTA yellow `#FFCF5C`, green banner/icon `#25D0A0`, pin/gray `#8E8E93`,
  dark bg `#101014`, dark card `#2B2C33`, danger `#F0526B`.

---

## 7. QA / parity checklist

- [ ] Onboarding: 8 steps, skip, back, progress pills, demo share→pick→save, focus demo, reminders primer, paywall.
- [ ] Quick add: empty → No URL dialog; valid → saved to Unsorted + navigates + SAVING→loaded states.
- [ ] Share sheet (text + image): overlay, pin toggle styling, collection memory, save closes app.
- [ ] Collection: pinned/saves sections, NEW ribbons, sort memory per collection, select-mode toolbar.
- [ ] Details: inline title edit, notes update, move, refresh, delete confirm, pin toggle.
- [ ] Search: stats card counts, recent saves, live filter, clear/cancel.
- [ ] Focus Mode: deck gestures, progress, open link, seen clearing, entry from banner + collection.
- [ ] Settings: usage meters + midnight countdown, haptic, dark theme persist, reminders flow, how-to, feedback mailto, delete-all.
- [ ] Pro gates: each of 8 gates shows correct paywall copy; free limits enforced (4 links, 10 images, 3 collections).
- [ ] Import/export: CSV/HTML/JSON import + zip/JSON backup (Pro), errors handled.
- [ ] Dark mode: every screen audited.
- [ ] Empty states: home, collection, search, move sheet.
- [ ] Offline: save works, scrape fails gracefully, Refresh recovers.

---

## 8. Open items to verify later (low-risk unknowns)

- Collection edit/rename/delete UI (assumed long-press or settings entry; Android long-press didn't trigger over adb).
- Lifetime plan card on Android paywall (iOS has $49.99 lifetime).
- "Show me →" full paywall (same as onboarding paywall, assumed).
- Subcollection UI after purchase (nested collection view), Share Collection output (image/file?).
- Image save happy path (my adb harness couldn't grant URI permissions; app error path verified).
- Reminder scheduling cadence (daily unseen nudge assumed).
- Google Drive sync internals (folder layout, merge rules).

---

## 9. Legal guardrails (brief)

- We rebuild behavior/UX; we do **not** copy code (none is public) or ship their artwork,
  mascot, logo, or app name/trademark in any published build. Internal/personal clone is fine;
  if publishing, rebrand and redraw assets.
- Scraping third-party sites for OG data = same as any link-preview feature; keep it light
  (single HTML fetch, respect robots where applicable).

---

## 10. Timeline (rough, hands-on build)

| Milestone | Scope | Est. |
|---|---|---|
| M1 | CI spike: GitHub Actions macOS builds app, boots iOS Simulator, returns screenshots | 1–2 d |
| M2 | Design system + shell + DB/models + usage/pro-gate core | 2–3 d |
| M3 | Collections + save pipeline + details + search | 3–4 d |
| M4 | Focus Mode + onboarding + paywalls + settings | 3–4 d |
| M5 | Import/export + share extension + polish + QA parity | 3–5 d |

Sources consulted: Google Play listing (com.myCku.tuckii), App Store listing (id6776568114),
appbrain; live device exploration of Android v1.6.0 (primary reference).

---

## 11. Implementation status (living log)

Repository: https://github.com/abhinaypodugu/Tuckit (public; GitHub Actions builds,
runs unit tests, and captures simulator screenshots as artifacts).

Implemented (maps to §2/§3):
- Core library store: collections (incl. implicit Unsorted), saves, pin/seen, notes,
  inline title edits, tags (Pro), subcollection model (Pro), per-collection save sort,
  global collection sort, search, daily free quotas (4 links / 10 images / 3 collections)
  with midnight reset, Pro simulation flag, JSON persistence.
- Metadata scraper (OG/Twitter/title/favicon, entity decoding, relative URL resolution).
- Screens: Home (quick save, review banner, collections grid + sort), Collection
  (pinned/saves, sort menu, select model ready), Link details (hero, inline title,
  notes editor, Move, Refresh, Delete confirm, pin, tags gate), Search (library stats,
  recently saved, live results), Settings (plan usage + reset countdown, haptics,
  dark mode, reminders, data/storage, support, delete-all), Backup & Restore
  (export JSON via fileExporter, restore JSON, import CSV/HTML/JSON), How To guides,
  Pro upsell modal + paywall (simulated purchase), Focus Mode deck, onboarding carousel
  with interactive save demo, focus demo and paywall.
- CI: GitHub Actions macos-14 runner → XcodeGen → xcodebuild → simctl → 9 screen captures
  (home, home-dark, onboarding, collection, details, search, settings, focus, paywall).

Known deviations / not yet done:
- No iOS Share Extension or iCloud sync (out of scope by decision); quick save is the
  in-app paste bar. How To copy reflects that.
- Paywall/StoreKit is simulated (`proSimulated`); no real billing. Restore Purchases is
  non-functional. Lifetime plan card not included.
- Backup restore reads `.json` only; `.zip` not implemented. Import supports CSV/HTML/JSON.
- Focus deck uses simple stack styling (not the full 3D stage), pending polish.
- Haptics wired for save + pin; reminders schedule one 24h notification.
- iPad sidebar layout, widgets, sharing collections: not implemented.
- App icon/mascot are placeholders (no copied artwork).

Update log (latest):
- Collection overflow fully functional: Add Link dialog, bulk Select Links (All/Share/Move/Delete),
  Create Sub-collection (Pro → real sheet with parentID), Share Collection (Pro → text share sheet),
  Sort saves, Delete Collection (moves saves to Unsorted), subcollection chips with navigation.
- Cards now show OG thumbnails when available, SAVING... badge while metadata is pending,
  NEW ribbons, pin badges, tag chips.
- Onboarding gained the reminders pitch page (system permission request) → 7 pages incl. paywall.
- CI captures a dark-mode home screenshot; runs cancel superseded builds; failure logs are artifacts.
