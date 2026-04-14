import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/engineer_specializations.dart';
import '../../../core/constants/saudi_cities.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/models/user_type.dart';
import '../../../core/services/auth_service.dart';

class SignupController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final selectedCityId = ''.obs;

  String get fullPhone {
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    return '966$digits';
  }
  final membershipController = TextEditingController();
  final experienceController = TextEditingController();
  final bioController = TextEditingController();
  final selectedSpecializationId = ''.obs;
  final formKey = GlobalKey<FormState>();

  final userType = UserType.user.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['prefillPhone'] != null) {
      var digits =
          args['prefillPhone'].toString().replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
      if (digits.startsWith('966')) digits = digits.substring(3);
      if (digits.isNotEmpty) phoneController.text = digits;
    }
  }

  String get cityName => getCityNameById(selectedCityId.value);
  String get specializationName => getSpecializationNameById(selectedSpecializationId.value);

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    membershipController.dispose();
    experienceController.dispose();
    bioController.dispose();
    super.onClose();
  }

  void setUserType(UserType type) => userType.value = type;

  String? validateRequired(String? value, String key) {
    if (value == null || value.trim().isEmpty) {
      return key.tr;
    }
    return null;
  }

  String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'city_required'.tr;
    }
    return null;
  }

  String? validateSpecialization(String? value) {
    if (value == null || value.isEmpty) {
      return 'engineer_specialization_required'.tr;
    }
    return null;
  }

  Future<void> signup() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final verificationId = await _authService.sendOtp(fullPhone);
      Get.offAllNamed('/otp', arguments: {
        'phone': fullPhone,
        'verificationId': verificationId,
        'isSignup': true,
        'userType': userType.value,
        'name': nameController.text.trim(),
        'city': cityName,
        'membershipNumber': userType.value == UserType.engineer
            ? membershipController.text.trim()
            : null,
        'yearsExperience': userType.value == UserType.engineer
            ? experienceController.text.trim()
            : null,
        'specialization': userType.value == UserType.engineer
            ? specializationName
            : null,
        'bio': userType.value == UserType.engineer
            ? (bioController.text.trim().isEmpty ? null : bioController.text.trim())
            : null,
      });
    } on AuthException catch (e) {
      Get.snackbar('error'.tr, e.message);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
