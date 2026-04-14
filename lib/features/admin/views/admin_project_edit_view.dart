import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/project_options.dart';
import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart';
import '../../../core/models/offer_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/admin_project_edit_controller.dart';

class AdminProjectEditView extends GetView<AdminProjectEditController> {
  const AdminProjectEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          controller.isCreate ? 'admin_project_create'.tr : 'admin_project_edit'.tr,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!controller.isCreate)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
              onPressed: controller.deleteProject,
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryAccent));
        }
        return Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (controller.isCreate) ...[
                TextFormField(
                  controller: controller.userIdController,
                  decoration: _dec('admin_project_owner_uid'.tr),
                  style: TextStyle(color: AppColors.textPrimary),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'admin_project_owner_required'.tr : null,
                ),
                const SizedBox(height: 12),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline_rounded, color: AppColors.primaryAccent),
                  title: Obx(
                    () => Text(
                      controller.ownerDisplayName.value,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  subtitle: Text(
                    'admin_open_owner_profile'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => controller.openUserInAdmin(controller.userIdController.text.trim()),
                ),
                const SizedBox(height: 4),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: AppColors.textSecondary,
                  iconColor: AppColors.primaryAccent,
                  title: Text(
                    'admin_technical_ids'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SelectableText(
                          '${'admin_project_doc_id'.tr}: ${controller.editingId ?? ''}',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: controller.userIdController,
                      decoration: _dec('admin_project_owner_uid'.tr),
                      style: TextStyle(color: AppColors.textPrimary),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'admin_project_owner_required'.tr : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Obx(
                () => DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: controller.projectTypeId.value.isEmpty ? null : controller.projectTypeId.value,
                  decoration: _dec('project_type'.tr),
                  dropdownColor: AppColors.cardBackground,
                  style: TextStyle(color: AppColors.textPrimary),
                  items: projectTypes
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.projectTypeId.value = v;
                  },
                  validator: (v) => v == null || v.isEmpty ? 'project_type_required'.tr : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.landAreaController,
                decoration: _dec('land_area'.tr),
                style: TextStyle(color: AppColors.textPrimary),
                validator: (v) => v == null || v.trim().isEmpty ? 'land_area_required'.tr : null,
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: controller.selectedCityId.value.isEmpty ? null : controller.selectedCityId.value,
                  decoration: _dec('city'.tr),
                  dropdownColor: AppColors.cardBackground,
                  style: TextStyle(color: AppColors.textPrimary),
                  items: saudiCities
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.selectedCityId.value = v;
                  },
                  validator: (v) => v == null || v.isEmpty ? 'city_required'.tr : null,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 4,
                decoration: _dec('project_description'.tr),
                style: TextStyle(color: AppColors.textPrimary),
                validator: (v) => v == null || v.trim().isEmpty ? 'description_required'.tr : null,
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: controller.selectedBudgetId.value.isEmpty ? null : controller.selectedBudgetId.value,
                  decoration: _dec('expected_budget'.tr),
                  dropdownColor: AppColors.cardBackground,
                  style: TextStyle(color: AppColors.textPrimary),
                  items: budgetOptions
                      .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.selectedBudgetId.value = v;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value:
                      controller.selectedDeliveryId.value.isEmpty ? null : controller.selectedDeliveryId.value,
                  decoration: _dec('select_delivery_duration'.tr),
                  dropdownColor: AppColors.cardBackground,
                  style: TextStyle(color: AppColors.textPrimary),
                  items: deliveryDurationOptions
                      .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.selectedDeliveryId.value = v;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: controller.statusId.value,
                  decoration: _dec('status'.tr),
                  dropdownColor: AppColors.cardBackground,
                  style: TextStyle(color: AppColors.textPrimary),
                  items: projectStatuses
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.statusId.value = v;
                  },
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('admin_project_listed'.tr, style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    'admin_project_listed_sub'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: controller.listed.value,
                  activeThumbColor: AppColors.primaryAccent,
                  onChanged: (v) => controller.listed.value = v,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.invitedEngineerIdController,
                decoration: _dec('admin_invited_engineer_uid'.tr),
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.acceptedEngineerIdController,
                decoration: _dec('admin_accepted_engineer_uid'.tr),
                style: TextStyle(color: AppColors.textPrimary),
              ),
              if (!controller.isCreate && controller.canOpenAdminSupportChat) ...[
                const SizedBox(height: 16),
                Material(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.glassBorder),
                    ),
                    leading: Icon(Icons.support_agent_rounded, color: AppColors.primaryAccent),
                    title: Text(
                      'admin_open_support_chat'.tr,
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'admin_open_support_chat_sub'.tr,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () {
                      final id = controller.editingId;
                      if (id != null) {
                        Get.toNamed(AppRoutes.adminProjectSupportChat, arguments: id);
                      }
                    },
                  ),
                ),
              ],
              if (!controller.isCreate) ...[
                const SizedBox(height: 24),
                Text(
                  'admin_related_section'.tr,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'admin_related_tap_hint'.tr,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final people = List<AdminProjectRelatedPerson>.of(controller.relatedPeople);
                  if (people.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: people
                        .map(
                          (p) => _relatedUserTile(
                            title: p.displayName != null && p.displayName!.isNotEmpty
                                ? p.displayName!
                                : 'admin_unknown_user'.tr,
                            subtitle: p.roleTrKey.tr,
                            onTap: () => controller.openUserInAdmin(p.uid),
                          ),
                        )
                        .toList(),
                  );
                }),
                Obx(() {
                  final line = controller.acceptedOfferLine.value;
                  if (line == null || line.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _relatedUserTile(
                      title: 'admin_accepted_offer_row'.tr,
                      subtitle: line,
                      onTap: null,
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  'admin_project_offers_title'.tr,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final offList = List<OfferDocument>.of(controller.offers);
                  if (offList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'no_offers'.tr,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    );
                  }
                  return Column(
                    children: offList.map((o) {
                      final name = (o.engineerName != null && o.engineerName!.isNotEmpty)
                          ? o.engineerName!
                          : 'admin_unknown_user'.tr;
                      final statusLabel = _offerStatusLabel(o.status);
                      final extra = [
                        if (o.proposedPrice != null && o.proposedPrice!.isNotEmpty) o.proposedPrice,
                        if (o.proposedDuration != null && o.proposedDuration!.isNotEmpty)
                          o.proposedDuration,
                      ].join(' · ');
                      return _relatedUserTile(
                        title: name,
                        subtitle: '$statusLabel${extra.isNotEmpty ? '\n$extra' : ''}',
                        onTap: o.engineerId.isNotEmpty ? () => controller.openUserInAdmin(o.engineerId) : null,
                      );
                    }).toList(),
                  );
                }),
              ],
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isSaving.value ? null : controller.save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isSaving.value
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _offerStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'offer_accepted'.tr;
      case 'rejected':
        return 'offer_rejected'.tr;
      default:
        return 'admin_offer_status_pending'.tr;
    }
  }

  Widget _relatedUserTile({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final inner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: onTap == null
            ? inner
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: inner,
              ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: AppColors.cardBackground,
      labelStyle: TextStyle(color: AppColors.textSecondary),
    );
  }
}
