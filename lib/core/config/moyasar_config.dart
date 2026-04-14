/// Moyasar payment gateway configuration.
/// Get your keys from https://dashboard.moyasar.com (sign up free)
///
/// For TESTING: Use pk_test_... (test cards work, no real charges)
/// For PRODUCTION: Use pk_live_... (requires Moyasar account activation)
/// Also set Cloud Function secret: firebase functions:config:set moyasar.secret_key="sk_test_xxx" or sk_live_xxx
/// For saved-card payments: firebase functions:config:set moyasar.callback_url="https://your-domain.com/callback" (required for 3DS)
class MoyasarConfig {
  MoyasarConfig._();

  /// Publishable API key - use pk_test_... for dev/testing, pk_live_... for production (requires activation)
  static const String publishableApiKey = String.fromEnvironment(
    'MOYASAR_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_mHzDD4YRuH2oj3NzJKZU6cKuS5iYCCYhkxeYN2up',
  );

  static bool get isConfigured =>
      publishableApiKey.isNotEmpty &&
      !publishableApiKey.contains('xxxxxxxx');
}

/// Moyasar test cards (sandbox only - no real charges)
/// Name: any 2+ words | Year: future | Month: future | CVC: any 3 digits
///
/// SUCCESS (paid):
///   Visa:        4111111111111111
///   Visa 3DS:    4111114005765430
///   Mastercard:  5421080101000000
///   Mada:        4201320111111010
///   Amex:        340000000900000
///
/// FAIL (for testing error handling):
///   Visa:        4123120000000000 (unspecified failure)
///   Visa:        4123120001090000 (insufficient funds)
class MoyasarTestCards {
  MoyasarTestCards._();
}
