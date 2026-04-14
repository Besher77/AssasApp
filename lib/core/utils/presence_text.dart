import 'package:get/get.dart';

/// Localized "online" / "last seen …" for chat header and profiles.
String presenceSubtitle({required bool isOnline, DateTime? lastSeen}) {
  if (isOnline) return 'online'.tr;
  if (lastSeen == null) return '';
  final now = DateTime.now();
  final diff = now.difference(lastSeen);
  if (diff.isNegative) return 'last_seen_just_now'.tr;
  if (diff < const Duration(minutes: 1)) return 'last_seen_just_now'.tr;
  if (diff < const Duration(hours: 1)) {
    final m = diff.inMinutes.clamp(1, 59);
    return 'last_seen_minutes'.trParams({'n': '$m'});
  }
  if (diff < const Duration(hours: 24)) {
    final h = diff.inHours.clamp(1, 23);
    return 'last_seen_hours'.trParams({'n': '$h'});
  }
  if (diff < const Duration(days: 7)) {
    final d = diff.inDays.clamp(1, 6);
    return 'last_seen_days'.trParams({'n': '$d'});
  }
  return 'last_seen_long'.trParams({
    'date':
        '${lastSeen.year}-${lastSeen.month.toString().padLeft(2, '0')}-${lastSeen.day.toString().padLeft(2, '0')}',
  });
}
