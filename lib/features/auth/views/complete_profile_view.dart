import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/user_type.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/complete_profile_controller.dart';

class CompleteProfileView extends GetView<CompleteProfileController> {
  const CompleteProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'complete_profile'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'complete_profile_subtitle'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'select_user_type'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _UserTypeCard(
                          type: UserType.user,
                          isSelected: controller.userType.value == UserType.user,
                          onTap: () => controller.setUserType(UserType.user),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _UserTypeCard(
                          type: UserType.engineer,
                          isSelected: controller.userType.value == UserType.engineer,
                          onTap: () => controller.setUserType(UserType.engineer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AsasTextField(
                  controller: controller.nameController,
                  hintText: 'name'.tr,
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                  validator: (v) => controller.validateRequired(v, 'name_required'),
                ),
                const SizedBox(height: 20),
                AsasPhoneField(
                  controller: controller.phoneController,
                  hintText: 'phone_number'.tr,
                  validator: validateSaudiPhone,
                ),
                const SizedBox(height: 20),
                Obx(
                  () => AsasCityDropdown(
                    value: controller.selectedCityId.value.isEmpty ? null : controller.selectedCityId.value,
                    onChanged: (v) => controller.selectedCityId.value = v ?? '',
                    validator: controller.validateCity,
                  ),
                ),
                Obx(
                  () => controller.userType.value == UserType.engineer
                      ? _EngineerFields(controller: controller)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 32),
                Obx(
                  () => AsasButton(
                    label: 'complete_profile'.tr,
                    onPressed: controller.completeProfile,
                    isLoading: controller.isLoading.value,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  const _UserTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final UserType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AsasCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            type == UserType.user ? Icons.person : Icons.engineering,
            size: 40,
            color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            type.tr,
            style: TextStyle(
              color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngineerFields extends StatelessWidget {
  const _EngineerFields({required this.controller});

  final CompleteProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        AsasTextField(
          controller: controller.membershipController,
          hintText: 'engineer_membership'.tr,
          prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
          validator: (v) => controller.validateRequired(v, 'engineer_membership_required'),
        ),
        const SizedBox(height: 20),
        AsasTextField(
          controller: controller.experienceController,
          hintText: 'engineer_experience'.tr,
          keyboardType: TextInputType.number,
          prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
          validator: (v) => controller.validateRequired(v, 'engineer_experience_required'),
        ),
        const SizedBox(height: 20),
        Obx(
          () => AsasSpecializationDropdown(
            value: controller.selectedSpecializationId.value.isEmpty ? null : controller.selectedSpecializationId.value,
            onChanged: (v) => controller.selectedSpecializationId.value = v ?? '',
            validator: controller.validateSpecialization,
          ),
        ),
        const SizedBox(height: 20),
        AsasTextField(
          controller: controller.bioController,
          hintText: 'engineer_bio_hint'.tr,
          prefixIcon: Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
          maxLines: 4,
        ),
      ],
    );
  }
}
