import 'package:get/get.dart';

/// User type for signup/onboarding (admin is set in Firestore only, not via signup UI).
enum UserType {
  user,
  engineer,
  admin,
}

extension UserTypeExtension on UserType {
  String get tr {
    switch (this) {
      case UserType.user:
        return 'user_type_user'.tr;
      case UserType.engineer:
        return 'user_type_engineer'.tr;
      case UserType.admin:
        return 'user_type_admin'.tr;
    }
  }
}
