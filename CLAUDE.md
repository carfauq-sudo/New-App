# MaintenanceGO — Project Context

This file gives Claude Code the full background on this project so it doesn't
need to be re-explained each session. Read this in full before making changes.

## What this is

A total car care and maintenance log/helper app, built as a capstone project.
AI use is encouraged and evaluated as part of the capstone.

**Central idea:** "Never forget maintenance" — the app exists to prevent
costly neglect by giving the owner a reliable, always-available record of
their vehicle's service history.

## Who it's for

- **Primary user, for now: me (the developer/owner).** This is being built
  for my own car(s) first, with the explicit intent to scale to other users
  later. Design and code quality should reflect "real product," not a
  personal throwaway script.
- Longer-term audience (not yet built for, but the architecture should not
  preclude them):
  - DIY vehicle owners who want to track parts, costs, and intervals precisely
  - Casual daily drivers who forget service intervals until something breaks
  - Used car buyers and sellers who need trustworthy proof of a vehicle's
    care history
  - Multi-car households managing more than one vehicle's records at once

## Core scope decisions (already made — do not relitigate without asking)

- **Account structure:** one account can hold multiple vehicles. Each
  vehicle has its own record set (maintenance log, reminders, etc.).
- **Offline-first.** The app must work with no signal (e.g., in a garage or
  at a shop). Local storage first; cloud sync is not a v1 requirement.
- **Manufacturer data precision matters.** The stated requirement is "must
  get vehicle manual data precise from vehicle to vehicle" — i.e., generic
  reminders are not good enough long-term; the goal is manufacturer/model-
  specific maintenance data.
  - **Data source decision:** use the **NHTSA VIN decode API** (free) for
    VIN-based vehicle data (make/model/year/trim/engine), rather than a paid
    aftermarket maintenance-schedule API. This was chosen specifically to
    keep the project free/scoped for a capstone.
  - Whether NHTSA's data is precise enough on its own, or needs to be
    supplemented with user-editable custom intervals, is still **unresolved**
    — flagged as an open blocker to investigate.
- **v1 AI scope (deliberately narrowed):** AI-assisted **receipt parsing**
  (turning a photographed/uploaded receipt into structured maintenance-record
  data). This was chosen over broader AI ambitions (e.g., full diagnostic
  chat, OEM schedule prediction) specifically to keep v1 realistic for a
  capstone timeline. Do not silently expand AI scope beyond this without
  flagging it.
- **Both casual + DIY depth intended eventually** — a maintenance record
  should support being logged quickly (casual use) OR filled with detail
  like part numbers/torque specs/costs (DIY use). Don't force one mode.

## Not yet decided (ask before assuming)

- Full v1 feature checklist beyond the above
- Auth/account structure specifics (local-only accounts are the likely
  default given offline-first, but not finalized)
- Whether/how OBD2 or telematics ("metered data") is in scope — this came up
  as a possibility in early brainstorming but has **not** been committed to;
  treat it as aspirational/out-of-scope unless explicitly revisited.

## Values and guardrails for this project

- Primary benefit: preventing costly neglect, extending vehicle life,
  documenting care history for resale value.
- Known risks to design around:
  - AI suggestions (e.g., predicted maintenance, parsed receipts) may be
    wrong or overconfident — surface AI-derived data as suggestions the user
    can correct, not as silent authority.
  - Vehicle and location data are sensitive — be thoughtful about what's
    stored and how it's exposed, especially anything tied to real-time
    location.
  - The app must not present itself as a substitute for a mechanic's
    judgment on safety-critical issues.

## Exemplary work / inspiration

- **CARFAX Car Care** — the specific thing worth learning from is its model
  of building trust through **verified, shop-reported history** rather than
  self-reported claims. Worth keeping in mind when designing how "verified"
  vs. "user-entered" data is distinguished in the UI/data model.
- Other apps researched for feature-set calibration (not necessarily to
  imitate): AUTOsist, Simply Auto, Drivvo, aCar, CarJourney, GarageHub
  (notable for its "Rev" AI assistant pattern), VinSnap, MyAutoLog.

## Tech stack

- **Framework: Flutter (Dart).** Chosen specifically over React Native
  because the developer has a Java background — Dart's syntax (strong
  typing, classes, familiar OOP patterns) was judged to be a faster ramp-up
  than JS's paradigm shift.
- **Platform: iOS only** for now (not Android). Xcode/iOS Simulator is the
  dev/test environment; do not assume Android tooling is set up.
