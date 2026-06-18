# mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## BirdLens Mobile

This folder contains the Flutter client for BirdLens. The app implements onboarding, authentication, image capture, prediction, favorites, history, and profile flows. It communicates with the Express backend (`/api`) and relies on temporary signed URLs for representative bird images.

### Key features

- Onboarding and Auth: Sign up, sign in, and secure token persistence using `flutter_secure_storage`.
- Scan & Predict: Image capture/selection, client-side resize/compression, multipart upload via `dio`, upload progress, and retry.
- Favorites & History: Favorites use a composite key to prevent duplicates; history lists newest-first and allows bulk deletion.
- Caching & Offline UX: Cached image loading, graceful network failure handling, and retry options.
- Accessibility: Improved contrast, semantic labels, and scalable text.

### Local development

Requirements: Flutter SDK 3.x, an emulator or device.

```bash
cd mobile
flutter pub get
flutter run
```

### Configuration

Set API base URL in `.env` (or `lib/constants/api_constants.dart`) as `API_BASE_URL`.

### CI & Builds

The repo includes basic CI steps to run `flutter analyze` and `flutter test`, and a simple `flutter build` job to produce Android and iOS artifacts for distribution.

---

For full architecture, API contract, and environment details see the repository root README and `technical_report.md`.
