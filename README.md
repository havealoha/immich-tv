# Immich TV

<p align="center">
  <img src="assets/png/banner.png" alt="Immich TV banner" width="860">
</p>

<p align="center">
  <img src="assets/png/playstore.png" alt="Immich TV Play Store icon" width="88">
  &nbsp;&nbsp;
  <img src="assets/png/appstore.png" alt="Immich TV App Store icon" width="88">
</p>

TV-first Immich client for browsing your self-hosted photo and video library from the couch.

Immich TV is a read-focused Flutter app built for large screens, remote navigation, and fullscreen playback. It connects to your existing Immich server and gives you a living-room experience designed for Android TV and Google TV first, while still supporting the wider Flutter platform matrix for development and validation.

## Website

- https://immichtvapp.web.app/

## Google Play

- Play Store: https://play.google.com/store/apps/details?id=com.workwithafridi.immichtv
- Public install milestone: `500+ downloads` on Google Play as of June 11, 2026

## Status

Immich TV is actively evolving and already usable as a focused TV browsing client.

Current product direction:

- Android TV / Google TV first
- Remote-first navigation and focus behavior
- Read-only browsing and playback
- Store-ready packaging and release polish
- Better resilience for large libraries and degraded networks

## Features

- Connect to an existing Immich server
- Sign in with either your Immich login or an API token
- Save profiles locally for fast re-entry on shared TV devices
- Browse timeline assets in a TV-optimized layout
- Jump between years from a horizontal year rail
- Open albums, people, and favorites
- Browse person-specific media from the People tab
- View photos and videos fullscreen
- Start slideshow playback directly from the viewer
- Use a layout tuned for TV remotes, keyboards, and pointer input
- Switch between live server access and demo content for testing

## Platform Focus

- Primary target: Android TV and Google TV
- Supported development targets: Android, web, Windows, macOS, and Linux
- UX priority: large-screen readability, predictable focus movement, and simple playback controls

## Tech Stack

- Flutter
- Dart 3.11
- `flutter_bloc`
- Dio
- `flutter_secure_storage`
- `shared_preferences`
- `video_player`

## Current Version

- App version: `1.1.3+11`

## Getting Started

### Requirements

- Flutter SDK
- An accessible Immich server
- A target device such as Android TV, Google TV, emulator, desktop, or web for development

### Run locally

```bash
flutter pub get
flutter run
```

### Quality checks

```bash
flutter analyze
flutter test
```

## Demo Access

Immich TV includes a built-in demo mode for testing.

Enter this exact server URL in the onboarding flow:

```text
https://demo.immichtv.local
```

Then sign in with:

```text
Email: demo@immich.tv
Password: demo1234
```

Demo content is only triggered when that exact URL is entered.

## Repository Map

- `lib/main.dart`: app startup and image cache tuning
- `lib/app.dart`: dependency wiring, theme setup, repository injection
- `lib/src/app_shell.dart`: top-level flow between bootstrap, onboarding, profile picker, and home
- `lib/src/core`: shared models, repositories, networking, services, and logging
- `lib/src/features`: feature-specific UI, Cubits, and data implementations
- `lib/src/shared`: shared presentation tokens, focus helpers, and reusable widgets
- `lib/src/platform`: platform-aware persistence and media adapters
- `test/`: widget and focused unit coverage
- `docs/DEVELOPMENT_CHECKLIST.md`: roadmap and current execution slices

## Screens and Branding

The repository includes packaged brand assets under `assets/png/`.

- `banner.png`
- `tv-banner-icon.png`
- `playstore.png`
- `appstore.png`

## Roadmap

- Measure and tune scroll smoothness on real TV hardware
- Improve retry and degraded-network behavior
- Expand remote-navigation and integration test coverage
- Finish Android TV packaging and broader platform validation
- Continue polishing releases, metadata, and store presentation

## Contributing

Contributions, issues, and suggestions are welcome.

If you want to contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `flutter analyze`
5. Run `flutter test`
6. Open a pull request

## Disclaimer

Immich TV is an independent client project and is not an official Immich app. You must already run or have access to an Immich server to use it.

## License

This project is licensed under the MIT License.

See [LICENSE](LICENSE) for details.
