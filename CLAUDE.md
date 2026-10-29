# Life Leveling: project handoff

Read this first. It carries everything from the planning chat where this app was designed.

## Who and what

- Owner: Jihad, based in Libya. Runs an auto parts shop (9am to 11pm), a car import business (Copart/IAAI → Libya), a private-label parts brand (ignition coils), a 3D printing partnership, and is planning a modern repair shop.
- The app: a Solo Leveling style "System" for real life. Real tasks are quests, quests give XP, tracks level up, all tracks feed one Master Level.
- Built in Flutter, Android first. Jihad mostly uses his phone; his Windows PC has Android Studio but did not have the Flutter SDK as of 2026-09-26.

## Where the plans live (Claude artifacts, private to Jihad)

- Plan doc "Life Leveling System" (Master Plan, XP Engine, Build Plan, System Features, Savings Vault, Extra Features, one tab per track): https://claude.ai/code/artifact/46fbbd3a-f6dc-4e34-892d-551d791b7027
- UI design canvas (26 phone screens incl. Arabic): https://claude.ai/artifact/TbZdS3Zg2NkfWe7HsUqWbV
- Web preview of v0.1 (an older build, published 2026-09-26): https://claude.ai/artifact/W3FXmbCyoR61eiRC9JqYMn
- The rules needed for v0.1 are copied below, so the code does not depend on those links.

## Current status: v0.1 compiles, 39 tests pass, pushed

Built with Flutter 3.47 (Dart 3.13): `flutter analyze` is clean and `flutter test` passes (39 tests). It has not yet been run on a phone.

History: the first cloud session's v0.1 was lost because GitHub pushes were refused and the container was reclaimed. It was rebuilt on 2026-10-29 and pushed immediately. **Push after every working step.** Cloud containers are temporary.

The android/ and web/ folders are committed (from `flutter create --project-name life_leveling --org com.jihad --platforms android,web .`) with the INTERNET permission in the manifest.

Cloud sessions cannot download the Android SDK (dl.google.com is blocked by the network policy), so APKs are built by GitHub Actions. `flutter build web` works in the cloud for previews.

### To build and run locally

```
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run            # phone plugged in, USB debugging on
flutter build apk --release   # APK at build/app/outputs/flutter-apk/app-release.apk
```

Release builds are signed with the debug key for now (fine for sideloading, not for the Play Store).

### Gotchas

