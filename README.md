# Murrtube Mobile

A native Flutter app for [murrtube.net](https://murrtube.net/), reverse-engineered from the website's Inertia.js API.

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