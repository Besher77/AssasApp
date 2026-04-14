import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/models/message_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';

class AdminProjectSupportChatController extends GetxController {
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final AuthService _auth = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();
  final NotificationService _notif = Get.find<NotificationService>();

  final messageController = TextEditingController();
  final messages = <MessageDocument>[].obs;
  final sendingImage = false.obs;
  final sendingFile = false.obs;
  final engineerUser = Rxn<UserDocument>();
  final clientUser = Rxn<UserDocument>();
  final isLoading = true.obs;

  ProjectDocument? project;
  String? engineerId;
  String? clientId;

  StreamSubscription<List<MessageDocument>>? _messagesSub;
  StreamSubscription<UserDocument?>? _engineerSub;
  StreamSubscription<UserDocument?>? _clientSub;
  Timer? _markDebounce;

  String? get adminId => _auth.currentUserId;

  bool get canSend {
    final p = project;
    final e = engineerId;
    final a = adminId;
    if (p == null || e == null || e.isEmpty || a == null) return false;
    return supportChatEligible(p);
  }

  static bool supportChatEligible(ProjectDocument? p) {
    if (p == null) return false;
    final eng = p.acceptedEngineerId;
    if (eng == null || eng.isEmpty) return false;
    return p.status == 'in_progress' || p.status == 'delivered' || p.status == 'completed';
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    _engineerSub?.cancel();
    _clientSub?.cancel();
    _markDebounce?.cancel();
    messageController.dispose();
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    isLoading.value = true;
    final a = Get.arguments;
    if (a is ProjectDocument) {
      project = a;
    } else if (a is String && a.isNotEmpty) {
      project = await _firestore.getProject(a);
    }

    final p = project;
    if (p == null) {
      isLoading.value = false;
      Get.snackbar('error'.tr, 'admin_project_not_found'.tr);
      Get.back();
      return;
    }
    if (!supportChatEligible(p)) {
      isLoading.value = false;
      Get.snackbar('error'.tr, 'admin_support_chat_not_available'.tr);
      Get.back();
      return;
    }

    engineerId = p.acceptedEngineerId;
    if (engineerId == null || engineerId!.isEmpty) {
      isLoading.value = false;
      Get.snackbar('error'.tr, 'admin_support_chat_not_available'.tr);
      Get.back();
      return;
    }

    clientId = p.userId;
    _engineerSub = _firestore.streamUser(engineerId!).listen((u) => engineerUser.value = u);
    if (clientId != null && clientId!.isNotEmpty) {
      _clientSub = _firestore.streamUser(clientId!).listen((u) => clientUser.value = u);
    }
    _listenMessages();
    unawaited(_markDeliveredAndReadNow());
    isLoading.value = false;
  }

  void _listenMessages() {
    final pid = project?.id;
    if (pid == null || pid.isEmpty) return;
    _messagesSub?.cancel();
    _messagesSub = _firestore.streamProjectMessages(pid).listen((list) {
      messages.value = list;
      _scheduleMarkDeliveredAndRead();
    });
  }

