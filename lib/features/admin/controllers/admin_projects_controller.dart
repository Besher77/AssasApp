import 'dart:async';

import 'package:get/get.dart';

import '../../../core/constants/project_options.dart';
import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart';
import '../../../core/models/project_document.dart';
import '../../../core/services/firestore_service.dart';
import 'admin_project_support_chat_controller.dart';

class AdminProjectsController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final projects = <ProjectDocument>[].obs;
  final userNameById = <String, String>{}.obs;
  final searchQuery = ''.obs;
  StreamSubscription<List<ProjectDocument>>? _sub;

  List<ProjectDocument> get supportChatProjects =>
      List<ProjectDocument>.of(projects).where(AdminProjectSupportChatController.supportChatEligible).toList();

  String displayNameForUserId(String uid) {
    if (uid.isEmpty) return '—';
    return userNameById[uid] ?? '…';
  }

  List<ProjectDocument> get filteredProjects {
    final q = searchQuery.value.trim().toLowerCase();
    final base = List<ProjectDocument>.of(projects);
    if (q.isEmpty) return base;
    return base.where((p) => _projectMatchesSearch(p, q)).toList();
  }

  List<ProjectDocument> get filteredSupportProjects {
    final q = searchQuery.value.trim().toLowerCase();
    final base = supportChatProjects;
    if (q.isEmpty) return base;
    return base.where((p) => _projectMatchesSearch(p, q)).toList();
  }

  bool _projectMatchesSearch(ProjectDocument p, String q) {
    if (p.id.toLowerCase().contains(q)) return true;
    if (p.description.toLowerCase().contains(q)) return true;
    if (p.userId.toLowerCase().contains(q)) return true;
    if ((p.acceptedEngineerId ?? '').toLowerCase().contains(q)) return true;
    if ((p.invitedEngineerId ?? '').toLowerCase().contains(q)) return true;
    if (getCityNameById(p.city).toLowerCase().contains(q)) return true;
    if (getProjectTypeNameById(p.projectType).toLowerCase().contains(q)) return true;
    if (getProjectStatusNameById(p.status).toLowerCase().contains(q)) return true;
    if (_name(p.userId).contains(q)) return true;
    if ((p.acceptedEngineerId ?? '').isNotEmpty && _name(p.acceptedEngineerId!).contains(q)) return true;
    if ((p.invitedEngineerId ?? '').isNotEmpty && _name(p.invitedEngineerId!).contains(q)) return true;
    return false;
  }

  String _name(String uid) => (userNameById[uid] ?? '').toLowerCase();

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _hydrateUserNames(List<ProjectDocument> list) async {
    final ids = <String>{};
    for (final p in list) {
      if (p.userId.isNotEmpty) ids.add(p.userId);
      final a = p.acceptedEngineerId;
      if (a != null && a.isNotEmpty) ids.add(a);
      final i = p.invitedEngineerId;
      if (i != null && i.isNotEmpty) ids.add(i);
    }
    for (final id in ids) {
      if (userNameById.containsKey(id)) continue;
      try {
        final u = await _firestore.getUser(id);
        userNameById[id] =
            u != null && u.name.trim().isNotEmpty ? u.name.trim() : 'admin_unknown_user'.tr;
        userNameById.refresh();
      } catch (_) {
        userNameById[id] = '—';
        userNameById.refresh();
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    _sub = _firestore.streamProjectsForAdmin().listen(
      (list) {
        projects.value = list;
        unawaited(_hydrateUserNames(list));
      },
      onError: (e) => Get.snackbar('error'.tr, e.toString()),
    );
  }
}
