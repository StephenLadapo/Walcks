# Walcks

**Walcks** is a personal-safety companion app for people who walk alone — commuting, jogging, or walking home late. It keeps trusted contacts informed, monitors your journey in real time, and gives you fast access to help.

> Built with Flutter. Hackathon project.

---

## The idea

Walking alone is a daily reality for a lot of people, and the risk is highest exactly when nobody is watching. Walcks closes that gap with a simple loop: **tell someone where you're going → let the app watch your progress → know that someone will notice if something goes wrong.**

Everything is stored locally on the device. There is no account, no server, and nothing is uploaded.

## Features

### Monitored Walk
The core of the app. Start a walk and Walcks tracks it from Point A to Point B.

- Live GPS tracking using the device's location stream (high accuracy, 10 m distance filter).
- Destination selection by typing an address (geocoded to coordinates).
- Live map with your position, your destination, and the route you've covered (OpenStreetMap tiles).
- **Prolonged-stop detection:** if there is little or no movement (less than 20 m) for **5 minutes**, Walcks asks *"Are you safe?"* and prompts you to contact emergency services or your contacts.
- Start and arrival alerts to your emergency contacts, using a message template you control.
- Choose which SIM card to send an emergency SMS from, on devices with multiple SIMs.
- "I Have Safely Arrived" and "Stop and Save Walk" flows — every finished walk is saved to your history.

### Emergency Contacts
- Save up to **5** trusted emergency contacts.
- Add, edit and delete contacts, with duplicate-phone-number protection.
- Place a call to any contact in one tap via the native dialler.

### Instant Alerts
- Configure the alert message template — use `{from}` and `{to}` placeholders, which are filled in with your live position and destination.
- Send a **test alert** to all your contacts and see the real per-contact delivery result.
- Walcks never claims a message was delivered when it wasn't; it reports exactly what the device accepted.

### Safe Routes
- Shows your current GPS fix — latitude, longitude and accuracy.
- Lists the destinations you actually walk most, taken from your own walk history.
- Restart a saved route with one tap ("Walk again").

### Reminders
- Create scheduled safety check-ins with a time and repeat days.
- Enable, disable, edit and delete reminders.
- Stored on the device (see *Known limitations*).

### Walk History
- Every monitored walk, saved automatically with its outcome (completed or stopped), start time, duration and number of GPS updates.
- Delete individual records or clear the whole history.

### Settings & Profile
- Display name stored on the device.
- Appearance: **System / Light / Dark** theme.
- Toggle "notify contacts when a walk starts".
- Data management: clear walk history, clear reminders, or delete all app data.

## Design

Walcks uses a responsive dashboard layout that adapts to the screen:

| Screen width | Layout |
| --- | --- |
| Desktop (≥ 1180 px) | Full sidebar navigation |
| Tablet (820–1180 px) | Compact icon rail |
| Mobile (< 820 px) | Slide-out navigation drawer |

The UI ships with a custom light **and** dark palette (purple/coral brand), Material 3 theming, the Inter font with a clean sans-serif fallback, and animated, accessible components.

## Tech stack

- **Flutter** / **Dart** (SDK `^3.13.4`, requires Flutter **3.44.0+**)
- [`geolocator`](https://pub.dev/packages/geolocator) — GPS position and permission handling
- [`flutter_map`](https://pub.dev/packages/flutter_map) + [`latlong2`](https://pub.dev/packages/latlong2) — OpenStreetMap mapping
- [`geocoding`](https://pub.dev/packages/geocoding) — address → coordinates lookup
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) — local, on-device storage
- [`url_launcher`](https://pub.dev/packages/url_launcher) — launching `tel:` calls
- [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) — generated app icons

## Project structure

```
lib/
├── main.dart                     # App entry, responsive dashboard shell
├── theme.dart                    # Light/dark palettes, typography, theming
├── models/                       # Data models + on-device repositories
│   ├── app_settings.dart
│   ├── emergency_contact.dart
│   ├── reminder.dart
│   └── walk_record.dart
├── screens/
│   ├── journey_page.dart         # Monitored walk workflow
│   ├── alerts_page.dart          # Alert configuration and testing
│   ├── routes_page.dart          # Current location + recent destinations
│   ├── reminders_page.dart       # Safety check-in reminders
│   ├── walk_history_page.dart    # Saved walk records
│   └── settings_page.dart        # Profile, appearance and data
├── services/
│   └── sms_service.dart          # Native SMS bridge (method channel)
└── widgets/                      # Shared UI components
```

## Getting started

### Prerequisites

- Flutter **3.44.0** or newer (Dart **3.13.4**+)
- A device/emulator with location services, for the full experience

### Run it

```bash
flutter pub get
flutter run
```

To run in a browser instead:

```bash
flutter run -d chrome
```

### Build

```bash
flutter build apk        # Android
flutter build web        # Web
```

## Known limitations

Walcks is honest about what works and what still needs wiring up:

- **Automatic SMS alerts** require a native `walcks/sms` bridge (SIM selection + sending) in the Android host. That bridge is **not included** in this repository, so on the web build and on a default Android host the app reports the failure instead of showing a false success. You can still call contacts directly from the Contacts page.
- **Reminder notifications** are stored and shown inside the app, but this build does not schedule OS-level notifications, so reminders won't fire while the app is closed.
- **Destination lookup (geocoding)** is not supported on the web build; use Android/iOS for that flow.

## Data & privacy

All data — contacts, walk history, reminders and preferences — is stored locally on the device using `shared_preferences`. Walcks has no backend and sends nothing to a server.

## License

Released for hackathon and educational use.