  void _scheduleMarkDeliveredAndRead() {
    final aid = adminId;
    final pid = project?.id;
    if (aid == null || pid == null) return;
    _markDebounce?.cancel();
    _markDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_markDeliveredAndReadNow());
    });
  }

  Future<void> _markDeliveredAndReadNow() async {
    final aid = adminId;
    final pid = project?.id;
    if (aid == null || pid == null) return;
    try {
      await _firestore.markMessagesAsDelivered(pid, aid);
      await _firestore.markMessagesAsRead(pid, aid);
    } catch (_) {}
  }

  bool isFromAdmin(MessageDocument m) => m.senderId == adminId;

  bool showsAdminBadge(MessageDocument m) => m.adminSupport || m.adminSender;

  String? senderLabel(MessageDocument m) {
    if (m.senderId == adminId) return null;
    final cid = clientId;
    if (cid != null && m.senderId == cid) return 'chat_sender_client'.tr;
    final eid = engineerId;
    if (eid != null && m.senderId == eid) return 'chat_sender_engineer'.tr;
    return null;
  }

  bool canModerateMessage(MessageDocument m) => adminId != null;

  Future<void> confirmAndDeleteMessage(MessageDocument m) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text('admin_chat_delete_title'.tr),
        content: Text('admin_chat_delete_body'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          TextButton(onPressed: () => Get.back(result: true), child: Text('delete'.tr)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _firestore.deleteProjectMessage(m.id);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> editTextMessage(MessageDocument m) async {
    if (m.type != MessageType.text) return;
    final ctrl = TextEditingController(text: m.text);
    try {
      final submitted = await Get.dialog<bool>(
        AlertDialog(
          title: Text('admin_chat_edit_title'.tr),
          content: TextField(
            controller: ctrl,
            maxLines: 5,
            decoration: InputDecoration(hintText: 'type_message'.tr),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
            TextButton(onPressed: () => Get.back(result: true), child: Text('save'.tr)),
          ],
        ),
      );
      if (submitted != true) return;
      final next = ctrl.text.trim();
      if (next.isEmpty || next == m.text) return;
      await _firestore.updateProjectMessageText(m.id, next);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      ctrl.dispose();
    }
  }

  void onMessageLongPress(MessageDocument m) {
    if (!canModerateMessage(m)) return;
    Get.bottomSheet<void>(
      SafeArea(
        child: Wrap(
          children: [
            if (m.type == MessageType.text)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('edit'.tr),
                onTap: () {
                  Get.back<void>();
                  unawaited(editTextMessage(m));
                },
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade300),
              title: Text('delete'.tr, style: TextStyle(color: Colors.red.shade300)),
              onTap: () {
                Get.back<void>();
                unawaited(confirmAndDeleteMessage(m));
              },
            ),
          ],
        ),
      ),
      backgroundColor: Get.theme.cardColor,
    );
  }

  Future<void> sendMessage() async {
    if (!canSend) return;
    final text = messageController.text.trim();
    if (text.isEmpty || project == null || adminId == null) return;
    try {
      await _firestore.sendMessage(
        project!.id,
        adminId!,
        text: text,
        receiverId: engineerId,
        adminSender: true,
      );
      messageController.clear();
      final cid = clientId ?? project!.userId;
      unawaited(_notif.notifyProjectAdminChatMessage(
        projectId: project!.id,
        clientUserId: cid,
        engineerUserId: engineerId!,
      ));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> sendImage() async {
    if (!canSend || project == null || adminId == null) return;
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x == null) return;
      sendingImage.value = true;
      final file = File(x.path);
      final url = await _storage.uploadChatImage(project!.id, file);
      if (url == null) throw Exception('Upload failed');
      await _firestore.sendMessage(
        project!.id,
        adminId!,
        text: '',
        receiverId: engineerId,
        type: MessageType.image,
        imageUrls: [url],
        adminSender: true,
      );
      final cid = clientId ?? project!.userId;
      unawaited(_notif.notifyProjectAdminChatMessage(
        projectId: project!.id,
        clientUserId: cid,
        engineerUserId: engineerId!,
      ));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      sendingImage.value = false;
    }
  }

  Future<void> sendFile() async {
    if (!canSend || project == null || adminId == null) return;
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final platformFile = result.files.single;
      final path = platformFile.path;
      if (path == null) {
        Get.snackbar('error'.tr, 'File path not available');
        return;
      }
      sendingFile.value = true;
      final file = File(path);
      final fileName = platformFile.name;
      final url = await _storage.uploadChatFile(project!.id, fileName, file);
      if (url == null) throw Exception('Upload failed');
      await _firestore.sendMessage(
        project!.id,
        adminId!,
        text: fileName,
        receiverId: engineerId,
        type: MessageType.file,
        fileUrl: url,
        fileName: fileName,
        adminSender: true,
      );
      final cid = clientId ?? project!.userId;
      unawaited(_notif.notifyProjectAdminChatMessage(
        projectId: project!.id,
        clientUserId: cid,
        engineerUserId: engineerId!,
      ));
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      sendingFile.value = false;
    }
  }
}
