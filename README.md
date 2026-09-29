# HarmonoPattume

Trash collection schedule (harmonogram wywozu odpadów) for Polish municipalities, in Italian, Polish and English. Built with Flutter: Android first, iOS-ready.

## Download (Android)

**[⬇ Download HarmonoPattume for Android](https://github.com/mancio/harmonoPattume/releases/latest/download/harmonopattume.apk)** (about 10 MB, signed release)

Old 32-bit phones: [harmonopattume-armv7.apk](https://github.com/mancio/harmonoPattume/releases/latest/download/harmonopattume-armv7.apk). All builds: [Releases](https://github.com/mancio/harmonoPattume/releases).

The app is not on Google Play yet, so Android asks a few questions the first time:

1. Open the downloaded file. If Android says installing from this source isn't allowed, tap **Settings → Allow from this source** (this is asked only once for the browser or file manager you use).
2. Tap **Install**.
3. If Play Protect shows "App scan recommended" or "Unrecognized app", tap **Scan app** or **Install anyway**.

Later versions install over the old one and keep your address and settings. If you had installed a test (debug) build before, uninstall it once first.

## What it does

- Pick your address (municipality, locality, street, house number) with the same names the municipality's own site uses.
- See upcoming collections grouped by day, coloured by waste type.
- Get a notification the evening before each collection day (time configurable).
- Switch language between Italiano, Polski and English, or follow the system.

## Supported municipalities

| Municipality | Source |
| --- | --- |
| Gmina Wieliczka | [wieliczka.kiedyodpady.pl](https://wieliczka.kiedyodpady.pl) |

Data comes from the unofficial JSON API behind kiedyodpady.pl (mOdpady / mMieszkaniec by Rekord Mobile), the same one used by the Home Assistant *Waste Collection Schedule* source `kiedyodpady_pl`. Many other gminas run on the same platform, so adding one is usually a new entry in `supportedMunicipalities` (`lib/sources/schedule_source.dart`). A municipality with a different data provider gets its own `ScheduleSource` implementation.

## Project layout

```
lib/
  models/collection.dart          common model (waste types, events, saved address)
  sources/schedule_source.dart    ScheduleSource interface and municipality list
  sources/kiedyodpady_source.dart kiedyodpady.pl adapter
  services/settings_store.dart    persisted settings
  services/reminders.dart         evening-before notifications
  ui/                             screens and waste styling
  l10n/app_{en,it,pl}.arb         translations
```

## Development

```sh
flutter pub get      # also generates lib/l10n/gen from the .arb files
flutter analyze
flutter test
flutter run
```

CI builds a debug APK on every pull request. Download it from the workflow run's artifacts to install it on an Android phone.
