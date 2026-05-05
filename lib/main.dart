import 'package:assas/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'core/routes/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_translations.dart';

/// FCM background handler - must be top-level, registered before runApp
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('FCM Background: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 1) تهيئة Firebase أول شيء
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 2) بعد التهيئة
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // ✅ 3) Crashlytics بعد Firebase
  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  // ✅ 4) باقي الخدمات
  await Get.putAsync(() => FirebaseService.init());

  try {
    await Get.putAsync(() => FcmService.init());
  } catch (e) {
    if (kDebugMode) debugPrint('FCM init error: $e');
  }

  Get.put(FirestoreService());
  Get.put(StorageService());
  Get.put(NotificationService());

  final settings = await Get.putAsync(() => SettingsService().init());
  await Get.putAsync(() => AuthService().init());

  Get.updateLocale(Locale(settings.locale.value));

  runZonedGuarded(() {
    runApp(const AsasApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class AsasApp extends StatefulWidget {
  const AsasApp({super.key});

  @override
  State<AsasApp> createState() => _AsasAppState();
}

class _AsasAppState extends State<AsasApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Get.isRegistered<AuthService>() || !Get.isRegistered<FirestoreService>()) return;
    final auth = Get.find<AuthService>();
    final uid = auth.currentUserId;
    if (uid == null) return;
    final firestore = Get.find<FirestoreService>();
    switch (state) {
      case AppLifecycleState.resumed:
        firestore.updateUserPresence(uid, isOnline: true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        firestore.updateUserPresence(uid, isOnline: false);
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    return Obx(
      () => SafeArea(
        child: GetMaterialApp(
          title: 'أساس',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeModeValue,
          locale: Locale(settings.locale.value),
          fallbackLocale: const Locale('ar'),
          translations: AppTranslations(),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.splash,
          getPages: AppRoutes.routes,
        ),
      ),
    );
  }
}
