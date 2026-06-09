<div align="center">
  <img src="assets/icon.png" alt="Murrmobile logo" width="120" />
  <h1>Murrmobile</h1>
  <p>A native Flutter client for <a href="https://murrtube.net">murrtube.net</a></p>
</div>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white" alt="Dart" /></a>
</p>

## Overview

Murrmobile is an unofficial, cross-platform mobile and desktop app for [murrtube.net](https://murrtube.net). It is built entirely in [Flutter](https://flutter.dev) and reverse-engineered from the website's [Inertia.js](https://inertiajs.com) frontend, allowing it to provide a native app experience without requiring a dedicated public API.

The app supports iOS, Android, macOS, Linux, Windows, and Web from a single codebase.

## Features

- **Home Feed** — Browse Trending, Latest, and Subscriptions with pull-to-refresh and infinite scroll pagination
- **Video Player** — Full HLS streaming support with adaptive quality, fullscreen landscape mode, auto-hiding controls, timeline scrubbing, and wakelock while playing
- **Search** — Real-time tag and user suggestions with debounced queries; search by video title, tag, or user
- **Comments** — View, post, reply to, and delete comments on videos
- **User Profiles** — View profiles, videos, playlists, subscribe/unsubscribe, block/unblock
- **Notifications** — In-app notification feed
- **Upload** — Upload videos directly from the app
- **Themes** — Dark, light, and AMOLED themes with persistent preferences
- **Responsive Layout** — Adaptive navigation rail on desktop/tablet, bottom nav on mobile
- **Cross-Platform** — One codebase targeting Android, iOS, macOS, Linux, Windows, and Web

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.12.1
- A supported IDE (VS Code or Android Studio recommended)
- For mobile: Android SDK or Xcode (Optional for desktop builds)

### Run the app

```bash
# Clone the repository
git clone https://gitlab.com/HttpAnimations/Murrmobile-App.git
cd Murrmobile-App

# Install dependencies
flutter pub get

# Run on your connected device or emulator
flutter run
```

### Build for release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release
```

## Downloads

Pre-built binaries for all platforms are available on the [releases page](https://github.com/openlyst/Murrmobile-App-builds/releases).

| Platform | Download |
|----------|----------|
| Android | APK / AAB |
| iOS | Unsigned IPA |
| Linux | ZIP (x64) |
| macOS | Unsigned ZIP |
| Windows | ZIP (x64) |

> [!NOTE]
> This is an unofficial client. It is not affiliated with or endorsed by the operators of murrtube.net. The app relies on the website's internal Inertia.js protocol, which may change without notice.

> We hope to one day became a part of the murrtube stack but for now we are just a fan app.