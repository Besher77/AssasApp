import 'dart:async';

import 'package:get/get.dart';

import '../../../core/models/admin_dashboard_stats.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class AdminHomeController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final adminName = ''.obs;
  final isLoading = true.obs;
  final pendingWithdrawalsCount = 0.obs;
  final pendingBankVerificationsCount = 0.obs;
  final pendingEngineerRegistrationsCount = 0.obs;

  final dashboardStats = Rxn<AdminDashboardStats>();
  final dashboardStatsLoading = false.obs;

  StreamSubscription<int>? _withdrawalsCountSub;
  StreamSubscription<int>? _bankCountSub;
  StreamSubscription<int>? _engineerRegCountSub;

  @override
  void onClose() {
    _withdrawalsCountSub?.cancel();
    _bankCountSub?.cancel();
    _engineerRegCountSub?.cancel();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _withdrawalsCountSub = _firestore.streamPendingWithdrawalRequestCount().listen(
      (n) => pendingWithdrawalsCount.value = n,
    );
    _bankCountSub = _firestore.streamPendingPayoutVerificationCount().listen(
      (n) => pendingBankVerificationsCount.value = n,
    );
    _engineerRegCountSub = _firestore.streamPendingEngineerRegistrationCount().listen(
      (n) => pendingEngineerRegistrationsCount.value = n,
    );
    unawaited(_loadThenDashboardStats());
  }

  Future<void> refreshDashboardStats() async {
    dashboardStatsLoading.value = true;
    try {
      dashboardStats.value = await _firestore.fetchAdminDashboardStats();
    } catch (_) {
      dashboardStats.value = null;
    } finally {
      dashboardStatsLoading.value = false;
    }
  }

  Future<void> _loadThenDashboardStats() async {
    await _load();
    await refreshDashboardStats();
  }

  Future<void> _load() async {
    final uid = _auth.currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      final doc = await _firestore.getUser(uid);
      adminName.value = doc?.name ?? '';
      if (doc?.userType != 'admin') {
        Get.offAllNamed(AppRoutes.home);
        return;
      }
    } catch (_) {
      Get.offAllNamed(AppRoutes.home);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
