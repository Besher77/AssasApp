import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/saved_card_document.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/saved_cards_controller.dart';

class SavedCardsView extends GetView<SavedCardsController> {
  const SavedCardsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'payment_methods'.tr,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.addCard)?.then((_) {
              try {
                Get.find<SavedCardsController>().load();
              } catch (_) {}
            }),
            icon: Icon(Icons.add, color: AppColors.primaryAccent, size: 20),
            label: Text('add_new_card'.tr, style: TextStyle(color: AppColors.primaryAccent)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          );
        }
        if (controller.cards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_off_rounded, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'no_saved_cards'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'add_card_when_paying'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.addCard)?.then((_) {
                      try {
                        Get.find<SavedCardsController>().load();
                      } catch (_) {}
                    }),
                    icon: const Icon(Icons.add_card),
                    label: Text('add_new_card'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          color: AppColors.primaryAccent,
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: controller.cards.length,
            itemBuilder: (context, index) {
              final card = controller.cards[index];
              return _CardTile(
                card: card,
                onDelete: () => _confirmDelete(context, card),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, SavedCardDocument card) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('remove_card'.tr, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'remove_card_confirm'.tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteCard(card);
            },
            child: Text('remove'.tr, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.onDelete});

  final SavedCardDocument card;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.credit_card_rounded, color: AppColors.primaryAccent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.brand} •••• ${card.lastFour}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (card.name.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    card.name,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          ),
        ],
      ),
    );
  }
}
