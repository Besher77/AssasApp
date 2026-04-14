import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/firestore_service.dart' show EngineerRegistrationStatus;
import '../../../core/theme/app_colors.dart';
import '../controllers/admin_user_edit_controller.dart';

class AdminUserEditView extends GetView<AdminUserEditController> {
  const AdminUserEditView({super.key});

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
          controller.isCreate ? 'admin_user_create'.tr : 'admin_user_edit'.tr,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!controller.isCreate)
            Obx(
              () => IconButton(
                tooltip: 'admin_send_notification'.tr,
                onPressed: controller.isSendingAnnouncement.value ? null : controller.promptSendAnnouncement,
                icon: controller.isSendingAnnouncement.value
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryAccent,
                        ),
                      )
                    : Icon(Icons.campaign_outlined, color: AppColors.primaryAccent),
              ),
            ),
          if (!controller.isCreate)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
              onPressed: controller.deleteUser,
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
                  controller: controller.uidController,
                  decoration: InputDecoration(
                    labelText: 'admin_uid_label'.tr,
                    hintText: 'admin_uid_hint'.tr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                  validator: controller.validateUidField,
                ),
                const SizedBox(height: 16),
              ] else ...[
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  collapsedIconColor: AppColors.textSecondary,
                  iconColor: AppColors.primaryAccent,
                  title: Text(
                    'admin_user_id_expand_title'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  subtitle: Text(
                    'admin_user_id_expand_subtitle'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  children: [
                    SelectableText(
                      controller.editingUid ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () async {
                          final id = controller.editingUid;
                          if (id == null || id.isEmpty) return;
                          await Clipboard.setData(ClipboardData(text: id));
                          Get.snackbar('', 'copied_to_clipboard'.tr);
                        },
                        icon: Icon(Icons.copy, size: 18, color: AppColors.primaryAccent),
                        label: Text('admin_copy_user_id'.tr),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: controller.nameController,
                decoration: _dec('name'.tr),
                style: TextStyle(color: AppColors.textPrimary),
                validator: controller.validateNameField,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: _dec('login_phone'.tr),
                style: TextStyle(color: AppColors.textPrimary),
                validator: controller.validatePhoneField,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.emailController,
                decoration: _dec('email'.tr),
                style: TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.cityController,
                decoration: _dec('city'.tr),
                style: TextStyle(color: AppColors.textPrimary),
                validator: controller.validateCityField,
              ),
              const SizedBox(height: 20),
              Text('select_user_type'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text('user_type_user'.tr),
                          selected: controller.userTypeStr.value == 'user',
                          onSelected: (_) => controller.setUserType('user'),
                          selectedColor: AppColors.primaryAccent.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: Text('user_type_engineer'.tr),
                          selected: controller.userTypeStr.value == 'engineer',
                          onSelected: (_) => controller.setUserType('engineer'),
                          selectedColor: AppColors.primaryAccent.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  )),
              Obx(() {
                if (controller.userTypeStr.value != 'engineer') return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: controller.membershipController,
                      decoration: _dec('engineer_membership'.tr),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.experienceController,
                      decoration: _dec('engineer_experience'.tr),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.specializationController,
                      decoration: _dec('engineer_specialization'.tr),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.bioController,
                      maxLines: 3,
                      decoration: _dec('engineer_bio'.tr),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                );
              }),
              Obx(() {
                if (controller.userTypeStr.value != 'engineer') return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'admin_engineer_reg_section'.tr,
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use — controlled by Obx + engineerRegStr
                        value: controller.engineerRegStr.value,
                        decoration: _dec('admin_engineer_reg_status'.tr),
                        dropdownColor: AppColors.cardBackground,
                        style: TextStyle(color: AppColors.textPrimary),
                        items: [
                          DropdownMenuItem(
                            value: EngineerRegistrationStatus.pending,
                            child: Text('engineer_reg_pending'.tr),
                          ),
                          DropdownMenuItem(
                            value: EngineerRegistrationStatus.active,
                            child: Text('engineer_reg_active'.tr),
                          ),
                          DropdownMenuItem(
                            value: EngineerRegistrationStatus.rejected,
                            child: Text('engineer_reg_rejected_label'.tr),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) controller.engineerRegStr.value = v;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller.engineerRegNoteController,
                      maxLines: 2,
                      decoration: _dec('admin_engineer_reg_note'.tr),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 28),
              if (!controller.isCreate && !controller.isSelf) ...[
                Text('admin_access_section'.tr, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Obx(() => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('admin_blocked'.tr, style: TextStyle(color: AppColors.textPrimary)),
                      subtitle: Text('admin_blocked_sub'.tr, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      value: controller.blocked.value,
                      activeThumbColor: AppColors.primaryAccent,
                      onChanged: (v) => controller.applyQuickBlock(value: v),
                    )),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('admin_suspended_until_label'.tr, style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Obx(() {
                    final t = controller.suspendedUntil.value;
                    return Text(
                      t == null ? '—' : MaterialLocalizations.of(context).formatFullDate(t),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    );
                  }),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: controller.pickSuspensionEnd,
                        child: Text('admin_pick_date'.tr, style: TextStyle(color: AppColors.primaryAccent)),
                      ),
                      TextButton(
                        onPressed: controller.clearSuspension,
                        child: Text('admin_clear_suspension'.tr, style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.blockedReasonController,
                  maxLines: 2,
                  decoration: _dec('admin_reason_optional'.tr),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
              ],
              if (controller.isCreate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'admin_create_note'.tr,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: controller.isSaving.value ? null : controller.saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isSaving.value
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : Text('save'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  )),
            ],
          ),
        );
      }),
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
