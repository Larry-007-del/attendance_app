# Attendance App

A Flutter mobile app connected to Django REST backend.

## Features
- JWT authentication with Django REST API
- View courses
- Mark attendance with GPS location
- Session persistence

## Setup

1. **Install Flutter** (3.0+):
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Build APK**:
   ```bash
   flutter build apk --debug
   ```

## API Configuration

Edit `lib/main.dart` to change the API endpoint:
```dart
const String API_BASE = 'https://attendance-system-backend-z1wl.onrender.com';
```

## Demo Credentials
- Username: `Gygas`
- Password: `ptolemy123`

## Project Structure
```
lib/
  main.dart          # Main app with login, home, and attendance
android/             # Android configuration with location permissions
pubspec.yaml        # Dependencies
```

## Dependencies
- `http` - API calls
- `shared_preferences` - Token storage
- `geolocator` - GPS location
- `get` - State management
