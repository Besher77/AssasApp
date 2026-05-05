import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/cancel_cause_templates.dart' show cancelCauseTemplates;
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';

/// Dialog to request or respond to project cancellation - both must select cause
class CancelProjectDialog extends StatefulWidget {
  const CancelProjectDialog({
    super.key,
    required this.onConfirm,
    this.title,
    this.confirmLabel,
  });

  final void Function(String causeId, {String? causeText}) onConfirm;
  final String? title;
  final String? confirmLabel;

  @override
  State<CancelProjectDialog> createState() => _CancelProjectDialogState();
}

class _CancelProjectDialogState extends State<CancelProjectDialog> {
  String? _selectedCauseId;
  final _causeTextController = TextEditingController();

  @override
  void dispose() {
    _causeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: Text(
        widget.title ?? 'cancel_project'.tr,
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'cancel_project_cause_required'.tr,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _selectedCauseId,
              onChanged: (v) => setState(() => _selectedCauseId = v),
              child: Column(
                children: cancelCauseTemplates.map((t) => RadioListTile<String>(
                  title: Text(t.name, style: TextStyle(color: AppColors.textPrimary)),
                  value: t.id,
                  activeColor: AppColors.primaryAccent,
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
            AsasTextField(
              controller: _causeTextController,
              label: 'additional_notes'.tr,
              hintText: 'cancel_notes_hint'.tr,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _selectedCauseId == null
              ? null
              : () {
                  Get.back();
                  widget.onConfirm(
                    _selectedCauseId!,
                    causeText: _causeTextController.text.trim().isEmpty
                        ? null
                        : _causeTextController.text.trim(),
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.5),
          ),
          child: Text(widget.confirmLabel ?? 'request_cancel'.tr),
        ),
      ],
    );
  }
}
