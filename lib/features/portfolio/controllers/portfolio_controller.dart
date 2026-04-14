import 'package:get/get.dart';

import '../../../core/models/portfolio_item.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class PortfolioController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final items = <PortfolioItem>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  Future<void> loadItems() async {
    isLoading.value = true;
    try {
      final uid = _authService.currentUserId;
      if (uid != null) {
        items.value = await _firestore.getEngineerPortfolio(uid);
      } else {
        items.value = [];
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      items.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}
