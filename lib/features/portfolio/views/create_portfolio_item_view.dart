import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/project_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/create_portfolio_item_controller.dart';

class CreatePortfolioItemView extends GetView<CreatePortfolioItemController> {
  const CreatePortfolioItemView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'add_portfolio_item'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
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
                const SizedBox(height: 16),
                AsasTextField(
                  controller: controller.titleController,
                  hintText: 'portfolio_title'.tr,
                  prefixIcon: Icon(Icons.title, color: AppColors.textSecondary),
                  validator: (v) => controller.validateRequired(v, 'portfolio_title_required'),
                ),
                const SizedBox(height: 20),
                AsasTextField(
                  controller: controller.descriptionController,
                  hintText: 'portfolio_description'.tr,
                  maxLines: 4,
                  prefixIcon: Icon(Icons.description_outlined, color: AppColors.textSecondary),
                  validator: (v) => controller.validateRequired(v, 'description_required'),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => _buildDropdown<String>(
                    value: controller.selectedProjectTypeId.value.isEmpty ? null : controller.selectedProjectTypeId.value,
                    hintText: 'project_type'.tr,
                    items: [
                      DropdownMenuItem(value: null, child: Text('select_project_type'.tr, style: TextStyle(color: AppColors.textSecondary))),
                      ...projectTypes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                    ],
                    onChanged: (v) => controller.selectedProjectTypeId.value = v ?? '',
                    validator: null,
                    icon: Icons.category_outlined,
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => GestureDetector(
                    onTap: controller.pickDate,
                    child: _buildDateField(controller.executionDate.value),
                  ),
                ),
                const SizedBox(height: 20),
                AsasTextField(
                  controller: controller.locationController,
                  hintText: 'portfolio_location'.tr,
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Text(
                  'upload_images'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => _ImagePickerSection(
                    imagePaths: controller.imagePaths.toList(),
                    onPickImages: controller.pickImages,
                    onRemoveImage: controller.removeImage,
                  ),
                ),
                const SizedBox(height: 32),
                Obx(
                  () => AsasButton(
                    label: 'add_portfolio_item'.tr,
                    onPressed: controller.createItem,
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

  Widget _buildDateField(DateTime? date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Text(
            date != null
                ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                : 'execution_date'.tr,
            style: TextStyle(
              color: date != null ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
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
}

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.imagePaths,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  final List<String> imagePaths;
  final VoidCallback onPickImages;
  final void Function(int) onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
                Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textSecondary),
                const SizedBox(height: 4),
                Text(
                  'upload_images'.tr,
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
    );
  }
}
