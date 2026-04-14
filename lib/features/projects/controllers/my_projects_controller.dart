import 'package:get/get.dart';

import '../../../core/models/project_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class MyProjectsController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final projects = <ProjectDocument>[].obs;
  final isLoading = true.obs;
  final selectedTabIndex = 0.obs;
  final isEngineer = false.obs;

  static const _inProgressStatuses = ['new', 'in_progress'];
  static const _completeStatuses = ['delivered', 'completed'];
  /// Statuses that mean project is taken by an engineer (exclude from "All" for user)
  static const _takenStatuses = ['in_progress', 'delivered', 'completed'];

  List<ProjectDocument> get inProgressProjects =>
      projects.where((p) => _inProgressStatuses.contains(p.status)).toList();

  List<ProjectDocument> get completeProjects =>
      projects.where((p) => _completeStatuses.contains(p.status)).toList();

  List<ProjectDocument> get displayedProjects {
    switch (selectedTabIndex.value) {
      case 1:
        return inProgressProjects;
      case 2:
        return completeProjects;
      default:
        // User "All" tab: only show projects not completed and not taken by another engineer
        if (!isEngineer.value) {
          return projects
              .where((p) => !_takenStatuses.contains(p.status))
              .toList();
        }
        return projects;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  void selectTab(int index) {
    selectedTabIndex.value = index;
  }

  Future<void> loadProjects() async {
    isLoading.value = true;
    try {
      final uid = _authService.currentUserId;
      if (uid != null) {
        final userDoc = await _firestore.getUser(uid);
        isEngineer.value = userDoc?.userType == 'engineer';
        projects.value = isEngineer.value
            ? await _firestore.getEngineerProjects(uid)
            : await _firestore.getUserProjects(uid);
      } else {
        projects.value = [];
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      projects.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}
