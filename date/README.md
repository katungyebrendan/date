# Velo

Velo is a Flutter dating app: sign up, build a profile, swipe to discover
people nearby, match, and chat in real time. The backend is Firebase
(Authentication, Firestore, Storage).

## Status

The app is fully built and compiles/runs — but it ships with **placeholder**
Firebase credentials (`lib/firebase_options.dart`). You must connect your own
Firebase project before sign-up, matching, or chat will actually work. Until
then, the UI runs and navigates normally, but Firebase calls will fail.

## One-time setup

1. **Install the Firebase CLI and FlutterFire CLI** (if you don't have them):
   ```
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

2. **Log in and configure Firebase for this app**:
   ```
   firebase login
   flutterfire configure
   ```
   - Pick an existing Firebase project or create a new one.
   - When asked which platforms to configure, select the ones you plan to
     ship (Android, iOS, Web at minimum).
   - When asked for the Android package name / iOS bundle ID, use
     `com.kats.velo` for both, to match what's already set in this project
     (`android/app/build.gradle.kts`, `ios/Runner.xcodeproj`) and the
     `android/app/google-services.json` already registered under that
     package name. If you pick a different identifier, update those files
     to match instead.
   - This regenerates `lib/firebase_options.dart` with real values (and, for
     Android, should match the `google-services.json` already in place).

3. **Enable the backend services in the Firebase Console**:
   - **Authentication** → Sign-in method → enable **Email/Password**.
   - **Firestore Database** → create a database (Native mode, pick a region).
   - **Storage** → get started (creates the default bucket).

4. **Deploy the security rules** in this repo:
   ```
   firebase deploy --only firestore:rules,storage:rules
   ```
   (`firestore.rules` and `storage.rules` at the repo root, wired up via
   `firebase.json`.)

5. **Run the app**:
   ```
   flutter pub get
   flutter run
   ```

## What's implemented

- Email/password auth (sign up, sign in, sign out)
- Onboarding: name, birthdate (18+ gate), gender + preference, bio, up to 6
  photos, city (manual entry, or "use my current location" autofill)
- Discovery swipe deck (like / pass / super-like, buttons and drag gestures)
- Matching (mutual-like detection via a Firestore transaction) with a match
  celebration screen
- Matches list and real-time chat per match
- Profile view/edit (including photo management) and settings (sign out,
  delete profile data)

### Known MVP limitations (by design, not bugs)

- **Account deletion** removes the Firestore profile and Storage photos, but
  not the underlying Firebase Auth account (that needs a re-authentication
  flow, which is a stretch item beyond this pass).
- **Candidate discovery** filters and excludes already-swiped users
  client-side; this is fine for small user bases but should move to a Cloud
  Function or a search index (e.g. Algolia) at scale.
- **Matching** is done via a client-side Firestore transaction rather than a
  Cloud Function trigger — simpler for MVP, but a Cloud Function is the more
  robust production approach (also lets you tighten security rules further,
  since clients currently need read access to each other's swipe docs).
- No Google Sign-In, push notifications, or in-app purchases — noted as
  future ideas, not implemented here.

## Project structure

See `lib/`: `models/` (data classes), `services/` (Firebase SDK wrappers —
the only place that talks to Firebase directly), `providers/` (Riverpod
providers gluing services to the UI), `routing/` (go_router setup with
auth-gated redirects), `screens/` (one folder per feature), `theme/`, and
`widgets/` (shared UI).

## Verifying without a Firebase project

- `flutter analyze` — should be clean.
- `flutter build web` (or `flutter build windows`) — proves the app,
  including all Firebase imports and the placeholder options, compiles.
- `flutter run -d chrome` — the UI (splash, sign-in/up, theme, navigation)
  renders; any real Firebase call will error until you complete the setup
  steps above.
