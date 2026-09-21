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

## How the developer prefers to work

- Learning Flutter/Dart for the first time, coming from a Java background —
  explanations that draw Java parallels are useful; don't assume prior Dart
  or mobile-dev experience.
- Prefers being walked through changes step by step and confirming each one
  works (e.g., via hot reload/simulator) before moving to the next.
- This is a capstone project with weekly graded contribution briefs — work
  should be documentable (clear commits, explainable decisions) since it
  feeds into that documentation process.
