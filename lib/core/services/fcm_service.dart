import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'firestore_service.dart';

/// Firebase Cloud Messaging service
class FcmService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<FcmService> init() async {
    final service = FcmService();
    await service._setup();
    return service;
  }

  Future<void> _setup() async {
    // Request notification permission on both iOS and Android 13+
    final settings = await _requestPermission();
    if (Platform.isIOS &&
        settings?.authorizationStatus != AuthorizationStatus.authorized &&
        settings?.authorizationStatus != AuthorizationStatus.provisional) {
      if (kDebugMode) debugPrint('FCM: iOS notification permission denied');
      return;
    }
    _setupForegroundHandlers();
    _setupTokenRefreshListener();
    _checkInitialMessage();
    await _getToken();
    await _subscribeToTopics();
  }

  Future<void> _checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      _handleNotificationTap(message.data);
    }
  }

  /// Request notification permission. On iOS shows alert; on Android 13+ shows POST_NOTIFICATIONS dialog.
  Future<NotificationSettings?> _requestPermission() async {
    try {
      if (Platform.isIOS) {
        return await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      // Android 13+ requires runtime permission for notifications
      return await _messaging.requestPermission();
    } catch (e) {
      if (kDebugMode) debugPrint('FCM requestPermission error: $e');
      return null;
    }
  }

  /// Call to explicitly request permission (e.g. from settings or after login)
  Future<bool> requestNotificationPermission() async {
    final settings = await _requestPermission();
    if (settings == null) return false;
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> _getToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (kDebugMode && _fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
      }
      _syncTokenToFirestoreIfLoggedIn();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM getToken error: $e');
      }
    }
  }

  /// Sync FCM token to Firestore when user is logged in (for Cloud Functions to send push)
  Future<void> _syncTokenToFirestoreIfLoggedIn() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _fcmToken == null) return;
    if (!Get.isRegistered<FirestoreService>()) return;
    try {
      await Get.find<FirestoreService>().updateFcmToken(uid, _fcmToken);
      if (kDebugMode) debugPrint('FCM: Token synced to Firestore for user $uid');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM sync token error: $e');
    }
  }

  /// Call to force sync token (e.g. when user logs in)
  Future<void> syncTokenToFirestore() async {
    await _syncTokenToFirestoreIfLoggedIn();
  }

  Future<void> _subscribeToTopics() async {
    try {
      await _messaging.subscribeToTopic('all_users');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM subscribe error: $e');
      }
    }
  }

  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((String newToken) {
      _fcmToken = newToken;
      if (kDebugMode) debugPrint('FCM Token refreshed');
      _syncTokenToFirestoreIfLoggedIn();
    });
  }

  void _setupForegroundHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('FCM Foreground: ${message.notification?.title}');
      }
      Get.snackbar(
        message.notification?.title ?? 'Notification',
        message.notification?.body ?? '',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('FCM Opened: ${message.data}');
      }
      _handleNotificationTap(message.data);
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    final projectId = data['projectId'] as String?;
    final type = data['type'] as String?;

    if ((type == 'chat' || type == 'project_invitation') &&
        projectId != null &&
        projectId.isNotEmpty) {
      Get.toNamed('/chat-project', arguments: projectId);
    } else if (route == '/project-detail' && projectId != null && projectId.isNotEmpty) {
      Get.toNamed('/project-detail', arguments: projectId);
    } else if (route != null && route.isNotEmpty) {
      Get.toNamed(route);
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM subscribe error: $e');
      }
    }
  }

  /// Call when user logs in - save token to Firestore
  Future<void> onUserLogin(String userId) async {
    await _subscribeToTopic('user_$userId');
  }

  /// Call when user logs out
  Future<void> onUserLogout() async {
    await _messaging.deleteToken();
  }
}