- **Repo:** https://github.com/carfauq-sudo/New-App.git
  - Local path: `~/Desktop/Capstone Project/New-App`
  - Internal Dart package name is `new_app` (lowercase/underscore — required
    because the folder/repo name "New-App" isn't a valid Dart identifier;
    this was a deliberate `flutter create --project-name new_app .` choice,
    not an accident — don't "fix" the naming mismatch by renaming the repo).
- **Dev environment (already fully set up and verified working):**
  - macOS, Xcode 27.0, Flutter 3.47.5, CocoaPods (installed via Homebrew,
    not `gem install`, due to permission issues)
  - Primary test device: iPhone 17e simulator (via Xcode's Device Hub — this
    Xcode version does not have a standalone "Simulator.app" in Spotlight;
    it's accessed through Xcode > Open Developer Tool > Device Hub)
  - `flutter doctor` shows Android toolchain missing — **this is expected
    and fine**, since Android is out of scope.
- Git auth uses a GitHub personal access token (classic, `repo` scope),
  saved via `osxkeychain` credential helper.

## Design decisions (landing page, v1 mockup)

A non-functional landing page mockup has been built and pushed to `main`
in `lib/main.dart`. Design direction:

- **Aesthetic: dark, high-contrast, minimalist.** Explicit ask was for a
  dark grey/black background, not pure black.
- **Palette (intentional, not default):**
  - Background: `#121212`
  - Surface (cards): `#1C1C1E`
  - Border: `#2C2C2E`
  - Text primary: `#F2F2F2`
  - Text secondary: `#9A9A9E`
  - Accent: `#E8A33D` — a muted amber deliberately chosen to evoke a
    dashboard/warning-light color (thematically tied to "this needs
    attention"), used sparingly — not a generic neon accent.
- **Layout, top third:** "My Vehicle" section — vehicle name (large),
  mileage, and last-service status line (in the accent color).
- **Layout, remaining two-thirds:** two stacked nav cards — "Maintenance
  logs" and "Maintenance calendar" — outlined, minimal, non-functional
  placeholders (`onTap` does nothing yet).
- Left-aligned content (not centered) — chosen to read more like a gauge
  cluster/dashboard than a marketing hero, fitting the subject matter.

## Current status (as of this file's writing)

- Environment fully set up and verified (build/run/hot-reload all working).
- Repo initialized, scaffolded, and pushed to GitHub.
- Dark-mode landing page mockup built and pushed — **UI only, not wired to
  any real data or navigation yet.**
- **Not yet started:** the actual data model (`Vehicle`, `MaintenanceRecord`,
  `Reminder`, `ServiceType` classes), navigation/routing, local storage
  layer, and any AI/receipt-parsing functionality.

## Vehicle reference data (from the owner's manual)

The truck's manual data lives in `assets/data/toyota_tacoma_2026.json`, loaded
by `lib/data/vehicle_reference.dart`. Tests: `test/vehicle_reference_test.dart`.

- **Source:** Toyota 2026 Tacoma Owner's Manual (OM04051U, gasoline T24A-FTS
  models only). Every fact carries `page` = the printed manual page (PDF page
  index = printed page + 2).
- **Read-only, separate from user data.** Logs, the schedule and stats are the
  user's and live elsewhere. They point at reference items by id only (for
  example a log's service type is `oil_change`).
- **Performance rules:** loaded once, lazily, and parsed off the UI thread
  (`compute`). Screens must never block on it: render first, fill in when the
  future completes, and handle it failing. Keep lookups by id (maps are built at
  parse time). If the data grows large (more vehicles), swap the loader for
  SQLite behind `ReferenceRepository` without touching screens.
- **Service intervals come from a dealer page, not Toyota's guide.** The owner's
  manual has no intervals; it points to the "Scheduled Maintenance Guide /
  Owner's Manual Supplement" (P.518, 520, 554), which is still not loaded
  (`pending_sources`). The user supplied a Toyota of Cedar Park web page as the
  schedule, logged on 2026-09-21 in `schedule_sources` / `schedule_milestones`,
  flagged `official: false` and unverified. It states no model year and has
  internal inconsistencies (listed in its `caveats`). Only two `intervals` are
  filled (oil change 10,000 mi, tire rotation 5,000 mi / 6 mo), each marked
  `third_party_unverified` with its basis. Replace/confirm them from the
  official guide before relying on them (e.g. for oil-life math).
- **Decision (2026-09-21): use the most verifiable data available now, and
  replace it later with an exact VIN-based lookup.** Trust order: the owner's
  manual specs (official, verified) first; the dealer schedule is *provisional*
  (`trust_tier`, `default_schedule_source_id`). A Haynes-derived enthusiast
  schedule was compared and deliberately NOT loaded (third-hand, spans
  generations, includes V6-only items). Anything provisional must be labeled
  provisional wherever the app shows it, and replacing it must not touch user
  records, which point at service type ids only.
- **Tire specs depend on the truck's tire type (A-D at 17", A-C at 18").** The
  manual doesn't map types to trims like SR5; the vehicle profile must record
  the type from the door-jamb tire label. Don't guess.
- **Publishing later:** if the app goes public, check Toyota's terms before
  redistributing manual content, and decide how other vehicles' data gets in
  (curated files, a licensed data API, or AI-assisted import that the user
  confirms).

## Oil life (computed, not typed in)

The Home page's Oil tile is calculated from the last log tagged
`serviceTypeId: 'oil_change'`, the estimated current mileage, and the interval
in the reference data. Code: `lib/calc/maintenance_math.dart` (pure functions:
`estimateMileage`, `computeLife`), `lib/app_state.dart` (shared in-memory logs
and stats; `lifeFor`). Tests: `test/maintenance_math_test.dart`,
`test/app_state_test.dart`, `test/widget_test.dart`.

- Life left = 1 - max(miles used / interval miles, months used / interval
  months) ("whichever comes first"). Either interval can be missing.
- There is no live odometer, so current mileage is estimated from the user's
  recorded readings and average driving rate; if there isn't enough history it
  just uses the latest reading (no extrapolation).
- It shows a dash until there is an oil-change log and the reference data has
  loaded, and never invents a number. The interval is provisional (dealer
  page), so the details sheet says so.
- The truck's own dashboard oil % is stored separately as a comparison; the
  tile shows the computed value. Logs added in the add-log form need the
  "Service type" dropdown set for the app to recognize them.
- Logs and stats are memory-only until the storage layer exists.
- **Status for the weekly brief: the oil life algorithm is an experiment.** It
  was built as a test and may or may not be used in the final version. Describe
  it in the brief as exploratory (with its provisional interval and the
  truck's own oil monitor as a possible replacement), not as a committed
  feature.

## Deferred work (intentionally NOT built yet — needs doing later)

- **Camera / photo access for receipt pictures.** The "Receipt picture" option
  in the maintenance log's + menu is a "Coming soon" placeholder. Needs a
  camera/photo-picker package, iOS permission strings in `Info.plist`
  (camera and photo library usage descriptions), and a decision on whether
  receipt photos are stored locally.
- **AI receipt parsing and AI summary of mechanic reports.** The "Mechanic
  report (AI summary)" option is also a placeholder, and no AI model is wired
  up. This is the v1 AI scope. Per the guardrails above, AI output must show
  up as a suggestion the user can review and correct (it should fill in the
  manual entry form), never as silent authority. Still to decide: which model
  or API, and how to handle offline use.
- **Auto-populated maintenance calendar.** The calendar currently shows
  placeholder items, plus whatever the user schedules by hand. Eventually it
  should fill itself in from the vehicle manual's service schedule, or from
  VIN-decoded vehicle data (NHTSA VIN decode API) and service intervals. This
  ties to the open question of whether NHTSA data alone is precise enough.
- **AI scheduling.** The "Schedule with AI" option in the calendar's + menu is
  a "Coming soon" placeholder. Like the other AI features, its output should
  be a suggestion the user reviews, not silent authority.
- **AI-picked YouTube DIY videos on the calendar.** Each scheduled item's
  detail card has a "Do it yourself" section with placeholder text and fake
  video rows, marked with the AI sparkle icon. Later: search YouTube for the
  task on this vehicle, have an AI model pick credible videos, and open them
  on tap. Show them as suggestions, and keep safety-critical jobs (e.g.
  brakes) pointing to a mechanic per the guardrails above.
- **Dashboard photos for vehicle stats.** The Home page shows Avg MPG, oil
  life, and tire PSI tiles (fuel level was removed on purpose: it changes too
  often to be worth entering) (plus the odometer) that the user types in via
  an edit form. The "Dashboard photo" option is a "Coming soon" placeholder.
  Later: camera access plus a way to read the photo (OCR / vision model). Read
  values should be shown for the user to confirm before saving. Stats are also
  memory-only for now.
- **Local storage for maintenance records.** Logs added through the manual
  form currently live only in memory and disappear on restart. The data model
  (`lib/maintenance_record.dart`) exists; the storage layer does not.
- **Real data behind the My Vehicle hotspots.** Their mods/maintenance lists
  are placeholders and are not yet tied to the maintenance log records.

## How the developer prefers to work

- Learning Flutter/Dart for the first time, coming from a Java background —
  explanations that draw Java parallels are useful; don't assume prior Dart
  or mobile-dev experience.
- Prefers being walked through changes step by step and confirming each one
  works (e.g., via hot reload/simulator) before moving to the next.
- This is a capstone project with weekly graded contribution briefs — work
  should be documentable (clear commits, explainable decisions) since it
  feeds into that documentation process.
