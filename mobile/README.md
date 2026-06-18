# 📱 BirdLens — Flutter Mobile App

> **Cross-platform Flutter client for BirdLens. Implements onboarding, JWT authentication, camera/gallery image capture, AI prediction, bird details, favorites, history, and profile flows — all backed by Riverpod state management and a Dio HTTP layer.**

---

## 📑 Table of Contents

- [Screenshots](#-screenshots)
- [Download](#-download)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#️-architecture)
- [Project Structure](#-project-structure)
- [State Management (Riverpod)](#-state-management-riverpod)
- [Networking (Dio)](#-networking-dio)
- [Navigation & Session Gating](#️-navigation--session-gating)
- [Screen Reference](#-screen-reference)
- [Theme System](#-theme-system)
- [Secure Storage](#-secure-storage)
- [Environment Configuration](#️-environment-configuration)
- [Key Workflows](#-key-workflows)
- [Build & Release](#-build--release)
- [Privacy & Security](#-privacy--security)
- [Known Limitations & Roadmap](#-known-limitations--roadmap)
- [Troubleshooting](#-troubleshooting)

---

## 📸 Screenshots

> **App screenshots coming soon** — Flutter build in progress.

| Onboarding | Sign In | Home | Scan |
|:---:|:---:|:---:|:---:|
| ![Onboarding](screenshots/placeholder_onboarding.png) | ![Sign In](screenshots/placeholder_signin.png) | ![Home](screenshots/placeholder_home.png) | ![Scan](screenshots/placeholder_scan.png) |
| *Welcome flow* | *Auth screen* | *Main navigation* | *Camera/gallery picker* |

| Result | Bird Details | Favorites | History |
|:---:|:---:|:---:|:---:|
| ![Result](screenshots/placeholder_result.png) | ![Details](screenshots/placeholder_details.png) | ![Favorites](screenshots/placeholder_favorites.png) | ![History](screenshots/placeholder_history.png) |
| *Prediction + confidence* | *Species info + S3 image* | *Saved birds* | *Prediction log* |

---

## ⬇️ Download

| Platform | Link |
|----------|------|
| Android APK | 📦 [Download latest APK](releases/birdlens-latest.apk) *(coming soon)* |
| iOS TestFlight | 🍎 TestFlight link coming soon |

> **Note:** Android APK requires enabling "Install from unknown sources" in device settings.

---

## ✨ Features

```
Authentication
  ├─ Sign up (username, email, password with validation)
  ├─ Sign in with JWT persistence
  ├─ Auto-session restore via flutter_secure_storage
  └─ Sign out with token cleanup

Prediction
  ├─ Camera capture or gallery selection
  ├─ Client-side image resize + compression before upload
  ├─ Multipart upload via Dio with progress indicator
  ├─ Retry on network failure
  └─ Enriched result: species, scientific name, habitat,
     conservation status, confidence, signed S3 image

Birds
  ├─ Full species detail screen
  ├─ Cached image loading with placeholder/fallback
  └─ Add/remove favorite from detail screen

Favorites
  ├─ Persistent saved bird collection
  ├─ Composite-key duplicate prevention (backend enforced)
  └─ Remove individual favorites

History
  ├─ Chronological prediction log (newest first)
  ├─ Confidence displayed per entry
  └─ Bulk clear history

Profile
  ├─ Current user info display
  └─ Logout
```

---

## ⚡ Quick Start

**Requirements:**
- Flutter SDK 3.x
- Dart 3.x
- Android emulator, iOS simulator, or physical device

```bash
# 1. Navigate to mobile directory
cd mobile

# 2. Install dependencies
flutter pub get

# 3. Configure API base URL
# Create/edit lib/constants/api_constants.dart or .env:
API_BASE_URL=http://10.0.2.2:5001  # Android emulator → localhost
# API_BASE_URL=http://localhost:5001 # iOS simulator

# 4. Run on connected device/emulator
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test
```

---

## 🏗️ Architecture

### Layered Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Screens & Widgets                │
│  splash / welcome / auth / home / scan / birds /    │
│  favorites / history / profile                      │
└───────────────────────┬─────────────────────────────┘
                        │  reads state, dispatches actions
                        ▼
┌─────────────────────────────────────────────────────┐
│                  Riverpod Providers                 │
│  authProvider / predictionProvider /                │
│  favoritesProvider / historyProvider /              │
│  profileProvider / navigationProvider               │
└───────────────────────┬─────────────────────────────┘
                        │  calls
                        ▼
┌─────────────────────────────────────────────────────┐
│                 Feature Services                    │
│  auth_service / bird_service / favorite_service /   │
│  history_service / profile_service /                │
│  image_picker_service / secure_storage_service      │
└───────────────────────┬─────────────────────────────┘
                        │  HTTP requests
                        ▼
┌─────────────────────────────────────────────────────┐
│               Configured Dio Client                 │
│  dio_client.dart                                    │
│  Base URL, timeouts, Bearer token interceptor,      │
│  error normalization, 401 session cleanup           │
└───────────────────────┬─────────────────────────────┘
                        │  HTTPS
                        ▼
                Express API (/api/*)
```

### Dependency Rule

```
Screens → Providers → Services → Dio → API

No screen ever calls Dio directly.
No provider knows about HTTP or Dio.
No service knows about widgets or navigation.
```

---

## 📁 Project Structure

```
mobile/
│
├── pubspec.yaml                  # Dependencies and assets
├── analysis_options.yaml         # Dart lint rules
│
├── assets/
│   ├── images/                   # Illustration assets
│   └── icons/                    # App icons
│
└── lib/
    ├── main.dart                 # MaterialApp, named routes, AuthGate wiring
    │
    ├── constants/
    │   └── api_constants.dart    # API base URL, route paths
    │
    ├── providers/
    │   ├── auth_provider.dart    # Session state, login, signup, logout
    │   ├── favorites_provider.dart # Favorites list + add/remove
    │   ├── history_provider.dart  # History list + delete
    │   ├── navigation_provider.dart # Bottom nav tab index
    │   └── profile_provider.dart  # Current user profile
    │
    ├── services/
    │   ├── dio_client.dart        # Configured Dio singleton
    │   ├── secure_storage_service.dart # flutter_secure_storage wrapper
    │   ├── auth_service.dart      # signup / login / me / logout
    │   ├── bird_service.dart      # predict / getById
    │   ├── favorite_service.dart  # add / list / remove
    │   ├── history_service.dart   # list / delete
    │   ├── image_picker_service.dart # camera / gallery picker + compress
    │   └── profile_service.dart   # current user fetch
    │
    ├── themes/
    │   └── app_colors.dart        # 8 theme palettes
    │
    ├── widgets/
    │   ├── widgets.dart           # Barrel export
    │   ├── text_styles.dart       # Shared typography
    │   ├── signinwidget.dart      # Auth form components
    │   ├── image_widget.dart      # Cached image with placeholder
    │   ├── bird_card.dart         # Reusable species card
    │   └── app_shadows.dart       # Shared shadow styles
    │
    └── screens/
        ├── splashScreen/splash_screen.dart
        ├── auth_gate.dart          # Session check → route decision
        ├── Welcome/welcome.dart    # 3-page onboarding
        ├── auth/signin.dart
        ├── auth/signup.dart
        ├── navigation/navigation.dart  # Bottom tab shell
        ├── home/home.dart
        ├── birds/bird_screen.dart      # Prediction result + bird details
        ├── favorites/favorites.dart
        ├── history/history.dart
        └── profile/profile.dart
```

---

## 🔄 State Management (Riverpod)

Riverpod is the **state ownership layer** — all async data and user actions go through providers, never directly in widgets.

### Provider State Shapes

**Auth Provider:**
```
unauthenticated  →  AuthGate sends to /welcome
authenticating   →  Loading indicator shown
authenticated(user, token)  →  AuthGate enters /main
error(message)   →  Error shown on auth screen
```

**Prediction Provider:**
```
idle            →  Scan button ready
selectingImage  →  Image picker open
uploading       →  Progress indicator
success(result) →  Push to /birdDetails with result
failure(msg)    →  Error with retry option
```

**Favorites Provider:**
```
loading  →  Skeleton/spinner
data([]) →  Empty state widget
data([birds]) →  Bird card list
failure  →  Error with retry
```

**History Provider:**
```
loading  →  Skeleton
data([]) →  "No predictions yet" empty state
data([items]) →  Newest-first list
failure  →  Error with retry
```

### Provider Usage Pattern

```dart
// Widget reads state
final authState = ref.watch(authProvider);

// Widget dispatches action
ref.read(authProvider.notifier).login(email, password);

// Conditional rendering
return switch (authState) {
  AuthLoading() => const LoadingSpinner(),
  AuthAuthenticated(user: final u) => HomeScreen(user: u),
  AuthError(message: final msg) => ErrorView(message: msg),
  _ => const SignInScreen(),
};
```

---

## 🌐 Networking (Dio)

`dio_client.dart` configures a singleton Dio instance used by all feature services:

```dart
Dio configureDio(String baseUrl, SecureStorageService storage) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {"Content-Type": "application/json"},
  ));

  // Attach JWT to all protected requests
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.readToken();
      if (token != null) {
        options.headers["Authorization"] = "Bearer $token";
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await storage.deleteToken();  // Clear invalid session
        // Navigate to sign-in
      }
      handler.next(error);
    },
  ));

  return dio;
}
```

**The client never talks to FastAPI, PostgreSQL, or AWS directly.** All requests go to the Express `/api/*` namespace.

### Multipart Image Upload

```dart
// bird_service.dart
Future<PredictionResult> predict(File imageFile) async {
  final compressed = await ImagePickerService.compressImage(imageFile);
  
  final formData = FormData.fromMap({
    "image": await MultipartFile.fromFile(
      compressed.path,
      filename: "bird.jpg",
      contentType: MediaType("image", "jpeg"),
    ),
  });

  final response = await dio.post(
    "/api/birds/predict",
    data: formData,
    onSendProgress: (sent, total) {
      // Update upload progress provider
    },
  );
  return PredictionResult.fromJson(response.data);
}
```

---

## 🗺️ Navigation & Session Gating

### Route Map

```
/splash     →  SplashScreen (checks session)
/           →  AuthGate (routes based on auth state)
/welcome    →  3-page onboarding
/signIn     →  Sign in screen
/signUp     →  Sign up screen
/main       →  MainNavigation (tab shell)
/home       →  Home screen
/favorites  →  Favorites list
/history    →  History list
/profile    →  Profile screen
/birdDetails →  Species detail + prediction result
```

### AuthGate Logic

```dart
class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return switch (authState) {
      AuthLoading() => const SplashScreen(),
      AuthAuthenticated() => const MainNavigation(),
      _ => const WelcomeScreen(),
    };
  }
}
```

### Session Boot Sequence

```
App launch
    │
    ▼
SplashScreen → authProvider.init()
    │
    ├─ SecureStorage.readToken()
    │     │
    │     ├─ Token exists?
    │     │     │
    │     │     └─ GET /api/auth/me
    │     │           ├─ 200 → authenticated(user, token)
    │     │           └─ 401 → delete token → unauthenticated
    │     │
    │     └─ No token → unauthenticated
    │
    └─ AuthGate routes accordingly
```

---

## 📺 Screen Reference

| Screen | Route | Auth | Responsibility |
|--------|-------|------|---------------|
| Splash | `/splash` | None | Token check → route |
| Welcome | `/welcome` | None | 3-slide onboarding with smooth page indicator |
| Sign In | `/signIn` | None | Validate → login → secure store → enter app |
| Sign Up | `/signUp` | None | Validate → register → secure store → enter app |
| Main Navigation | `/main` | ✅ | Bottom tab shell (Home, Favorites, History, Profile) |
| Home | `/home` | ✅ | Entry point, scan CTA, recent activity |
| Scan | (modal) | ✅ | Image picker → compress → upload → progress |
| Bird Screen | `/birdDetails` | ✅ | Species name, scientific name, habitat, conservation, image, confidence |
| Favorites | `/favorites` | ✅ | Saved species list, tap → details, swipe/button remove |
| History | `/history` | ✅ | Newest-first predictions with confidence, bulk clear |
| Profile | `/profile` | ✅ | User info, logout |

### Shared UI States

Every data screen handles all four states:

```
Loading    → Shimmer skeleton or spinner
Data       → Content with interaction
Empty      → Friendly empty state with action CTA
Error      → Error message + retry button
```

---

## 🎨 Theme System

Eight color palettes defined in `themes/app_colors.dart`. Each palette provides:

| Token | Usage |
|-------|-------|
| `primary` | CTA buttons, active icons, highlights |
| `background` | Screen background |
| `text` | Primary text |
| `border` | Input borders, dividers |
| `white` | Cards, surfaces |
| `lightText` | Secondary/hint text |
| `card` | Card fill |
| `shadow` | Shadow color for elevation |

**Available themes:**

```
🌲 Forest     ☕ Coffee      💜 Purple
🌊 Ocean      🌅 Sunset      🌿 Mint
🌙 Midnight   🌹 Rose Gold
```

`FlutterScreenUtil` adapts all dimensions and text sizes to the device screen, using a reference design size as baseline.

---

## 🔒 Secure Storage

`flutter_secure_storage` persists the JWT using platform-native keystore mechanisms:

```
Android → Android Keystore
iOS     → Keychain
```

**Token lifecycle:**

```dart
class SecureStorageService {
  static const _tokenKey = "jwt_token";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() =>
      _storage.read(key: _tokenKey);

  Future<void> deleteToken() =>
      _storage.delete(key: _tokenKey);
}
```

**Never stored in:**
- `SharedPreferences` (not encrypted)
- App state / memory only (lost on restart)
- Log output
- App bundle / source code

---

## ⚙️ Environment Configuration

```dart
// lib/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5001',
  );
}
```

Or via `flutter_dotenv`:

```
# .env (not committed)
API_BASE_URL=https://your-backend.onrender.com
```

**For local development:**

| Target | `API_BASE_URL` |
|--------|---------------|
| Android emulator | `http://10.0.2.2:5001` |
| iOS simulator | `http://localhost:5001` |
| Physical device | `http://<your-machine-ip>:5001` |
| Production | `https://your-api.onrender.com` |

> The mobile bundle must **never** contain database URLs, JWT secrets, AWS keys, or any backend secrets.

---

## 🔄 Key Workflows

### Login

```
SignIn screen
    │ user submits form
    ▼
authProvider.login(email, password)
    │
    ▼
AuthService.login()
    │  POST /api/auth/login
    ▼
SecureStorageService.writeToken(jwt)
    │
    ▼
authProvider state → authenticated(user, token)
    │
    ▼
AuthGate → NavigatorPush(/main)
```

### Prediction

```
Home screen → tap "Scan"
    │
    ▼
ImagePickerService.pickImage(camera | gallery)
    │  Returns compressed File
    ▼
predictionProvider.predict(imageFile)
    │
    ▼
BirdService.predict()
    │  Dio multipart POST /api/birds/predict
    │  + Authorization: Bearer <jwt>
    ▼
predictionProvider state → success(result)
    │
    ▼
Navigator.pushNamed('/birdDetails', arguments: result)
    │
    ▼
BirdScreen renders:
  - Species name + scientific name
  - Habitat + conservation status
  - S3 image (CachedNetworkImage)
  - Confidence % + is_confident badge
  - Add/Remove Favorite button
```

### Add Favorite

```
BirdScreen → tap ♥
    │
    ▼
favoritesProvider.add(bird_id)
    │
    ▼
FavoriteService.add()
    │  POST /api/favorites { bird_id }
    ▼
Provider refreshes → list includes new bird
    │  (or optimistic update)
    ▼
UI icon updates to filled ♥
```

---

## 🏗️ Build & Release

### Debug Build

```bash
flutter run                   # connected device
flutter run -d emulator-xxxx  # specific emulator
```

### Release APK (Android)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Release App Bundle (Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS Archive (Xcode)

```bash
flutter build ios --release
# Then open Xcode → Product → Archive
```

### CI / Automated Builds

Basic CI pipeline:

```yaml
# .github/workflows/flutter.yml
steps:
  - flutter pub get
  - flutter analyze
  - flutter test
  - flutter build apk --release
  - flutter build ios --release --no-codesign
```

---

## 🔐 Privacy & Security

```
✅ JWT stored in platform keystore (flutter_secure_storage)
✅ Token never logged, never in SharedPreferences
✅ API base URL is the only config in .env (no secrets)
✅ User images uploaded to Express only — never to S3/DB directly
✅ S3 signed URLs are treated as transient — not cached long-term
✅ API errors shown as user-friendly messages (not raw internals)
✅ 401 responses auto-clear session and redirect to sign-in

⚠️  Ensure .env is in .gitignore
⚠️  Never log tokens, signed URLs, or personal data in screen code
⚠️  Signed image URLs expire — don't persist them beyond view lifecycle
```

---

## 🗺️ Known Limitations & Roadmap

### Current Limitations

| Area | Limitation |
|------|-----------|
| Offline | No offline identification; requires network |
| Species | Only 50 species supported |
| Prediction | Top-1 result only; no alternatives shown |
| Confidence | Uncalibrated softmax — may be overconfident |
| Routing | `go_router` dependency present but not yet used for declarative guards |
| Tests | Default widget test not aligned to BirdLens flows |
| i18n | Initial localization keys added; translations pending |

### Roadmap

```
Short term:
  □ Complete Riverpod provider wiring for all feature flows
  □ Add widget and provider unit tests
  □ GoRouter declarative auth redirects
  □ Proper error models and error boundary widgets
  □ Accessibility audit (contrast, semantics, text scaling)
  □ Offline/network error handling across all screens

Medium term:
  □ Top-K prediction results UI
  □ Individual history deletion (not just bulk clear)
  □ Localization (i18n) — initial structure already in place
  □ Dark mode / theme switching UI
  □ Species map / range info
  □ Onboarding re-entry for returning users

Long term:
  □ On-device inference option (TFLite)
  □ Geographic context for predictions
  □ Community sightings / sharing
  □ Offline field guide / cached species content
```

---

## 🛠️ Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Connection refused` | API not running or wrong IP | Check `API_BASE_URL`; use `10.0.2.2` for Android emulator |
| `401 Unauthorized` on all requests | Expired or missing token | Sign out and sign in again; check `JWT_SECRET` matches backend |
| Image not loading | Signed URL expired | Re-fetch from API; signed URLs expire in 1 hour |
| Upload fails with `413` | Image too large | Reduce compression quality in `image_picker_service.dart` |
| `flutter pub get` fails | Dependency conflict | Check Flutter SDK version matches `pubspec.yaml` constraints |
| Hot reload breaks state | Riverpod provider disposal | Full restart; use `flutter run --no-hot` to isolate |
| Android build fails | SDK/NDK version | Check `android/app/build.gradle` for SDK compatibility |
| iOS simulator can't connect | `localhost` routing | Use `http://127.0.0.1:5001` or check simulator network |

---

<div align="center">

**From tap to species identification in under 2 seconds.**

*BirdLens Mobile — Part of the BirdLens full-stack AI bird identification system*

</div>
