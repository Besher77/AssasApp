import 'package:get/get.dart';

import 'app_ar.dart';
import 'app_en.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': AppEn.translations,
        'ar': AppAr.translations,
      };
}
