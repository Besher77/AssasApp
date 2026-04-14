/// Must match [COMMISSION_RATE] in `functions/index.js` (engineer share = 1 - rate).
const double kPlatformCommissionRate = 0.1;

/// Net amount the engineer receives after platform fee (2 decimal SAR rounding).
double engineerNetAfterCommission(double grossAmount) {
  if (grossAmount <= 0) return 0;
  return (grossAmount * (1 - kPlatformCommissionRate) * 100).round() / 100;
}

double platformCommissionOn(double grossAmount) {
  if (grossAmount <= 0) return 0;
  return (grossAmount * kPlatformCommissionRate * 100).round() / 100;
}
