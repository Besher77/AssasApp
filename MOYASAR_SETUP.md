# Moyasar Card Payment Setup

## 1. Get API Keys

1. Sign up at [moyasar.com](https://moyasar.com) (free)
2. Go to [Dashboard → API Keys](https://dashboard.moyasar.com)
3. Copy your **Test** keys:
   - **Publishable:** `pk_test_...` (for the app)
   - **Secret:** `sk_test_...` (for Cloud Functions)

## 2. Configure the App

**Option A – Edit config file:**
Open `lib/core/config/moyasar_config.dart` and replace:
```dart
defaultValue: 'pk_test_xxxxxxxxxxxxxxxxxxxxxxxx',
```
with your key:
```dart
defaultValue: 'pk_test_YOUR_ACTUAL_KEY_HERE',
```

**Option B – Use dart-define:**
```bash
flutter run --dart-define=MOYASAR_PUBLISHABLE_KEY=pk_test_YOUR_KEY
```

## 3. Configure Cloud Functions

```bash
firebase functions:config:set moyasar.secret_key="sk_test_YOUR_SECRET_KEY"
firebase deploy --only functions
```

## 4. Test Cards (Sandbox – no real charges)

Use any name (2+ words), future expiry, and any 3-digit CVC.

### Success (paid)

| Card Type | Number |
|-----------|--------|
| Visa | `4111111111111111` |
| Visa (3DS) | `4111114005765430` |
| Mastercard | `5421080101000000` |
| Mada | `4201320111111010` |
| Amex | `340000000900000` |

### Failure (for testing errors)

| Scenario | Card Number |
|----------|-------------|
| Unspecified failure | `4123120000000000` |
| Insufficient funds | `4123120001090000` |
| Declined | `4123120001090109` |
| Lost card | `4123450131000508` |
| Expired card | `4123128518640738` |
