import 'package:get/get.dart';

import '../../../core/models/message_document.dart' show MessageDocument, MessageType;
import '../../../core/models/project_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';

class ChatListItem {
  ChatListItem({
    required this.project,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final ProjectDocument project;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final MessageDocument? lastMessage;
  final int unreadCount;
}

class ChatsListController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();

  final items = <ChatListItem>[].obs;
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
      final projects = await _firestore.getChatProjects(uid);
      final list = <ChatListItem>[];
      for (final project in projects) {
        String? otherUserId;
        String? otherUserName;
        String? otherUserPhotoUrl;
        if (project.userId == uid) {
          final offer = await _firestore.getAcceptedOfferForProject(project.id);
          otherUserId = offer?.engineerId ?? project.invitedEngineerId;
          if (otherUserId != null) {
            if (offer != null) {
              otherUserName = offer.engineerName;
              otherUserPhotoUrl = offer.engineerPhotoUrl;
            } else {
              final eng = await _firestore.getUser(otherUserId);
              otherUserName = eng?.name;
              otherUserPhotoUrl = eng?.photoUrl;
            }
          }
        } else {
          otherUserId = project.userId;
          final owner = await _firestore.getUser(project.userId);
          otherUserName = owner?.name;
          otherUserPhotoUrl = owner?.photoUrl;
        }
        if (otherUserId == null) continue;
        final lastMessage = await _firestore.getLastMessage(project.id);
        final unreadCount = await _firestore.getProjectUnreadCount(project.id, uid);
        list.add(ChatListItem(
          project: project,
          otherUserId: otherUserId,
          otherUserName: otherUserName ?? 'chat'.tr,
          otherUserPhotoUrl: otherUserPhotoUrl,
          lastMessage: lastMessage,
          unreadCount: unreadCount,
        ));
      }
      list.sort((a, b) {
        final aTime = a.lastMessage?.createdAt ?? a.project.createdAt ?? DateTime(0);
        final bTime = b.lastMessage?.createdAt ?? b.project.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });
      items.value = list;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String getLastMessagePreview(MessageDocument? msg) {
    if (msg == null) return '';
    if (msg.type == MessageType.image) return '📷 ${'image'.tr}';
    if (msg.type == MessageType.file) return '📎 ${msg.fileName ?? 'file'.tr}';
    return msg.text;
  }
}
