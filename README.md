# Immich TV

<p align="center">
  <img src="assets/png/banner.png" alt="Immich TV banner" width="860">
</p>

<p align="center">
  <img src="assets/png/playstore.png" alt="Immich TV Play Store icon" width="88">
  &nbsp;&nbsp;
  <img src="assets/png/appstore.png" alt="Immich TV App Store icon" width="88">
</p>

TV-first Immich client for browsing your self-hosted photo library from the couch.

Immich TV is a read-focused Flutter app built for large screens and remote navigation. It connects to your existing Immich server and gives you a TV-friendly experience for timeline browsing, albums, favorites, fullscreen viewing, and ambient slideshow playback.

## Website

Open the live marketing site here:

- https://immichtvapp.web.app/

## Status

This project is being prepared for open source and is actively evolving.

Current focus areas:

- Android TV / Google TV first
- Remote-friendly navigation and focus behavior
- Timeline browsing with year-based filtering
- Fullscreen asset viewing for photos and videos
- Slideshow playback with simple TV-first controls

## Features

- Connect to an existing Immich server
- Authenticate with your Immich account
- Browse timeline assets in a TV-optimized layout
- Jump between years from a horizontal year rail
- Open albums and favorites
- View photos and videos fullscreen
- Start a slideshow directly from the asset viewer
- Save profiles locally with PIN-based reopening

## Tech Stack

- Flutter
- BLoC for state management
- Dio for API access
- `video_player` for video playback
- `flutter_secure_storage` and local persistence for saved sessions/profiles

## Project Goals

- Deliver a polished TV-native gallery experience for Immich users
- Keep the initial product read-only and safe for home use
- Prioritize smooth focus handling, large-screen readability, and simple playback flows

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

### Analyze

```bash
flutter analyze
```

### Demo Access

Immich TV includes a built-in demo mode for testers.

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

## Screens and Branding

The repository includes packaged brand assets under `assets/png/`.

- `banner.png`
- `tv-banner-icon.png`
- `playstore.png`
- `appstore.png`

These are used both in the app UI and in this repository presentation.

## Roadmap

- More robust large-library timeline querying
- Better TV-specific focus choreography
- More viewer and slideshow polish
- Platform packaging and store-ready metadata
- Expanded testing around remote navigation flows

## Contributing

Contributions, issues, and suggestions are welcome.

If you want to contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `flutter analyze`
5. Open a pull request

For larger ideas or architectural changes, opening an issue first is helpful.

## Disclaimer

Immich TV is an independent client project and is not an official Immich app. You must already run or have access to an Immich server to use it.

## License

This project is licensed under the MIT License.

See [LICENSE](LICENSE) for details.
