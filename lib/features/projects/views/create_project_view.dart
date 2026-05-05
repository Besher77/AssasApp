import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/project_options.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/create_project_controller.dart';

class CreateProjectView extends GetView<CreateProjectController> {
  const CreateProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !controller.isLoading.value,
        child: Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'create_project'.tr,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
              onPressed: controller.isLoading.value ? null : () => Get.back(),
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Obx(
                          () => AsasProjectTypeDropdown(
                            value: controller.projectTypeId.value.isEmpty ? null : controller.projectTypeId.value,
                            onChanged: (v) => controller.projectTypeId.value = v ?? '',
                            validator: controller.validateProjectType,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AsasTextField(
                              controller: controller.landAreaController,
                              hintText: 'land_area'.tr,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icon(Icons.square_foot, color: AppColors.textSecondary),
                              validator: (v) => controller.validateRequired(v, 'land_area_required'),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryAccent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'land_area_hint'.tr,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        Obx(
                          () => _buildDropdown<String>(
                            value: controller.selectedBudgetId.value.isEmpty ? null : controller.selectedBudgetId.value,
                            hintText: 'expected_budget'.tr,
                            items: [
                              DropdownMenuItem(value: null, child: Text('select_budget'.tr, style: TextStyle(color: AppColors.textSecondary))),
                              ...budgetOptions.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                            ],
                            onChanged: (v) => controller.selectedBudgetId.value = v ?? '',
                            validator: controller.validateBudget,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(
                          () => _buildDropdown<String>(
                            value: controller.selectedDeliveryDurationId.value.isEmpty ? null : controller.selectedDeliveryDurationId.value,
                            hintText: 'expected_delivery'.tr,
                            items: [
                              DropdownMenuItem(value: null, child: Text('select_delivery_duration'.tr, style: TextStyle(color: AppColors.textSecondary))),
                              ...deliveryDurationOptions.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                            ],
                            onChanged: (v) => controller.selectedDeliveryDurationId.value = v ?? '',
                            validator: controller.validateDeliveryDuration,
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AsasTextField(
                          controller: controller.descriptionController,
                          hintText: 'project_description'.tr,
                          maxLines: 4,
                          prefixIcon: Icon(Icons.description_outlined, color: AppColors.textSecondary),
                          validator: (v) => controller.validateRequired(v, 'description_required'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'upload_images_and_files'.tr,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Obx(
                          () => _MediaPickerSection(
                            imagePaths: controller.imagePaths.toList(),
                            fileAttachments: controller.fileAttachments.toList(),
                            onPickImages: controller.pickImages,
                            onPickFiles: controller.pickFiles,
                            onRemoveImage: controller.removeImage,
                            onRemoveFile: controller.removeFile,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Obx(
                          () => AsasButton(
                            label: 'create_project'.tr,
                            onPressed: controller.isLoading.value ? null : () => controller.createProject(),
                            isLoading: controller.isLoading.value,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.isLoading.value) const _CreateProjectProgressOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateProjectProgressOverlay extends GetView<CreateProjectController> {
  const _CreateProjectProgressOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Obx(
                () {
                  final p = controller.submitProgress.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: p <= 0 || p >= 1 ? null : p,
                            minHeight: 8,
                            backgroundColor: AppColors.glassBorder,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        controller.submitPhaseKey.value.isEmpty
                            ? 'please_wait'.tr
                            : controller.submitPhaseKey.value.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'create_project_do_not_close'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDropdown<T>({
  required T? value,
  required String hintText,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
  String? Function(T?)? validator,
  required IconData icon,
}) {
  return DropdownButtonFormField<T>(
    initialValue: value,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.inputRadius)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
    ),
    dropdownColor: AppColors.cardBackground,
    icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
    style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
    validator: validator,
    onChanged: onChanged,
    items: items,
  );
}

class _MediaPickerSection extends StatelessWidget {
  const _MediaPickerSection({
    required this.imagePaths,
    required this.fileAttachments,
    required this.onPickImages,
    required this.onPickFiles,
    required this.onRemoveImage,
    required this.onRemoveFile,
  });

  final List<String> imagePaths;
  final List<({File file, String name})> fileAttachments;
  final VoidCallback onPickImages;
  final VoidCallback onPickFiles;
  final void Function(int) onRemoveImage;
  final void Function(int) onRemoveFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'add_images'.tr,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: onPickImages,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.primaryAccent),
                    const SizedBox(height: 4),
                    Text(
                      'add_images'.tr,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            ...imagePaths.asMap().entries.map(
                  (e) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(e.value),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(e.key),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'add_files'.tr,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: onPickFiles,
              child: Container(
                width: 100,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_file, size: 28, color: AppColors.primaryAccent),
                    const SizedBox(height: 4),
                    Text(
                      'add_files'.tr,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            ...fileAttachments.asMap().entries.map(
                  (e) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: AppColors.primaryAccent, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.value.name,
                                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => onRemoveFile(e.key),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
