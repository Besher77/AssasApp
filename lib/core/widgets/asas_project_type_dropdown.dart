import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../constants/project_types.dart';
import '../theme/app_colors.dart';

/// Project type dropdown
class AsasProjectTypeDropdown extends StatelessWidget {
  const AsasProjectTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value != null && value!.isNotEmpty ? value : null,
      decoration: InputDecoration(
        hintText: 'project_type'.tr,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputRadius),
        ),
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
        prefixIcon: Icon(Icons.category_outlined, color: AppColors.textSecondary),
      ),
      dropdownColor: AppColors.cardBackground,
      icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
      style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
      validator: validator,
      onChanged: onChanged,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'select_project_type'.tr,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ...projectTypes.map(
          (type) => DropdownMenuItem<String>(
            value: type.id,
            child: Text(type.name),
          ),
        ),
      ],
    );
  }
}
