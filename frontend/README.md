# Frontend (Flutter)

This folder is now a Flutter app for web and mobile that replaces the prior Next.js frontend.

## Run

```bash
flutter pub get
flutter run
```

## Configure backend URLs

Defaults:
- API: `http://localhost:8000`
- Socket: `http://localhost:8000`

Override via Dart defines:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 --dart-define=WS_BASE_URL=http://localhost:8000
```

## Included flows

- Create room
- Join room
- Add up to 4 suggestions
- Start voting with geolocation (host)
- Live room updates via Socket.IO
- Vote and show winner/results
- Restart session

## Location permission flow

- Permission request is triggered when host taps **Start voting**
- App stores two local flags in SharedPreferences:
  - `locationPermissionPrompted`
  - `locationPermissionGranted`
- If denied, the app shows guidance plus:
  - **Settings** action
  - **Continue with demo location** fallback
