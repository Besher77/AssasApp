import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

/// Saudi phone number field with +966 prefix (fixed)
class AsasPhoneField extends StatelessWidget {
  const AsasPhoneField({
    super.key,
    this.controller,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;

  static const String saudiCode = '+966';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  saudiCode,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            enabled: enabled,
            maxLength: 9,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hintText ?? '5XXXXXXXX',
              hintStyle: TextStyle(color: AppColors.textSecondary),
              counterText: '',
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.inputRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                borderSide: BorderSide(
                  color: AppColors.primaryAccent,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                borderSide: BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Validates Saudi phone number: 9 digits starting with 5
String? validateSaudiPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'login_phone_required'.tr;
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 9) {
    return 'phone_saudi_invalid'.tr;
  }
  if (!digits.startsWith('5')) {
    return 'phone_saudi_invalid'.tr;
  }
  return null;
}
