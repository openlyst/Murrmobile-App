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

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | [Flutter](https://flutter.dev) |
| State Management | [Provider](https://pub.dev/packages/provider) |
| HTTP / API | `dart:http` with cookie jar and CSRF token handling |
| Video Playback | [`video_player`](https://pub.dev/packages/video_player) |
| Image Caching | [`cached_network_image`](https://pub.dev/packages/cached_network_image) |
| Local Storage | [`shared_preferences`](https://pub.dev/packages/shared_preferences) |
| External Links | [`url_launcher`](https://pub.dev/packages/url_launcher) |
| Sharing | [`share_plus`](https://pub.dev/packages/share_plus) |
| Wakelock | [`wakelock_plus`](https://pub.dev/packages/wakelock_plus) |

## Architecture

Murrmobile communicates with murrtube.net by mimicking the website's Inertia.js requests. It parses server-rendered JSON page props to extract data for feeds, videos, comments, user profiles, and more. Authentication is handled via session cookies and CSRF tokens, just like the web client.

```
lib/
├── main.dart                 # App entry point, theme provider setup
├── models/                   # Data models (Media, User, Comment, etc.)
├── pages/                    # UI screens (Home, Search, Video, Profile, etc.)
├── providers/                # State providers (ThemeProvider)
├── services/
│   └── murrtube_api.dart     # Inertia.js API client, all network logic
├── theme/
│   └── app_theme.dart        # Dark, light, and AMOLED theme definitions
├── utils/
│   ├── app_preferences.dart  # Shared preferences wrapper
│   └── cookie_loader.dart    # Persistent cookie storage
└── widgets/                  # Reusable UI components (VideoCard, ResponsiveShell, etc.)
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.12.1
- A supported IDE (VS Code or Android Studio recommended)
- For mobile: Android SDK or Xcode

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

# Web
flutter build web --release
```

> [!NOTE]
> This is an unofficial client. It is not affiliated with or endorsed by the operators of murrtube.net. The app relies on the website's internal Inertia.js protocol, which may change without notice.