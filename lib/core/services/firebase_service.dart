import 'package:assas/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

/// Firebase initialization service
class FirebaseService extends GetxService {
  static Future<FirebaseService> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return FirebaseService();
    } catch (e) {
      // Avoid using Get.snackbar before runApp
      rethrow;
    }
  }
}
