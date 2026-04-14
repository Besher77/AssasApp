import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/engineer_specializations.dart';
import '../../../core/constants/saudi_cities.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/models/user_type.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestore = Get.find<FirestoreService>();
  final StorageService _storage = Get.find<StorageService>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final membershipController = TextEditingController();
  final experienceController = TextEditingController();
  final bioController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final user = Rxn<UserDocument>();
  final selectedCityId = ''.obs;
  final selectedSpecializationId = ''.obs;
  final userType = UserType.user.obs;
  final isEditMode = false.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final avatarPath = Rxn<String>();
  final walletBalance = 0.0.obs;
  File? _pickedImage;

  UserDocument? get userData => user.value;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    membershipController.dispose();
    experienceController.dispose();
    bioController.dispose();
    super.onClose();
  }

  String? validateCity(String? value) {
    if (value == null || value.isEmpty) return 'city_required'.tr;
    return null;
  }

  String? validateSpecialization(String? value) {
    if (userType.value == UserType.engineer && (value == null || value.isEmpty)) {
      return 'engineer_specialization_required'.tr;
    }
    return null;
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final uid = _authService.currentUserId;
      if (uid == null) return;

      final userDoc = await _firestore.getUser(uid);
      if (userDoc != null) {
        user.value = userDoc;
        _populateFromUser(userDoc);
      } else {
        _populateFromAuth();
      }
      final wallet = await _firestore.getOrCreateWallet(uid);
      walletBalance.value = wallet.balance;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _populateFromUser(UserDocument doc) {
    nameController.text = doc.name;
    phoneController.text = doc.phone.replaceFirst('966', '');
    emailController.text = doc.email ?? '';
    selectedCityId.value = saudiCities.any((c) => c.nameAr == doc.city || c.nameEn == doc.city)
        ? saudiCities.firstWhere((c) => c.nameAr == doc.city || c.nameEn == doc.city).id
        : '';
    userType.value = switch (doc.userType) {
      'engineer' => UserType.engineer,
      'admin' => UserType.admin,
      _ => UserType.user,
    };
    membershipController.text = doc.membershipNumber ?? '';
    experienceController.text = doc.yearsExperience ?? '';
    bioController.text = doc.bio ?? '';
    selectedSpecializationId.value = getSpecializationIdByValue(doc.specialization) ?? doc.specialization ?? '';
    avatarPath.value = doc.photoUrl;
  }

  void _populateFromAuth() {
    final authUser = _authService.currentUser;
    if (authUser != null) {
      nameController.text = authUser.displayName ?? '';
      phoneController.text = authUser.phoneNumber?.replaceAll(RegExp(r'\D'), '').replaceFirst('966', '') ?? '';
      emailController.text = authUser.email ?? '';
      avatarPath.value = authUser.photoURL;
    }
  }

  void toggleEditMode() {
    isEditMode.value = !isEditMode.value;
    if (!isEditMode.value) {
      user.value != null ? _populateFromUser(user.value!) : _populateFromAuth();
    }
  }

  Future<void> pickAvatar() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (xfile != null) {
        _pickedImage = File(xfile.path);
        avatarPath.value = xfile.path;
      }
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }

  String? validateRequired(String? value, String key) {
    if (value == null || value.trim().isEmpty) return key.tr;
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'login_phone_required'.tr;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9 || !digits.startsWith('5')) return 'phone_saudi_invalid'.tr;
    return null;
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;
    try {
      final uid = _authService.currentUserId;
      if (uid == null) throw AuthException('error_user_not_found'.tr);

      String? photoUrl = user.value?.photoUrl ?? _authService.currentUser?.photoURL;
      if (_pickedImage != null) {
        photoUrl = await _storage.uploadAvatar(uid, _pickedImage!);
      }

      final fullPhone = '966${phoneController.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '')}';

      final city = getCityNameById(selectedCityId.value);
      final fcm = Get.isRegistered<FcmService>() ? Get.find<FcmService>() : null;
      final prev = user.value;
      String? engReg;
      String? engNote;
      if (userType.value == UserType.engineer) {
        if (prev?.userType != 'engineer') {
          engReg = EngineerRegistrationStatus.pending;
          engNote = null;
        } else {
          engReg = prev?.engineerRegistrationStatus;
          engNote = prev?.engineerRegistrationNote;
        }
      }

      final userDoc = UserDocument(
        uid: uid,
        phone: fullPhone,
        name: nameController.text.trim(),
        city: city.isEmpty ? (prev?.city ?? '') : city,
        userType: userType.value.name,
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
        photoUrl: photoUrl,
        membershipNumber: userType.value == UserType.engineer ? membershipController.text.trim() : null,
        yearsExperience: userType.value == UserType.engineer ? experienceController.text.trim() : null,
        specialization: userType.value == UserType.engineer ? getSpecializationNameById(selectedSpecializationId.value) : null,
        bio: userType.value == UserType.engineer ? (bioController.text.trim().isEmpty ? null : bioController.text.trim()) : null,
        fcmToken: fcm?.fcmToken ?? prev?.fcmToken,
        createdAt: prev?.createdAt,
        payoutBankId: prev?.payoutBankId,
        payoutAccountName: prev?.payoutAccountName,
        payoutIban: prev?.payoutIban,
        payoutStatus: prev?.payoutStatus,
        payoutAdminMessage: prev?.payoutAdminMessage,
        payoutSubmittedAt: prev?.payoutSubmittedAt,
        blocked: prev?.blocked ?? false,
        suspendedUntil: prev?.suspendedUntil,
        blockedReason: prev?.blockedReason,
        engineerRegistrationStatus: engReg,
        engineerRegistrationNote: engNote,
      );

      await _firestore.createOrUpdateUser(userDoc);
      if (userType.value == UserType.user) {
        await _firestore.clearUserEngineerRegistrationFields(uid);
      }
      user.value = userDoc;
      isEditMode.value = false;
      Get.snackbar('', 'profile_saved'.tr);
    } on AuthException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    }
  }
}
