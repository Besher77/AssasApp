import 'package:get/get.dart';

import '../../../core/constants/engineer_specializations.dart';
import '../../../core/services/firestore_service.dart';

/// Engineer card data for home list
class EngineerCardData {
  EngineerCardData({
    required this.user,
    required this.rating,
    this.minPrice,
  });

  final UserDocument user;
  final double rating;
  final double? minPrice;
}

class BrowseEngineersController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final engineers = <EngineerCardData>[].obs;
  final isLoading = true.obs;
  final searchQuery = ''.obs;
  /// Selected specialization (major) id for filtering
  final selectedSpecializationId = Rxn<String>();

  @override
  void onReady() {
    super.onReady();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final users =
          (await _firestore.getEngineers()).where((u) => u.isVisibleAsEngineerInBrowse).toList();
      final cards = <EngineerCardData>[];
      for (final u in users) {
        final rating = await _firestore.getEngineerAverageRating(u.uid);
        final minPrice = await _firestore.getEngineerMinOfferPrice(u.uid);
        cards.add(EngineerCardData(user: u, rating: rating, minPrice: minPrice));
      }
      engineers.value = cards;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void setSearch(String query) {
    searchQuery.value = query.trim().toLowerCase();
  }

  void setSpecialization(String? specializationId) {
    selectedSpecializationId.value = specializationId;
  }

  List<EngineerCardData> get filteredEngineers {
    var list = engineers.toList();
    if (searchQuery.value.isNotEmpty) {
      list = list
          .where((e) =>
              e.user.name.toLowerCase().contains(searchQuery.value) ||
              (e.user.specialization?.toLowerCase().contains(searchQuery.value) ?? false) ||
              (e.user.city.toLowerCase().contains(searchQuery.value)))
          .toList();
    }
    if (selectedSpecializationId.value != null && selectedSpecializationId.value!.isNotEmpty) {
      final specId = selectedSpecializationId.value!;
      list = list.where((e) {
        final engineerSpecId = getSpecializationIdByValue(e.user.specialization);
        return engineerSpecId == specId;
      }).toList();
    }
    return list;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedSpecializationId.value = null;
  }
}
