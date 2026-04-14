# Firebase Setup Guide for أساس (Assas)

## Prerequisites
- Firebase project created at [Firebase Console](https://console.firebase.google.com)
- Flutter project with `firebase_options.dart` (run `dart run flutterfire_cli configure` if needed)

## Configured Features

### 1. Firebase Authentication
- **Phone (OTP)**: Saudi numbers (+966) - SMS verification via Firebase
- **Google Sign-In**: Configure in Firebase Console > Authentication > Sign-in method
- **Apple Sign-In**: Configure in Firebase Console + Apple Developer account

### 2. Cloud Firestore
- **Collections**: `users/{userId}`, `projects/{projectId}`, `portfolio_items/{itemId}`
- **Security rules**: See `firestore.rules` - deploy with `firebase deploy --only firestore:rules`
- **Indexes**: For projects query (userId + createdAt), run `firebase deploy --only firestore:indexes` or create index via Firebase Console when prompted

### 3. Firebase Storage
- **Paths**: `avatars/{userId}.jpg`, `projects/{projectId}/{index}.jpg`
- **Security rules**: See `storage.rules` - deploy with `firebase deploy --only storage`
- **Enable Storage**: In Firebase Console > Build > Storage > Get started

### 4. App Check (optional, for Storage)
- Reduces "No AppCheckProvider" warnings
- Debug provider used in development
- Run app, copy debug token from logcat, register in Firebase Console > App Check > Debug tokens

### 5. FCM (Push Notifications)
- Foreground/background message handling
- Topic subscription: `all_users`, `user_{userId}`

## Android Setup
1. Add `google-services.json` to `android/app/`
2. Ensure `minSdkVersion` >= 21 in `android/app/build.gradle.kts`
3. For Google Sign-In: Add SHA-1 in Firebase Console > Project Settings

## iOS Setup
1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Enable Sign in with Apple capability in Xcode
3. Add Push Notifications capability
4. Configure URL schemes for Google Sign-In

## Deploy Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

## Error Handling
All Firebase errors are mapped to user-friendly Arabic/English messages in `lib/core/errors/firebase_auth_errors.dart`.
