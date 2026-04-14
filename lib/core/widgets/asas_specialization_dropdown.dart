import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../constants/engineer_specializations.dart';
import '../theme/app_colors.dart';

/// Engineer specialization dropdown
class AsasSpecializationDropdown extends StatelessWidget {
  const AsasSpecializationDropdown({
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
      value: value != null && value!.isNotEmpty
          ? (engineerSpecializations.any((s) => s.id == value) ? value : null)
          : null,
      decoration: InputDecoration(
        hintText: 'engineer_specialization'.tr,
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
            'select_specialization'.tr,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ...engineerSpecializations.map(
          (spec) => DropdownMenuItem<String>(
            value: spec.id,
            child: Text(spec.name),
          ),
        ),
      ],
    );
  }
}
