import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/project_options.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/constants/project_types.dart';
import '../../../core/constants/saudi_cities.dart' show getCityNameById;
import '../../../core/models/offer_document.dart';
import '../../../core/models/project_document.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/project_detail_controller.dart';
import 'cancel_project_dialog.dart';

class ProjectDetailView extends StatefulWidget {
  const ProjectDetailView({super.key});

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  late final ProjectDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProjectDetailController(), permanent: false);
    final arg = Get.arguments;
    String? projectId;
    if (arg is ProjectDocument) {
      projectId = arg.id;
    } else if (arg is Map && arg['id'] != null) {
      projectId = arg['id'] as String?;
    } else if (arg is String) {
      projectId = arg;
    }
    if (projectId != null && projectId.isNotEmpty) controller.load(projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.project.value == null) {
        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
        );
      }
      final project = controller.project.value;
      if (project == null) {
        if (controller.unlistedAccessDenied.value) {
          return Scaffold(
            backgroundColor: AppColors.primaryBackground,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                onPressed: () => Get.back(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_off_rounded, size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'project_hidden_from_engineers'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
              onPressed: () => Get.back(),
            ),
          ),
          body: Center(
            child: Text('project_not_found'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
        );
      }
      return _buildContent(context, project);
    });
  }

  Future<void> _confirmBrowseListing(BuildContext context, {required bool listed}) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          listed ? 'publish_project_title'.tr : 'hide_project_title'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          listed ? 'publish_project_message'.tr : 'hide_project_message'.tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(listed ? 'publish_project_confirm'.tr : 'hide_project_confirm'.tr),
          ),
        ],
      ),
    );
    if (ok == true) await controller.updateBrowseListing(listed);
  }

  void _showCancelDialog(BuildContext context, {required bool isRespond}) {
    Get.dialog(
      CancelProjectDialog(
        title: isRespond ? 'respond_to_cancel'.tr : 'cancel_project'.tr,
        confirmLabel: isRespond ? 'agree_and_cancel'.tr : 'request_cancel'.tr,
        onConfirm: (causeId, {causeText}) {
          if (isRespond) {
            controller.respondToCancelRequest(causeId, causeText: causeText);
          } else {
            controller.requestCancelProject(causeId, causeText: causeText);
          }
          controller.refresh();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProjectDocument project) {
    final isAccepted = (project.status == 'in_progress' || project.status == 'delivered') &&
        controller.acceptedOffer.value != null;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: controller.isOwner.value
          ? _buildOwnerContent(context, project)
          : _buildNonOwnerContent(context, project),
      floatingActionButton: isAccepted
          ? _AnimatedSpeedDialFab(
              onChat: () => _openChat(controller),
              onCancel: controller.canCancelProject && !controller.isOtherPartyInCancelRequest
                  ? () => _showCancelDialog(context, isRespond: false)
                  : null,
              onRespondToCancel: controller.canCancelProject && controller.isOtherPartyInCancelRequest
                  ? () => _showCancelDialog(context, isRespond: true)
                  : null,
              onDelivery: controller.isEngineer.value && project.status == 'in_progress'
                  ? () => controller.markProjectDelivered()
                  : null,
              onReceive: controller.isOwner.value && project.status == 'delivered'
                  ? () => _showConfirmReceiptAndRun(controller)
                  : null,
            )
          : null,
    );
  }

  Future<void> _showConfirmReceiptAndRun(ProjectDetailController c) async {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('confirm_receive'.tr, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'confirm_receive_message'.tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await c.confirmProjectReceipt();
              await c.refresh();
              if (c.project.value?.status == 'completed' && !c.hasReviewed.value) {
                _openAddReview(
                  c.project.value!.id,
                  c.acceptedOffer.value!.engineerId,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.black),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerContent(BuildContext context, ProjectDocument project) {
    final isAccepted = (project.status == 'in_progress' || project.status == 'delivered') &&
        controller.acceptedOffer.value != null;
    final tabCount = isAccepted ? 3 : 2;

    return DefaultTabController(
      length: tabCount,
      initialIndex: 0,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(context, project),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusChip(status: project.status),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                labelColor: AppColors.primaryAccent,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryAccent,
                tabs: [
                  Tab(text: 'tab_details'.tr),
                  Tab(text: '${'tab_offers'.tr} (${controller.offerCount.value})'),
                  if (isAccepted) Tab(text: 'chat'.tr),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _buildDetailsTab(context, project),
            _buildOffersTab(context),
            if (isAccepted) _buildChatTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_rounded, size: 64, color: AppColors.primaryAccent.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            Text(
              'chat'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'no_messages'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(controller),
                icon: const Icon(Icons.chat_bubble_outline, size: 22),
                label: Text('chat'.tr, style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context, ProjectDocument project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isOwner.value && controller.canToggleBrowseListing)
            _BrowseListingCard(
              project: project,
              onHide: () => _confirmBrowseListing(context, listed: false),
              onPublish: () => _confirmBrowseListing(context, listed: true),
            ),
          if (controller.isOwner.value && controller.canToggleBrowseListing) const SizedBox(height: 20),
          if (project.status == 'delivered' && controller.acceptedOffer.value != null)
            Obx(
              () => _ReceiveProjectCard(
                onConfirmReceipt: () async {
                  await controller.confirmProjectReceipt();
                  await controller.refresh();
                  if (controller.project.value?.status == 'completed' &&
                      !controller.hasReviewed.value) {
                    _openAddReview(
                      controller.project.value!.id,
                      controller.acceptedOffer.value!.engineerId,
                    );
                  }
                },
                isConfirming: controller.isConfirmingReceipt.value,
              ),
            ),
          if (project.status == 'delivered' && controller.acceptedOffer.value != null)
            const SizedBox(height: 20),
          _DescriptionSection(description: project.description),
          const SizedBox(height: 24),
          if (project.imageUrls.isNotEmpty || project.fileAttachments.isNotEmpty)
            _ProjectMediaSection(project: project),
          if (project.imageUrls.isNotEmpty || project.fileAttachments.isNotEmpty)
            const SizedBox(height: 24),
          _DetailsCard(project: project),
        ],
      ),
    );
  }

  Widget _buildOffersTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: _buildOffersSection(context),
    );
  }

  Widget _buildNonOwnerContent(BuildContext context, ProjectDocument project) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, project),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusChip(status: project.status),
                const SizedBox(height: 20),
                _DescriptionSection(description: project.description),
                const SizedBox(height: 24),
                if (project.imageUrls.isNotEmpty || project.fileAttachments.isNotEmpty)
                  _ProjectMediaSection(project: project),
                if (project.imageUrls.isNotEmpty || project.fileAttachments.isNotEmpty)
                  const SizedBox(height: 24),
                _CollapsibleDetails(project: project),
                const SizedBox(height: 24),
                if (controller.isEngineer.value) ...[
                  if (controller.acceptedOffer.value != null)
                    _AcceptedOfferCard(
                      offer: controller.acceptedOffer.value!,
                      projectStatus: controller.project.value?.status ?? '',
                      hasReviewed: controller.hasReviewed.value,
                      remainingTimeText: controller.remainingTimeText,
                      isOwner: false,
                      onMarkDelivered: controller.markProjectDelivered,
                      onConfirmReceipt: null,
                      onAddReview: () => _openAddReview(
                        controller.project.value!.id,
                        controller.acceptedOffer.value!.engineerId,
                      ),
                      onOpenChat: () => _openChat(controller),
                      onTapEngineer: () => _openEngineerProfile(controller.acceptedOffer.value!.engineerId),
                      onCancelProject: controller.canCancelProject ? () => _showCancelDialog(context, isRespond: false) : null,
                      onRespondToCancel: controller.canCancelProject && controller.isOtherPartyInCancelRequest ? () => _showCancelDialog(context, isRespond: true) : null,
                      hasPendingCancelRequest: controller.cancelRequest.value != null,
                      isOtherPartyInCancel: controller.isOtherPartyInCancelRequest,
                    ),
                  if (controller.acceptedOffer.value == null) _buildEngineerActions(context),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    final accepted = controller.acceptedOffer.value;
    final pendingOffers = controller.offers.where((o) => o.status == 'pending').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accepted != null) ...[
          _AcceptedOfferCard(
              offer: accepted,
              projectStatus: controller.project.value?.status ?? '',
              hasReviewed: controller.hasReviewed.value,
              remainingTimeText: controller.remainingTimeText,
              isOwner: true,
              onMarkDelivered: null,
              onConfirmReceipt: controller.project.value?.status == 'delivered'
                  ? null
                  : () async {
                      await controller.confirmProjectReceipt();
                      await controller.refresh();
                    },
              onAddReview: () => _openAddReview(
                controller.project.value!.id,
                accepted.engineerId,
              ),
              onOpenChat: () => _openChat(controller),
              onTapEngineer: () => _openEngineerProfile(accepted.engineerId),
              onCancelProject: controller.canCancelProject ? () => _showCancelDialog(context, isRespond: false) : null,
              onRespondToCancel: controller.canCancelProject && controller.isOtherPartyInCancelRequest ? () => _showCancelDialog(context, isRespond: true) : null,
              hasPendingCancelRequest: controller.cancelRequest.value != null,
              isOtherPartyInCancel: controller.isOtherPartyInCancelRequest,
            ),
          if (pendingOffers.isNotEmpty) const SizedBox(height: 20),
        ],
        if (pendingOffers.isEmpty && accepted == null)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 32, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                const SizedBox(width: 12),
                Text(
                  'no_offers'.tr,
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
                ),
              ],
            ),
          )
        else if (accepted == null)
          ...pendingOffers.map((offer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OfferCard(
                  offer: offer,
                  project: controller.project.value,
                  onAccept: () => _openPaymentToAccept(offer),
                  onReject: () => controller.rejectOffer(offer),
                  onTapEngineer: () => _openEngineerProfile(offer.engineerId),
                ),
              )),
      ],
    );
  }

  void _openPaymentToAccept(OfferDocument offer) {
    final project = controller.project.value;
    if (project == null) return;
    Get.toNamed('/accept-offer-payment', arguments: {
      'offer': offer,
      'project': project,
    })?.then((result) {
      if (result == true) controller.refresh();
    });
  }

  void _openAddReview(String projectId, String engineerId) {
    Get.toNamed('/add-review', arguments: {
      'engineerId': engineerId,
      'projectId': projectId,
    })?.then((_) => controller.refresh());
  }

  Widget _buildEngineerActions(BuildContext context) {
    final p = controller.project.value;
    if (p != null && !p.listed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_off_outlined, color: AppColors.textSecondary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'project_not_accepting_offers'.tr,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.hasOffered.value)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.primaryAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'already_offered'.tr,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openSubmitOffer(controller.project.value!),
              icon: const Icon(Icons.send_outlined, size: 20),
              label: Text('submit_offer'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _openSubmitOffer(ProjectDocument project) {
    Get.toNamed('/submit-offer', arguments: project)?.then((_) => controller.refresh());
  }

  void _openEngineerProfile(String engineerId) {
    Get.toNamed('/engineer-profile', arguments: engineerId);
  }

  Future<void> _openChat(ProjectDetailController c) async {
    final args = await c.getChatArgs();
    if (args == null) return;
    Get.toNamed(AppRoutes.chat, arguments: args)?.then((_) => c.refresh());
  }

  SliverAppBar _buildAppBar(BuildContext context, ProjectDocument project) {
    final hasMedia = project.imageUrls.isNotEmpty || project.fileAttachments.isNotEmpty;
    return SliverAppBar(
      expandedHeight: hasMedia ? 200 : 120,
      pinned: true,
      backgroundColor: AppColors.primaryBackground,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (project.imageUrls.isEmpty)
              Container(
                color: AppColors.cardBackground,
                child: Center(
                  child: Icon(Icons.photo_library_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                ),
              )
            else
              GestureDetector(
                onTap: () => _showImageGallery(context, project.imageUrls, 0),
                child: Image.network(
                  project.imageUrls.first,
                  fit: BoxFit.cover,
                ),
              ),
            if (project.imageUrls.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                  ),
                ),
              ),
            if (project.imageUrls.length > 1)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${project.imageUrls.length}',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageGallery(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: urls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Image.network(urls[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSpeedDialFab extends StatefulWidget {
  const _AnimatedSpeedDialFab({
    required this.onChat,
    this.onCancel,
    this.onRespondToCancel,
    this.onDelivery,
    this.onReceive,
  });

  final VoidCallback onChat;
  final VoidCallback? onCancel;
  final VoidCallback? onRespondToCancel;
  final VoidCallback? onDelivery;
  final VoidCallback? onReceive;

  @override
  State<_AnimatedSpeedDialFab> createState() => _AnimatedSpeedDialFabState();
}

class _AnimatedSpeedDialFabState extends State<_AnimatedSpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.onReceive != null)
          _buildMiniFab(
            icon: Icons.check_circle_outline,
            label: 'receive_project'.tr,
            onTap: () {
              _controller.reverse();
              widget.onReceive!();
            },
          ),
        if (widget.onDelivery != null)
          _buildMiniFab(
            icon: Icons.delivery_dining,
            label: 'deliver_project'.tr,
            onTap: () {
              _controller.reverse();
              widget.onDelivery!();
            },
          ),
        if (widget.onCancel != null)
          _buildMiniFab(
            icon: Icons.cancel_outlined,
            label: 'cancel_project'.tr,
            onTap: () {
              _controller.reverse();
              widget.onCancel!();
            },
          ),
        if (widget.onRespondToCancel != null)
          _buildMiniFab(
            icon: Icons.cancel_outlined,
            label: 'respond_to_cancel'.tr,
            onTap: () {
              _controller.reverse();
              widget.onRespondToCancel!();
            },
          ),
        _buildMiniFab(
          icon: Icons.chat_bubble_rounded,
          label: 'chat'.tr,
          onTap: () {
            _controller.reverse();
            widget.onChat();
          },
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) => Transform.rotate(
            angle: _expandAnimation.value * 0.75,
            child: child,
          ),
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniFab({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      axisAlignment: 1,
      child: FadeTransition(
        opacity: _expandAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                onPressed: onTap,
                backgroundColor: AppColors.cardBackground,
                foregroundColor: AppColors.primaryAccent,
                child: Icon(icon, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.primaryBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _ProjectMediaSection extends StatelessWidget {
  const _ProjectMediaSection({required this.project});

  final ProjectDocument project;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, color: AppColors.primaryAccent, size: 22),
                const SizedBox(width: 10),
                Text(
                  'project_media'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (project.imageUrls.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: project.imageUrls.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _openGallery(context, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      project.imageUrls[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (project.fileAttachments.isNotEmpty) ...[
            if (project.imageUrls.isNotEmpty) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (project.imageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'attachments'.tr,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ...project.fileAttachments.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _openUrl(f.url),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBackground.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.insert_drive_file, color: AppColors.primaryAccent, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  f.name.isNotEmpty ? f.name : 'file'.tr,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.download_rounded, size: 22, color: AppColors.primaryAccent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: index),
            itemCount: project.imageUrls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Image.network(project.imageUrls[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();
    final label = getProjectStatusNameById(status);
    final color = switch (status) {
      'in_progress' => AppColors.primaryAccent,
      'delivered' => Colors.blue,
      'completed' => Colors.green,
      'cancelled' => Colors.red,
      _ => AppColors.textSecondary,
    };
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _ReceiveProjectCard extends StatelessWidget {
  const _ReceiveProjectCard({
    required this.onConfirmReceipt,
    this.isConfirming = false,
  });

  final Future<void> Function() onConfirmReceipt;
  final bool isConfirming;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.2),
            AppColors.primaryAccent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.primaryAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'receive_project'.tr,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'confirm_receive_message'.tr,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isConfirming
                  ? null
                  : () => _showConfirmDialog(context),
              icon: isConfirming
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Icon(Icons.check_circle_outline, size: 22, color: Colors.black),
              label: Text(
                isConfirming ? 'processing'.tr : 'receive_project'.tr,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('confirm_receive'.tr, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'confirm_receive_message'.tr,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await onConfirmReceipt();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.black,
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.primaryAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'project_description'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.7,
                  fontSize: 15,
                ),
          ),
        ),
      ],
    );
  }
}

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: AppColors.primaryAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 24),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: widget.child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Non-collapsible details card for owner tabs
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.project});

  final ProjectDocument project;

  @override
  Widget build(BuildContext context) {
    final details = <Widget>[
      _DetailRow(icon: Icons.category_outlined, label: 'project_type'.tr, value: getProjectTypeNameById(project.projectType)),
      _DetailRow(icon: Icons.square_foot, label: 'land_area'.tr, value: '${project.landArea} ${'land_area_unit'.tr}'),
      _DetailRow(icon: Icons.location_on_outlined, label: 'city'.tr, value: project.city.isNotEmpty ? getCityNameById(project.city) : '-'),
    ];
    if (project.status.isNotEmpty) {
      details.add(_DetailRow(icon: Icons.flag_outlined, label: 'status'.tr, value: getProjectStatusNameById(project.status)));
    }
    if (project.budget != null && project.budget!.isNotEmpty) {
      details.add(_DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'expected_budget'.tr, value: getBudgetOptionNameById(project.budget!)));
    }
    if (project.deliveryDuration != null && project.deliveryDuration!.isNotEmpty) {
      details.add(_DetailRow(icon: Icons.schedule_outlined, label: 'expected_delivery'.tr, value: getDeliveryDurationNameById(project.deliveryDuration!)));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: AppColors.primaryAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  'project_details'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: details.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: d)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleDetails extends StatelessWidget {
  const _CollapsibleDetails({required this.project});

  final ProjectDocument project;

  @override
  Widget build(BuildContext context) {
    final details = <Widget>[
      _DetailRow(icon: Icons.category_outlined, label: 'project_type'.tr, value: getProjectTypeNameById(project.projectType)),
      _DetailRow(icon: Icons.square_foot, label: 'land_area'.tr, value: '${project.landArea} ${'land_area_unit'.tr}'),
      _DetailRow(icon: Icons.location_on_outlined, label: 'city'.tr, value: project.city.isNotEmpty ? getCityNameById(project.city) : '-'),
    ];
    if (project.status.isNotEmpty) {
      details.add(_DetailRow(icon: Icons.flag_outlined, label: 'status'.tr, value: getProjectStatusNameById(project.status)));
    }
    if (project.budget != null && project.budget!.isNotEmpty) {
      details.add(_DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'expected_budget'.tr, value: getBudgetOptionNameById(project.budget!)));
    }
    if (project.deliveryDuration != null && project.deliveryDuration!.isNotEmpty) {
      details.add(_DetailRow(icon: Icons.schedule_outlined, label: 'expected_delivery'.tr, value: getDeliveryDurationNameById(project.deliveryDuration!)));
    }

    return _CollapsibleSection(
      title: 'project_details'.tr,
      icon: Icons.info_outline_rounded,
      initiallyExpanded: false,
      child: Column(
        children: details.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: d)).toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAccent.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferExpandableDetails extends StatelessWidget {
  const _OfferExpandableDetails({required this.offer});

  final OfferDocument offer;

  @override
  Widget build(BuildContext context) {
    final hasContent = offer.message.isNotEmpty ||
        offer.imageUrls.isNotEmpty ||
        offer.fileAttachments.isNotEmpty;
    if (!hasContent) return const SizedBox.shrink();

    return _CollapsibleSection(
      title: 'offer_description'.tr,
      icon: Icons.description_outlined,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offer.message.isNotEmpty) ...[
            Text(
              offer.message,
              style: TextStyle(
                color: AppColors.textPrimary,
                height: 1.6,
                fontSize: 15,
              ),
            ),
            if (offer.imageUrls.isNotEmpty || offer.fileAttachments.isNotEmpty)
              const SizedBox(height: 16),
          ],
          if (offer.imageUrls.isNotEmpty) ...[
            Text(
              'offer_images'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: offer.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _showImageGallery(context, offer.imageUrls, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      offer.imageUrls[i],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            if (offer.fileAttachments.isNotEmpty) const SizedBox(height: 16),
          ],
          if (offer.fileAttachments.isNotEmpty) ...[
            Text(
              'attachments'.tr,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...offer.fileAttachments.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _openUrl(f.url),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_file, color: AppColors.primaryAccent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.name.isNotEmpty ? f.name : 'file'.tr,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageGallery(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: urls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Image.network(urls[i], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _AcceptedOfferCard extends StatelessWidget {
  const _AcceptedOfferCard({
    required this.offer,
    required this.projectStatus,
    required this.hasReviewed,
    required this.remainingTimeText,
    required this.isOwner,
    required this.onMarkDelivered,
    required this.onConfirmReceipt,
    required this.onAddReview,
    required this.onOpenChat,
    required this.onTapEngineer,
    this.onCancelProject,
    this.onRespondToCancel,
    this.hasPendingCancelRequest = false,
    this.isOtherPartyInCancel = false,
  });

  final OfferDocument offer;
  final String projectStatus;
  final bool hasReviewed;
  final String? remainingTimeText;
  final bool isOwner;
  final VoidCallback? onMarkDelivered;
  final Future<void> Function()? onConfirmReceipt;
  final VoidCallback? onAddReview;
  final VoidCallback? onOpenChat;
  final VoidCallback? onTapEngineer;
  final VoidCallback? onCancelProject;
  final VoidCallback? onRespondToCancel;
  final bool hasPendingCancelRequest;
  final bool isOtherPartyInCancel;

  @override
  Widget build(BuildContext context) {
    final isInProgress = projectStatus == 'in_progress';
    final isDelivered = projectStatus == 'delivered';
    final isCompleted = projectStatus == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primaryAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                'accepted_offer'.tr,
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (offer.message.isNotEmpty || offer.imageUrls.isNotEmpty || offer.fileAttachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OfferExpandableDetails(offer: offer),
          ],
          if (isOwner && onTapEngineer != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onTapEngineer,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                    backgroundImage: offer.engineerPhotoUrl != null ? NetworkImage(offer.engineerPhotoUrl!) : null,
                    child: offer.engineerPhotoUrl == null
                        ? Text(
                            (offer.engineerName ?? '?')[0].toUpperCase(),
                            style: TextStyle(color: AppColors.primaryAccent),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.engineerName ?? 'engineer'.tr,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'engineer_profile'.tr,
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
          if (remainingTimeText != null && (isInProgress || isDelivered)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 18, color: AppColors.primaryAccent),
                  const SizedBox(width: 8),
                  Text(
                    remainingTimeText!,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (onOpenChat != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text('chat'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryAccent,
                  side: BorderSide(color: AppColors.primaryAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (isInProgress && onMarkDelivered != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkDelivered,
                icon: const Icon(Icons.delivery_dining, size: 20),
                label: Text('deliver_project'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (isDelivered && isOwner && onConfirmReceipt != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showConfirmReceiptDialog(context, onConfirmReceipt!),
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: Text('receive_project'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (isCompleted && !hasReviewed && onAddReview != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddReview,
                icon: const Icon(Icons.star_outline, size: 20),
                label: Text('add_review'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryAccent,
                  side: BorderSide(color: AppColors.primaryAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if ((isInProgress || isDelivered) && (onCancelProject != null || onRespondToCancel != null)) ...[
            const SizedBox(height: 12),
            if (hasPendingCancelRequest && isOtherPartyInCancel && onRespondToCancel != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRespondToCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: Text('respond_to_cancel'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else if (hasPendingCancelRequest && !isOtherPartyInCancel)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'cancel_awaiting_other'.tr,
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (onCancelProject != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancelProject,
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: Text('cancel_project'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showConfirmReceiptDialog(BuildContext context, Future<void> Function() onConfirm) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('confirm_receive'.tr, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'confirm_receive_message'.tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryAccent, foregroundColor: Colors.black),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.project,
    required this.onAccept,
    required this.onReject,
    required this.onTapEngineer,
  });

  final OfferDocument offer;
  final ProjectDocument? project;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTapEngineer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTapEngineer,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryAccent.withValues(alpha: 0.2),
                  backgroundImage: offer.engineerPhotoUrl != null ? NetworkImage(offer.engineerPhotoUrl!) : null,
                  child: offer.engineerPhotoUrl == null
                      ? Text(
                          (offer.engineerName ?? '?')[0].toUpperCase(),
                          style: TextStyle(color: AppColors.primaryAccent),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.engineerName ?? 'engineer'.tr,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'engineer_profile'.tr,
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (offer.message.isNotEmpty || offer.imageUrls.isNotEmpty || offer.fileAttachments.isNotEmpty)
            _OfferExpandableDetails(offer: offer)
          else
            Text(
              offer.message,
              style: TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
          if (offer.proposedPrice != null && offer.proposedPrice!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${'proposed_price'.tr}: ${offer.proposedPrice}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
          if (offer.proposedDuration != null && offer.proposedDuration!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${'proposed_duration'.tr}: ${offer.proposedDuration}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                  ),
                  child: Text('reject'.tr),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('accept'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrowseListingCard extends StatelessWidget {
  const _BrowseListingCard({
    required this.project,
    required this.onHide,
    required this.onPublish,
  });

  final ProjectDocument project;
  final VoidCallback onHide;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                project.listed ? Icons.public_rounded : Icons.visibility_off_rounded,
                color: AppColors.primaryAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  project.listed ? 'project_listed_public'.tr : 'project_listed_private'.tr,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.listed ? 'project_listed_public_hint'.tr : 'project_listed_private_hint'.tr,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          if (project.listed)
            OutlinedButton.icon(
              onPressed: onHide,
              icon: const Icon(Icons.visibility_off_outlined, size: 20),
              label: Text('hide_project_action'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.glassBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: onPublish,
              icon: const Icon(Icons.publish_rounded, size: 20),
              label: Text('publish_project_action'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  final String title;
  final String content;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryAccent, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
