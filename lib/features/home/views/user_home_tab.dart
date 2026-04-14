import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/home_categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/browse_engineers_controller.dart';

/// User home tab - search, filter by major, ads banner, engineer cards
class UserHomeTab extends GetView<BrowseEngineersController> {
  const UserHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchBar(controller: controller),
        _FilterCards(controller: controller),
        _AdsBanner(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const _EngineersShimmer();
            }
            final list = controller.filteredEngineers;
            if (list.isEmpty) {
              return _EmptyEngineers();
            }
            return _EngineersList(engineers: list);
          }),
        ),
      ],
    );
  }
}

const double _homeCardRadius = 20;

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final BrowseEngineersController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: TextField(
        onChanged: controller.setSearch,
        decoration: InputDecoration(
          hintText: 'search_engineers_placeholder'.tr,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 8),
            child: Icon(Icons.search_rounded, size: 22, color: AppColors.primaryAccent),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_homeCardRadius),
            borderSide: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_homeCardRadius),
            borderSide: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_homeCardRadius),
            borderSide: BorderSide(color: AppColors.primaryAccent.withValues(alpha: 0.65), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.25),
      ),
    );
  }
}

class _FilterCards extends StatelessWidget {
  const _FilterCards({required this.controller});

  final BrowseEngineersController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Obx(() {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final major in homeMajorCards)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: _FilterCard(
                    major: major,
                    isSelected: controller.selectedSpecializationId.value == major.id,
                    onTap: () {
                      controller.setSpecialization(
                        controller.selectedSpecializationId.value == major.id ? null : major.id,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.major,
    required this.isSelected,
    required this.onTap,
  });

  final HomeMajorCard major;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 78,
        height: 86,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    major.color.withValues(alpha: 0.35),
                    major.color.withValues(alpha: 0.18),
                  ]
                : [
                    AppColors.cardBackground,
                    AppColors.surfaceTint,
                  ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? major.color : AppColors.glassBorder.withValues(alpha: 0.9),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: major.color.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppColors.cardDropShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: major.color.withValues(alpha: isSelected ? 0.28 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(major.icon, color: major.color, size: 24),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                major.name,
                style: TextStyle(
                  color: isSelected ? major.color : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdsBanner extends StatefulWidget {
  @override
  State<_AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends State<_AdsBanner> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _banners = [
    _BannerData(
      titleAr: 'معك لبناء مستقبك',
      titleEn: 'With you to build your future',
      gradient: [Color(0xFF0F172A), Color(0xFF1E40AF)],
      accent: Color(0xFFFBBF24),
    ),
    _BannerData(
      titleAr: 'مهندسون متخصصون',
      titleEn: 'Specialized engineers',
      gradient: [Color(0xFF134E4A), Color(0xFF0F766E)],
      accent: Color(0xFF5EEAD4),
    ),
    _BannerData(
      titleAr: 'جودة وضمان',
      titleEn: 'Quality and guarantee',
      gradient: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
      accent: Color(0xFFE9D5FF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 152,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _banners.length,
              itemBuilder: (_, i) {
                final b = _banners[i];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: b.gradient,
                      ),
                      borderRadius: BorderRadius.circular(_homeCardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: b.gradient.last.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_homeCardRadius),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: CircleAvatar(
                              radius: 72,
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -40,
                            child: Icon(
                              Icons.engineering_rounded,
                              size: 120,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: b.accent.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: b.accent.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Text(
                                      'app_name'.tr,
                                      style: TextStyle(
                                        color: b.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    Get.locale?.languageCode == 'ar' ? b.titleAr : b.titleEn,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active
                      ? AppColors.primaryAccent
                      : AppColors.textSecondary.withValues(alpha: 0.35),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.titleAr,
    required this.titleEn,
    required this.gradient,
    required this.accent,
  });
  final String titleAr;
  final String titleEn;
  final List<Color> gradient;
  final Color accent;
}

class _EngineersShimmer extends StatelessWidget {
  const _EngineersShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBackground,
      highlightColor: AppColors.glassBorder,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: 5,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShimmerCard(),
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
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

class _EmptyEngineers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.engineering_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'no_engineers_match'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'try_different_search'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EngineersList extends StatelessWidget {
  const _EngineersList({required this.engineers});

  final List<EngineerCardData> engineers;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Get.find<BrowseEngineersController>().load(),
      color: AppColors.primaryAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: engineers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'specialized_engineers'.tr,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 14),
                    child: Text(
                      'browse_trusted_engineers_hint'.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                    ),
                  ),
                ],
              ),
            );
          }
          final e = engineers[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EngineerCard(data: e),
          );
        },
      ),
    );
  }
}

class _EngineerCard extends StatelessWidget {
  const _EngineerCard({required this.data});

  final EngineerCardData data;

  @override
  Widget build(BuildContext context) {
    final engineer = data.user;
    return AsasCard(
      borderRadius: _homeCardRadius,
      padding: const EdgeInsets.all(14),
      onTap: () => Get.toNamed('/engineer-profile', arguments: engineer.uid),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryAccent.withValues(alpha: 0.35),
                  AppColors.secondaryAccent.withValues(alpha: 0.15),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: engineer.photoUrl != null && engineer.photoUrl!.isNotEmpty
                  ? (engineer.photoUrl!.startsWith('http')
                      ? Image.network(
                          engineer.photoUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(engineer.photoUrl!),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ))
                  : Container(
                      width: 72,
                      height: 72,
                      color: AppColors.primaryBackground,
                      child: Icon(Icons.person_rounded, color: AppColors.primaryAccent, size: 38),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  engineer.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (engineer.specialization != null && engineer.specialization!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.8)),
                    ),
                    child: Text(
                      engineer.specialization!,
                      style: TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < data.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 15,
                              color: i < data.rating.round()
                                  ? AppColors.primaryAccent
                                  : AppColors.textSecondary.withValues(alpha: 0.45),
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            data.rating > 0 ? data.rating.toStringAsFixed(1) : '-',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (data.minPrice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'starts_from'.trParams({'price': data.minPrice!.toStringAsFixed(0)}),
                    style: TextStyle(
                      color: AppColors.secondaryAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.7)),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }
}
