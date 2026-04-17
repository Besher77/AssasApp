import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/saudi_cities.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../../core/models/user_type.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key, this.showBackButton = true, this.isEmbedded = false});

  final bool showBackButton;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        if (controller.isEditMode.value) {
          return _EditProfileLayout(controller: controller, showBackButton: showBackButton, isEmbedded: isEmbedded);
        }
        return _ProfileLayout(controller: controller, showBackButton: showBackButton, isEmbedded: isEmbedded);
      }),
    );
  }
}

class _ProfileLayout extends StatelessWidget {
  const _ProfileLayout({required this.controller, this.showBackButton = true, this.isEmbedded = false});

  final ProfileController controller;
  final bool showBackButton;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          pinned: true,
          backgroundColor: AppColors.primaryBackground,
          leading: showBackButton
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                  onPressed: () => Get.back(),
                )
              : null,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                _ProfileHeader(controller: controller),
                const SizedBox(height: 24),
                _WalletCard(controller: controller),
                const SizedBox(height: 28),
                _MenuSection(controller: controller, isEmbedded: isEmbedded),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final path = controller.avatarPath.value;
        return Row(
        children: [
          Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryAccent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ClipOval(child: _buildAvatarContent(path)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: controller.toggleEditMode,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryBackground, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.black, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.nameController.text.isEmpty ? 'user'.tr : controller.nameController.text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (controller.selectedCityId.value.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        getCityNameById(controller.selectedCityId.value),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAvatarContent(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: AppColors.cardBackground,
        child: Icon(Icons.person_rounded, size: 44, color: AppColors.textSecondary),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/wallet'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryAccent.withValues(alpha: 0.25),
              AppColors.primaryAccent.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryAccent, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'wallet_balance'.tr,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.walletBalance.value.toStringAsFixed(2)} SAR',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryAccent),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.controller, this.isEmbedded = false});

  final ProfileController controller;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.edit_outlined,
            label: 'edit_profile'.tr,
            onTap: () => controller.toggleEditMode(),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'wallet'.tr,
            onTap: () => Get.toNamed('/wallet'),
          ),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.credit_card_outlined,
            label: 'payment_methods'.tr,
            onTap: () => Get.toNamed('/saved-cards'),
          ),
          if (controller.userType.value == UserType.engineer) ...[
            _MenuDivider(),
            _MenuTile(
              icon: Icons.account_balance_outlined,
              label: 'engineer_bank_details'.tr,
              onTap: () => Get.toNamed(AppRoutes.engineerBankDetails),
            ),
          ],
          _MenuDivider(),
          _MenuTile(
            icon: Icons.folder_outlined,
            label: 'nav_my_projects'.tr,
            onTap: () {
              if (!isEmbedded) Get.back();
              Get.find<HomeController>().goToMyProjects();
            },
          ),
          if (controller.userType.value == UserType.engineer) ...[
            _MenuDivider(),
            _MenuTile(
              icon: Icons.workspace_premium_outlined,
              label: 'portfolio'.tr,
              onTap: () => Get.toNamed('/portfolio'),
            ),
            _MenuDivider(),
            _MenuTile(
              icon: Icons.rate_review_outlined,
              label: 'my_reviews'.tr,
              onTap: () => Get.toNamed(AppRoutes.myReviews),
            ),
          ],
          _MenuDivider(),
          _SettingsSection(),
          _MenuDivider(),
          _MenuTile(
            icon: Icons.notifications_outlined,
            label: 'notifications'.tr,
            onTap: () => Get.toNamed('/notifications'),
          ),
          if (controller.userType.value == UserType.engineer) ...[
            _MenuDivider(),
            _MenuTile(
              icon: Icons.person_outline_rounded,
              label: 'view_my_profile'.tr,
              onTap: () {
                final uid = Get.find<AuthService>().currentUserId;
                if (uid != null) Get.toNamed('/engineer-profile', arguments: uid);
              },
            ),
          ],
          _MenuDivider(),
          _MenuTile(
            icon: Icons.logout_rounded,
            label: 'logout'.tr,
            iconColor: Colors.red.shade400,
            onTap: () => controller.logout(),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsService>();
    return Obx(
      () => Column(
        children: [
          _SettingsTile(
            icon: Icons.language_rounded,
            label: 'language'.tr,
            subtitle: settings.locale.value == 'ar' ? 'العربية' : 'English',
            value: settings.locale.value == 'en',
            onChanged: (_) => settings.toggleLocale(),
          ),
          _MenuDivider(),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            label: 'dark_mode'.tr,
            subtitle: settings.isDarkMode ? 'on'.tr : 'off'.tr,
            value: settings.isDarkMode,
            onChanged: (_) => settings.toggleTheme(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryAccent.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primaryAccent,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primaryAccent, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: iconColor ?? AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: AppColors.glassBorder,
      indent: 60,
    );
  }
}

class _EditProfileLayout extends StatelessWidget {
  const _EditProfileLayout({required this.controller, this.showBackButton = true, this.isEmbedded = false});

  final ProfileController controller;
  final bool showBackButton;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => controller.toggleEditMode(),
        ),
        title: Text('edit_profile'.tr, style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _AvatarSection(controller: controller),
              const SizedBox(height: 28),
              _EditForm(controller: controller),
              const SizedBox(height: 28),
              AsasButton(
                label: 'save'.tr,
                onPressed: controller.saveProfile,
                isLoading: controller.isSaving.value,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final path = controller.avatarPath.value;
      return Center(
        child: GestureDetector(
          onTap: controller.pickAvatar,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryAccent, width: 3),
                ),
                child: ClipOval(child: _buildAvatarContent(path)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBackground, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAvatarContent(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        color: AppColors.cardBackground,
        child: Icon(Icons.person_rounded, size: 50, color: AppColors.textSecondary),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AsasTextField(
          controller: controller.nameController,
          hintText: 'name'.tr,
          prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
          validator: (v) => controller.validateRequired(v, 'name_required'),
          enabled: controller.isEditMode.value,
        ),
        const SizedBox(height: 20),
        AsasPhoneField(
          controller: controller.phoneController,
          hintText: 'phone_number'.tr,
          validator: validateSaudiPhone,
          enabled: controller.isEditMode.value,
        ),
        const SizedBox(height: 20),
        Obx(
          () => AsasCityDropdown(
            value: controller.selectedCityId.value.isEmpty ? null : controller.selectedCityId.value,
            onChanged: (v) => controller.selectedCityId.value = v ?? '',
            validator: controller.validateCity,
          ),
        ),
        const SizedBox(height: 20),
        AsasTextField(
          controller: controller.emailController,
          hintText: 'email'.tr,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
          enabled: controller.isEditMode.value,
        ),
        Obx(
          () => controller.userType.value == UserType.engineer
              ? _EngineerFields(controller: controller)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _EngineerFields extends StatelessWidget {
  const _EngineerFields({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        AsasTextField(
          controller: controller.membershipController,
          hintText: 'engineer_membership'.tr,
          prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
          validator: (v) => controller.userType.value == UserType.engineer ? controller.validateRequired(v, 'engineer_membership_required') : null,
          enabled: controller.isEditMode.value,
        ),
        const SizedBox(height: 20),
        AsasTextField(
          controller: controller.experienceController,
          hintText: 'engineer_experience'.tr,
          keyboardType: TextInputType.number,
          prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
          validator: (v) => controller.userType.value == UserType.engineer ? controller.validateRequired(v, 'engineer_experience_required') : null,
          enabled: controller.isEditMode.value,
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
          enabled: controller.isEditMode.value,
        ),
      ],
    );
  }
}
