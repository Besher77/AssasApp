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
import '../../../core/services/storage_service.dart';

class ChatController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final StorageService _storage = Get.find<StorageService>();

  final messageController = TextEditingController();
  final messages = <MessageDocument>[].obs;
  final sendingImage = false.obs;
  final sendingFile = false.obs;

  /// Sending allowed only while project chat is open (status, listing, role).
  final canSendMessages = false.obs;

  /// Other party in chat (for presence: online / last seen).
  final otherUser = Rxn<UserDocument>();

  ProjectDocument? project;
  String? otherUserId;
  String? otherUserName;

  StreamSubscription<List<MessageDocument>>? _messagesSub;
  StreamSubscription<UserDocument?>? _presenceSub;
  StreamSubscription<ProjectDocument?>? _projectSub;
  Timer? _markReadDebounce;

  @override
  void onClose() {
    _messagesSub?.cancel();
    _presenceSub?.cancel();
    _projectSub?.cancel();
    _markReadDebounce?.cancel();
    messageController.dispose();
    super.onClose();
  }

  String? get currentUserId => _auth.currentUserId;

  bool isMe(String senderId) => senderId == currentUserId;

  /// True when the other participant is an engineer (tap opens engineer profile).
  bool get otherPartyIsEngineer {
    final id = otherUserId;
    if (id == null || id.isEmpty) return false;
    final u = otherUser.value;
    if (u != null) return u.userType == 'engineer';
    final p = project;
    final me = currentUserId;
    if (p == null || me == null) return false;
    if (p.userId == me) {
      return p.acceptedEngineerId == id || p.invitedEngineerId == id;
    }
    return false;
  }

  @override
  void onReady() {
    super.onReady();
    _applyChatGate();
    listenMessages();
    _listenOtherPresence();
    _listenProjectDoc();
    unawaited(_markDeliveredAndReadNow());
  }

  void _applyChatGate() {
    final p = project;
    final uid = currentUserId;
    if (p == null || uid == null) {
      canSendMessages.value = false;
      return;
    }
    canSendMessages.value = _firestore.isProjectChatOpenForUser(p, uid);
  }

  void _listenProjectDoc() {
    final pid = project?.id;
    if (pid == null || pid.isEmpty) return;
    _projectSub?.cancel();
    _projectSub = _firestore.streamProjectDocument(pid).listen((p) {
      if (p == null) {
        canSendMessages.value = false;
        return;
      }
      project = p;
      final uid = currentUserId;
      if (uid == null) {
        canSendMessages.value = false;
        return;
      }
      canSendMessages.value = _firestore.isProjectChatOpenForUser(p, uid);
    });
  }

  void listenMessages() {
    if (project == null) return;
    _messagesSub?.cancel();
    _messagesSub = _firestore.streamProjectMessages(project!.id).listen((list) {
      messages.value = list;
      _scheduleMarkDeliveredAndRead();
    });
  }

  void _listenOtherPresence() {
    _presenceSub?.cancel();
    final oid = otherUserId;
    if (oid == null || oid.isEmpty) {
      otherUser.value = null;
      return;
    }
    _presenceSub = _firestore.streamUser(oid).listen((u) => otherUser.value = u);
  }

  void _scheduleMarkDeliveredAndRead() {
    if (project == null || currentUserId == null) return;
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_markDeliveredAndReadNow());
    });
  }

  Future<void> _markDeliveredAndReadNow() async {
    if (project == null || currentUserId == null) return;
    try {
      await _firestore.markMessagesAsDelivered(project!.id, currentUserId!);
      await _firestore.markMessagesAsRead(project!.id, currentUserId!);
    } catch (_) {}
  }

  Future<void> sendMessage() async {
    if (!canSendMessages.value) {
      Get.snackbar('info'.tr, 'chat_read_only_hint'.tr);
      return;
    }
    final text = messageController.text.trim();
    if (text.isEmpty || project == null || currentUserId == null) return;
    try {
      await _firestore.sendMessage(
        project!.id,
        currentUserId!,
        text: text,
        receiverId: otherUserId,
      );
      messageController.clear();
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  Future<void> sendImage() async {
    if (!canSendMessages.value) {
      Get.snackbar('info'.tr, 'chat_read_only_hint'.tr);
      return;
    }
    if (project == null || currentUserId == null) return;
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
        currentUserId!,
        text: '',
        receiverId: otherUserId,
        type: MessageType.image,
        imageUrls: [url],
      );
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      sendingImage.value = false;
    }
  }

  Future<void> sendFile() async {
    if (!canSendMessages.value) {
      Get.snackbar('info'.tr, 'chat_read_only_hint'.tr);
      return;
    }
    if (project == null || currentUserId == null) return;
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
        currentUserId!,
        text: fileName,
        receiverId: otherUserId,
        type: MessageType.file,
        fileUrl: url,
        fileName: fileName,
      );
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      sendingFile.value = false;
    }
  }
}
