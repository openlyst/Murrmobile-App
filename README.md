# Murrtube Mobile

A native Flutter app for [murrtube.net](https://murrtube.net/), reverse-engineered from the website's Inertia.js API.

## Setup

1. Run `flutter pub get`
2. Copy your murrtube.net browser cookies into `assets/cookies.txt`
3. Run the app

## Features

- Home feed (Trending / Subscriptions)
- Video player with HLS streaming
- Search (videos, users, tags)
- Comments and replies
- Notifications
- Upload page
- Settings
- About pages (Terms, Privacy, Cookies)

## Tests

### Integration Tests (Real API)
```bash
flutter test integration_test/murrtube_real_test.dart
```

These tests hit the actual murrtube.net servers using your cookies.

## Architecture

- `lib/services/murrtube_api.dart` — Inertia.js API client
- `lib/models/` — Data models (User, Media, Comment, etc.)
- `lib/pages/` — All app pages matching the site's routes
- `lib/widgets/` — Reusable UI components