- Fonts (Rajdhani, IBM Plex Sans, both OFL) are bundled in assets/google_fonts/ and `GoogleFonts.config.allowRuntimeFetching = false`, so fonts never download. Widget tests set `AppTheme.useGoogleFonts = false`.
- google_fonts is pinned to ^8.2.1. v9 moved to the standalone `material_ui` package and its TextTheme doesn't match `flutter/material`'s.
- Saving: lib/data/save_store.dart picks a JSON file on Android and localStorage on the web (conditional import).
- Web preview publish: `flutter build web --release --no-web-resources-cdn --pwa-strategy=none`, drop skwasm/wimp/webparagraph and *.symbols, skip AssetManifest.bin (web uses the .bin.json), serve shaders/*.frag as application/json, and write the page without html/head/body tags.

## v0.1 scope (Build Plan, "v0.1 MVP")

Onboarding (Awakening → name → tracks → weight), Status Window, Daily Quests for all 8 tracks + side quests, XP Engine, track levels, Master Level with balance gates, streaks, missed-daily penalty, daily reset at midnight, in-app "[ Daily Quest has arrived ]" window, local save. Done when Jihad uses it 7 days in a row without needing a fix.

## Code map

| Path | What |
| --- | --- |
| lib/core/xp_engine.dart | All leveling math. Pure Dart, unit-tested. |
| lib/core/content.dart | The 8 tracks and every quest with XP. Tune numbers here. |
| lib/core/game_logic.dart | Toggle quest (replay-from-day-start), day rollover, penalties, streaks. |
| lib/core/models.dart | GameState + JSON. |
| lib/data/ | GameRepository over a SaveStore (file on Android, localStorage on web). |
| lib/state/game_controller.dart | Riverpod AsyncNotifier. Midnight timer + check on app resume. |
| lib/ui/ | Theme, dialogs (System window unfold animation), screens. |
| test/ | 39 tests: XP engine, game logic, and an onboarding → quest widget test. |
| .github/workflows/build-apk.yml | Cloud build: analyze, test, build APK, publish as a GitHub release. |

Packages: flutter_riverpod ^3.4.3, google_fonts ^8.2.1, path_provider ^2.1.6, web ^1.1.2.

## Game rules (from the XP Engine doc)

- XP to next level = base × (1 + level × 0.25), rounded. Bases: Auto Parts 100, Private Label 60, Repair Shop 60, Car Business 45, 3D Printing 45, Mind 45, Body 40, Hobbies 40.
- Master Level = 1 + (sum of (track level − 1)) ÷ 4, rounded down.
- Balance gates: Master Level 10 needs every active track ≥ 3; 20 → 7; 30 → 12; 50 → 20; 100 → 40.
- Hunter Rank by Master Level: E 1–9, D 10–24, C 25–44, B 45–69, A 70–99, S 100–149, National 150+.
- Multipliers stack but cap at 4x total.
- Missed daily quest: −5 XP (Mind meditation −3, Hobbies 0). Side quests never penalize. XP can drop to 0 within a level but never below: you can never lose a level.
- Streak: a track's streak goes up when all its dailies are done (Hobbies: any quest). Otherwise it resets.
- If the app wasn't opened for days, at most 7 missed days are scored.

The quest names and XP values in content.dart (other than Repair Shop's setup step) were chosen by Claude, not the plan. Jihad may want to tune them.

## Decisions made in the planning chat

- v0.1 saves to a JSON file, not Drift. Move to Drift in v0.2 when reports/history need queries.
- Repair Shop got a daily quest "One setup step (research, visit, budget)" 20 XP so it doesn't block the level-10 balance gate.
- The real 9am phone notification (flutter_local_notifications + timezone, needs core library desugaring and manifest receivers) was postponed. Add it next.
- Notion sync for the idea logbook was discussed and put on hold.
- Style: dark System look. Colors #060A13 ground, #0B1424 panels, #5CC8FF cyan, #F0C35A gold, #B79BFF crystal purple, #FF6B78 red. Fonts Rajdhani (display) + IBM Plex Sans (body); Arabic uses Cairo + IBM Plex Sans Arabic.

## Savings Vault (planned for v0.2; full design in the plan doc's "Savings Vault" tab)

- Tracker: deposits (incl. real savings), withdrawals with a reason, "Reinvested" money counts toward the total. Shows total, bar to the next 20,000 dinars, history chart, savings streak.
- Daily random save 0–10 dinars: exact = 5 XP, more = +1, double or more = +2; 0 = free completion. Missing it: no XP penalty, breaks the savings streak.
- Treasure Quest: ~5%/day, 10–100 dinars, 3 days, ~1 XP per 3 dinars (min 10), same bonus rule; expiring costs nothing.
- Every 20,000 dinars: 300 XP (+100 Gold, Double XP Charm, +5 Wealth: later versions). Titles "Treasure Keeper" (first 20,000) and "Vault Lord" (100,000). Each milestone rewards once.
- Savings streak: 7 days +10 XP, 30 days Freeze Token, 100 days Golden Vault.
- Vault reset: once per 30 days, double confirm, history archived as a "season", earned XP/titles kept.
- XP goes to the Car Business track by default.

## Cloud build (GitHub Actions)

The repo is jihad-g/solo-levelling-app. .github/workflows/build-apk.yml runs on every push: checkout → setup-java 17 → subosito/flutter-action@v2 (stable) → pub get → analyze → test → `flutter build apk --release` → softprops/action-gh-release@v2 publishing the APK as release `build-N` (pre-release unless the branch is main), so it installs straight from the phone via the Releases page.

## Next steps, in order

1. Install the APK from GitHub Releases and run it on Jihad's phone for 7 days.
2. Add the 9am notification + 10pm check-in.
3. v0.2: Savings Vault, level-stones, level-up screen polish, loot drops, random quests, Idea Logbook, achievements, Drift.
4. v0.3 economy (Gold, shops, Penalty Zone), v0.4 big systems (Gates, Boss, ranks, Shadow Army, classes), v0.5 polish (AI voice via free Gemini tier, reports, business numbers, widget, backup, Arabic, sounds).
