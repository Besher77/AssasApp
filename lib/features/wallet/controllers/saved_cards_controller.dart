import 'package:get/get.dart';

import '../../../core/models/saved_card_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class SavedCardsController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final cards = <SavedCardDocument>[].obs;
  final isLoading = true.obs;

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    final uid = _auth.currentUserId;
    if (uid == null) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      cards.value = await _firestore.getSavedCards(uid);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteCard(SavedCardDocument card) async {
    final uid = _auth.currentUserId;
    if (uid == null) return;
    try {
      await _firestore.deleteSavedCard(uid, card.id);
      cards.remove(card);
      Get.snackbar('', 'card_removed'.tr);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }
}
