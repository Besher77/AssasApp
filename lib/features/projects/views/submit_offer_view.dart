import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/platform_commission.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/submit_offer_controller.dart';

class SubmitOfferView extends GetView<SubmitOfferController> {
  const SubmitOfferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'submit_offer'.tr,
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
                  controller: controller.messageController,
                  hintText: 'offer_message'.tr,
                  maxLines: 4,
                  validator: controller.validateMessage,
                ),
                const SizedBox(height: 20),
                if (controller.projectBudgetHint.isNotEmpty) ...[
                  _HintChip(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'expected_budget_hint'.trParams({'budget': controller.projectBudgetHint}),
                  ),
                  const SizedBox(height: 12),
                ],
                AsasTextField(
                  controller: controller.priceController,
                  hintText: 'proposed_price'.tr,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icon(Icons.attach_money, color: AppColors.textSecondary, size: 20),
                  validator: controller.validatePrice,
                ),
                Obx(() {
                  controller.priceInputTick.value;
                  final net = controller.engineerEstimatedNet;
                  final gross = controller.parsedOfferAmount;
                  if (net == null || gross == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade900.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.45)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.savings_outlined, color: AppColors.primaryAccent, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'offer_engineer_net_title'.tr,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'offer_engineer_net_body'.trParams({
                              'net': net.toStringAsFixed(2),
                              'gross': gross.toStringAsFixed(2),
                              'pct': '${(kPlatformCommissionRate * 100).round()}',
                            }),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                if (controller.projectDurationHint.isNotEmpty) ...[
                  _HintChip(
                    icon: Icons.schedule_outlined,
                    text: 'expected_duration_hint'.trParams({'duration': controller.projectDurationHint}),
                  ),
                  const SizedBox(height: 12),
                ],
                AsasTextField(
                  controller: controller.durationController,
                  hintText: 'proposed_duration'.tr,
                  prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
                  validator: controller.validateDuration,
                ),
                const SizedBox(height: 24),
                _AttachmentsSection(controller: controller),
                const SizedBox(height: 32),
                Obx(
                  () => AsasButton(
                    label: 'submit_offer'.tr,
                    onPressed: controller.submit,
                    isLoading: controller.isSubmitting.value,
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

class _HintChip extends StatelessWidget {
  const _HintChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.controller});

  final SubmitOfferController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'attachments'.tr,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.pickImages,
                icon: Icon(Icons.add_photo_alternate_outlined, size: 20, color: AppColors.primaryAccent),
                label: Text('add_images'.tr, style: TextStyle(color: AppColors.primaryAccent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.pickFiles,
                icon: Icon(Icons.attach_file, size: 20, color: AppColors.primaryAccent),
                label: Text('add_files'.tr, style: TextStyle(color: AppColors.primaryAccent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primaryAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        Obx(() {
          if (controller.imageFiles.isEmpty && controller.fileAttachments.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.imageFiles.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(controller.imageFiles.length, (i) {
                      return _ImageChip(
                        file: controller.imageFiles[i],
                        onRemove: () => controller.removeImage(i),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                ],
                if (controller.fileAttachments.isNotEmpty) ...[
                  ...controller.fileAttachments.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FileChip(
                        name: e.value.name,
                        onRemove: () => controller.removeFile(e.key),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ImageChip extends StatelessWidget {
  const _ImageChip({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(file, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined, color: AppColors.primaryAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
