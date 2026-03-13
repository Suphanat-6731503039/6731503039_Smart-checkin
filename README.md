# Smart Class App Flutter Project

An application for smart classroom management built with Flutter.

## Main Features
- Classroom check-in
- QR Code scanning
- QR Code generation
- Mood Selector
- Instructor dashboard
- Firebase integration for authentication and data management

## Project Structure
- `lib/` Main app code
  - `main.dart` App entry point
  - `login/` Login screen
  - `qrcode/` QR Code scanning and generation
  - `screens/` Various screens such as check-in, dashboard, finish screen
  - `services/` Firebase and location services
  - `widgets/` Reusable widgets
- `pubspec.yaml` Dependencies list
- `firebase.json` Firebase configuration
- `web/` For web app build

## Installation and Run
1. Install Flutter SDK
2. Run commands:
   ```
   flutter pub get
   flutter run
   ```
3. To build for web:
   ```
   flutter build web
   ```

## Firebase Integration
- Configure `firebase_options.dart` and `firebase.json`
- Use services in `services/auth_service.dart` and `services/firestore_service.dart`

## Usage Example
- Log in with user account
- Check in by scanning QR Code
- Select daily mood
- Instructor views data via dashboard

---

**Developer:**
- [Developer Name]

**License:** MIT
