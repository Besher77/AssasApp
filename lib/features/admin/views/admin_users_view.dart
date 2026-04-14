import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/admin_users_controller.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final engineersFirst = args is Map && args['tab'] == 'engineers';
    _tabController = TabController(length: 2, vsync: this, initialIndex: engineersFirst ? 1 : 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminUsersController>();
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
          'admin_users_title'.tr,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'admin_notify_all_users'.tr,
              onPressed: controller.isBroadcasting.value ? null : controller.promptNotifyAllUsers,
              icon: controller.isBroadcasting.value
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
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAccent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryAccent,
          tabs: [
            Tab(text: 'admin_tab_users'.tr),
            Tab(
              child: Obx(() {
                final n = controller.pendingEngineerRegistrationsCount.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text('admin_tab_engineers'.tr, overflow: TextOverflow.ellipsis)),
                    if (n > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          n > 99 ? '99+' : '$n',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.adminUserEdit),
        backgroundColor: AppColors.primaryAccent,
        child: const Icon(Icons.person_add_rounded, color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'admin_search_users_hint'.tr,
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Obx(() {
                  controller.searchQuery.value;
                  final list = controller.filteredUsers;
                  return _UserList(
                    list: list,
                    emptySearch: controller.users.isNotEmpty && list.isEmpty,
                    onEdit: (u) => Get.toNamed(AppRoutes.adminUserEdit, arguments: u.uid),
                    menuBuilder: (u) => _buildMenu(context, controller, u),
                  );
                }),
                Obx(() {
                  controller.searchQuery.value;
                  final list = controller.filteredEngineers;
                  return _UserList(
                    list: list,
                    emptySearch: controller.engineers.isNotEmpty && list.isEmpty,
                    onEdit: (u) => Get.toNamed(AppRoutes.adminUserEdit, arguments: u.uid),
                    menuBuilder: (u) => _buildMenu(context, controller, u),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, AdminUsersController controller, UserDocument u) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            Get.toNamed(AppRoutes.adminUserEdit, arguments: u.uid);
            break;
          case 'block':
            controller.toggleBlocked(u);
            break;
          case 'suspend':
            controller.pickSuspendUntil(u);
            break;
          case 'clear_susp':
            controller.clearSuspension(u);
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'edit', child: Text('edit'.tr)),
        if (u.userType != 'admin')
          PopupMenuItem(
            value: 'block',
            child: Text(u.blocked ? 'admin_unblock_user'.tr : 'admin_block_user'.tr),
          ),
        if (u.userType != 'admin' && !u.blocked) ...[
          PopupMenuItem(value: 'suspend', child: Text('admin_suspend_until'.tr)),
          if (u.suspendedUntil != null && u.suspendedUntil!.isAfter(DateTime.now()))
            PopupMenuItem(value: 'clear_susp', child: Text('admin_clear_suspension'.tr)),
        ],
      ],
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({
    required this.list,
    required this.emptySearch,
    required this.onEdit,
    required this.menuBuilder,
  });

  final List<UserDocument> list;
  final bool emptySearch;
  final void Function(UserDocument) onEdit;
  final Widget Function(UserDocument) menuBuilder;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          emptySearch ? 'admin_search_no_results'.tr : 'admin_no_users'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final u = list[i];
        return Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onEdit(u),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                    child: Text(
                      u.name.isNotEmpty ? u.name.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.name.isEmpty ? '—' : u.name,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u.phone,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(user: u),
                  const SizedBox(width: 4),
                  menuBuilder(u),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.user});

  final UserDocument user;

  @override
  Widget build(BuildContext context) {
    if (user.blocked) {
      return _chip('admin_status_blocked'.tr, Colors.red.shade700);
    }
    if (user.suspendedUntil != null && user.suspendedUntil!.isAfter(DateTime.now())) {
      return _chip('admin_status_suspended'.tr, Colors.orange.shade800);
    }
    if (user.userType == 'engineer' && !user.isEngineerRegistrationApproved) {
      if (user.isEngineerRegistrationRejected) {
        return _chip('engineer_reg_rejected_label'.tr, Colors.deepPurple.shade400);
      }
      return _chip('engineer_reg_pending'.tr, Colors.amber.shade800);
    }
    return _chip('admin_status_active'.tr, Colors.green.shade700);
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
