import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class StorageService extends GetxService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadAvatar(String userId, File file) async {
    try {
      final ref = _storage.ref().child('avatars/$userId.jpg');
      final bytes = await file.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadAvatar: $e');
      rethrow;
    }
  }

  Future<String?> uploadPortfolioImage(String engineerId, String itemId, int index, File file) async {
    try {
      final ref = _storage.ref().child('portfolios/$engineerId/$itemId/$index.jpg');
      final bytes = await file.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadPortfolioImage: $e');
      rethrow;
    }
  }

  Future<String?> uploadProjectImage(String projectId, int index, File file) async {
    try {
      final ref = _storage.ref().child('projects/$projectId/$index.jpg');
      final bytes = await file.readAsBytes();
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadProjectImage: $e');
      rethrow;
    }
  }

  /// Upload project file (PDF, DWG, etc.). Returns download URL.
  Future<String?> uploadProjectFile(String projectId, String fileName, File file) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
      final ref = _storage.ref().child('projects/$projectId/files/${ts}_$safeName');
      final bytes = await file.readAsBytes();
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadProjectFile: $e');
      rethrow;
    }
  }

  /// Upload chat image. Returns download URL.
  Future<String?> uploadChatImage(String projectId, File file) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : ext == 'gif'
              ? 'image/gif'
              : 'image/jpeg';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('chat/$projectId/$ts.$ext');
      final bytes = await file.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadChatImage: $e');
      rethrow;
    }
  }

  /// Upload offer image. Returns download URL. Uses projectId for path (offer created after upload).
  Future<String?> uploadOfferImage(String projectId, int index, File file) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : ext == 'gif' ? 'image/gif' : 'image/jpeg';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('offers/$projectId/${ts}_$index.$ext');
      final bytes = await file.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadOfferImage: $e');
      rethrow;
    }
  }

  /// Upload offer file. Returns download URL.
  Future<String?> uploadOfferFile(String projectId, String fileName, File file) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
      final ref = _storage.ref().child('offers/$projectId/${ts}_$safeName');
      final bytes = await file.readAsBytes();
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadOfferFile: $e');
      rethrow;
    }
  }

  /// Upload chat audio. Returns download URL.
  Future<String?> uploadChatAudio(String projectId, String fileName, File file) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
      final ref = _storage.ref().child('chat/$projectId/${ts}_$safeName');
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final contentType = ext == 'm4a'
          ? 'audio/mp4'
          : ext == 'mp3'
              ? 'audio/mpeg'
              : ext == 'wav'
                  ? 'audio/wav'
                  : 'audio/mp4';
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadChatAudio: $e');
      rethrow;
    }
  }

  /// Upload chat file. Returns download URL.
  Future<String?> uploadChatFile(String projectId, String fileName, File file) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\-\.]'), '_');
      final ref = _storage.ref().child('chat/$projectId/${ts}_$safeName');
      final bytes = await file.readAsBytes();
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) debugPrint('StorageService.uploadChatFile: $e');
      rethrow;
    }
  }
}
