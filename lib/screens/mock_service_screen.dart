import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/mock_service_category.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_search_bar.dart';
import 'mock_travel_flow_screens.dart';
import 'mock_venue_flow_screens.dart';

/// 服务页尚未接入后端能力的本地演示页。
///
/// 页面不发起网络请求，也不会产生真实订单或费用。
class MockServiceScreen extends StatefulWidget {
  const MockServiceScreen({super.key, required this.category});

  final MockServiceCategory category;

  @override
  State<MockServiceScreen> createState() => _MockServiceScreenState();
}

class _MockServiceScreenState extends State<MockServiceScreen> {
  final _searchController = TextEditingController();
  final _completedIds = <int>{};
  String _query = '';
  int _filterIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryTitle(AppLocalizations l10n) {
    return switch (widget.category) {
      MockServiceCategory.coupons => l10n.pointsCoupons,
      MockServiceCategory.hotel => l10n.servicesHotel,
      MockServiceCategory.ktv => l10n.servicesKtv,
      MockServiceCategory.bar => l10n.servicesBar,
      MockServiceCategory.billiards => l10n.servicesBilliards,
      MockServiceCategory.food => l10n.servicesFood,
      MockServiceCategory.delivery => l10n.servicesDelivery,
      MockServiceCategory.flashSale => l10n.servicesFlashSale,
      MockServiceCategory.boutique => l10n.servicesBoutique,
      MockServiceCategory.massage => l10n.servicesMassage,
      MockServiceCategory.flights => l10n.servicesFlights,
      MockServiceCategory.taxi => l10n.servicesTaxi,
    };
  }

  IconData get _categoryIcon {
    return switch (widget.category) {
      MockServiceCategory.coupons => Icons.confirmation_number_outlined,
      MockServiceCategory.hotel => Icons.hotel_outlined,
      MockServiceCategory.ktv => Icons.mic_external_on_outlined,
      MockServiceCategory.bar => Icons.local_bar_outlined,
      MockServiceCategory.billiards => Icons.sports_outlined,
      MockServiceCategory.food => Icons.restaurant_outlined,
      MockServiceCategory.delivery => Icons.delivery_dining_outlined,
      MockServiceCategory.flashSale => Icons.bolt_outlined,
      MockServiceCategory.boutique => Icons.storefront_outlined,
      MockServiceCategory.massage => Icons.spa_outlined,
      MockServiceCategory.flights => Icons.flight_takeoff_outlined,
      MockServiceCategory.taxi => Icons.local_taxi_outlined,
    };
  }

  List<_MockServiceItem> _items(AppLocalizations l10n) {
    final title = _categoryTitle(l10n);
    if (widget.category == MockServiceCategory.coupons) {
      return [
        _MockServiceItem(
          id: 1,
          title: l10n.serviceDemoCouponNewUser,
          subtitle: l10n.serviceDemoCouponNoThreshold,
          couponAmount: '20',
          rating: '5.0',
          sold: 1286,
        ),
        _MockServiceItem(
          id: 2,
          title: l10n.serviceDemoCouponDining,
          subtitle: l10n.serviceDemoCouponThreshold('100'),
          couponAmount: '30',
          rating: '4.9',
          sold: 864,
        ),
        _MockServiceItem(
          id: 3,
          title: l10n.serviceDemoCouponTravel,
          subtitle: l10n.serviceDemoCouponThreshold('300'),
          couponAmount: '50',
          rating: '4.8',
          sold: 529,
        ),
      ];
    }
    return [
      _MockServiceItem(
        id: 1,
        title: l10n.serviceDemoFeaturedItem(title),
        subtitle: l10n.serviceDemoQualityDescription,
        rating: '4.9',
        sold: 1286,
      ),
      _MockServiceItem(
        id: 2,
        title: l10n.serviceDemoPopularItem(title),
        subtitle: l10n.serviceDemoFastDescription,
        rating: '4.8',
        sold: 956,
      ),
      _MockServiceItem(
        id: 3,
        title: l10n.serviceDemoValueItem(title),
        subtitle: l10n.serviceDemoQualityDescription,
        rating: '4.7',
        sold: 731,
      ),
      _MockServiceItem(
        id: 4,
        title: l10n.serviceDemoNearbyItem(title),
        subtitle: l10n.serviceDemoFastDescription,
        rating: '4.9',
        sold: 428,
      ),
    ];
  }

  List<_MockServiceItem> _filteredItems(AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    final result = _items(l10n).where((item) {
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
    }).toList(growable: false);
    if (_filterIndex == 1) return result.reversed.toList(growable: false);
    if (_filterIndex == 2) {
      result.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return result;
  }

  Future<void> _completeItem(_MockServiceItem item) async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.category != MockServiceCategory.coupons) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.serviceDemoConfirmTitle),
          content: Text(l10n.serviceDemoConfirmBody(item.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.serviceDemoConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _completedIds.add(item.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.serviceDemoSuccess(item.title))),
      );
  }

  Future<void> _showCompletedItems() async {
    final l10n = AppLocalizations.of(context)!;
    final completed = _items(l10n)
        .where((item) => _completedIds.contains(item.id))
        .toList(growable: false);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GvSpacing.lg,
            0,
            GvSpacing.lg,
            GvSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.category == MockServiceCategory.coupons
                    ? l10n.serviceDemoMyCoupons
                    : l10n.serviceDemoMyOrders,
                style: GvTypography.title(
                  AppColors.textPrimary.resolveFrom(sheetContext),
                ),
              ),
              const SizedBox(height: GvSpacing.lg),
              if (completed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: GvSpacing.lg),
                  child: Text(
                    l10n.serviceDemoEmptyOrders,
                    textAlign: TextAlign.center,
                    style: GvTypography.body(
                      AppColors.textSecondary.resolveFrom(sheetContext),
                    ),
                  ),
                )
              else
                ...completed.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _categoryIcon,
                      color: AppColors.primary.resolveFrom(sheetContext),
                    ),
                    title: Text(item.title),
                    trailing:
                        const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.category == MockServiceCategory.flights ||
        widget.category == MockServiceCategory.taxi) {
      return MockTravelSearchScreen(category: widget.category);
    }
    if (widget.category == MockServiceCategory.hotel ||
        widget.category == MockServiceCategory.ktv ||
        widget.category == MockServiceCategory.bar ||
        widget.category == MockServiceCategory.billiards ||
        widget.category == MockServiceCategory.massage) {
      return MockVenueListScreen(category: widget.category);
    }
    final l10n = AppLocalizations.of(context)!;
    final title = _categoryTitle(l10n);
    final items = _filteredItems(l10n);
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: title,
        showBack: true,
        right: IconButton(
          tooltip: widget.category == MockServiceCategory.coupons
              ? l10n.serviceDemoMyCoupons
              : l10n.serviceDemoMyOrders,
          onPressed: _showCompletedItems,
          icon: Badge(
            isLabelVisible: _completedIds.isNotEmpty,
            label: Text('${_completedIds.length}'),
            child: Icon(
              widget.category == MockServiceCategory.coupons
                  ? Icons.confirmation_number_outlined
                  : Icons.receipt_long_outlined,
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: Column(
            children: [
              _DemoHero(
                title: l10n.serviceDemoHeroTitle(title),
                subtitle: l10n.serviceDemoHeroSubtitle,
                icon: _categoryIcon,
              ),
              GvSearchBar(
                controller: _searchController,
                hint: l10n.serviceDemoSearchHint(title),
                onChanged: (value) => setState(() => _query = value),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
                child: Row(
                  children: [
                    l10n.serviceDemoFilterRecommended,
                    l10n.serviceDemoFilterNearby,
                    l10n.serviceDemoFilterTopRated,
                  ].asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: GvSpacing.sm),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _filterIndex == entry.key,
                        onSelected: (_) =>
                            setState(() => _filterIndex = entry.key),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GvSpacing.page,
                  GvSpacing.sm,
                  GvSpacing.page,
                  GvSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: textSecondary),
                    const SizedBox(width: GvSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.serviceDemoMockNotice,
                        style: GvTypography.small(textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          l10n.serviceDemoNoResults,
                          style: GvTypography.body(textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          GvSpacing.page,
                          GvSpacing.sm,
                          GvSpacing.page,
                          GvSpacing.lg,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final completed = _completedIds.contains(item.id);
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: GvSpacing.sm),
                            child: _ServiceResultCard(
                              item: item,
                              icon: _categoryIcon,
                              primary: primary,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              completed: completed,
                              coupon: widget.category ==
                                  MockServiceCategory.coupons,
                              onTap: completed
                                  ? _showCompletedItems
                                  : () => _completeItem(item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoHero extends StatelessWidget {
  const _DemoHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary.resolveFrom(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        GvSpacing.page,
        GvSpacing.page,
        GvSpacing.page,
        GvSpacing.xs,
      ),
      padding: const EdgeInsets.all(GvSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(GvRadii.cardLg),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(GvSpacing.page),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: GvSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GvTypography.title(Colors.white).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                Text(
                  subtitle,
                  style: GvTypography.caption(
                    Colors.white.withValues(alpha: 0.82),
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

class _ServiceResultCard extends StatelessWidget {
  const _ServiceResultCard({
    required this.item,
    required this.icon,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.completed,
    required this.coupon,
    required this.onTap,
  });

  final _MockServiceItem item;
  final IconData icon;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final bool completed;
  final bool coupon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      elevation: 0,
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GvRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(GvRadii.input),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 34, color: primary),
              ),
              const SizedBox(width: GvSpacing.page),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.body(textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.xs),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.small(textSecondary),
                    ),
                    const SizedBox(height: GvSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: primary),
                        const SizedBox(width: 2),
                        Text(
                          l10n.serviceDemoRating(item.rating),
                          style: GvTypography.small(textSecondary),
                        ),
                        const SizedBox(width: GvSpacing.sm),
                        Text(
                          l10n.serviceDemoSold(item.sold),
                          style: GvTypography.small(textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: GvSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            coupon
                                ? l10n.serviceDemoCouponAmount(
                                    item.couponAmount ?? '0',
                                  )
                                : l10n.serviceDemoFree,
                            style: GvTypography.body(primary).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: onTap,
                          child: Text(
                            completed
                                ? l10n.serviceDemoDone
                                : coupon
                                    ? l10n.serviceDemoClaim
                                    : l10n.serviceDemoAction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockServiceItem {
  const _MockServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.couponAmount,
    required this.rating,
    required this.sold,
  });

  final int id;
  final String title;
  final String subtitle;
  final String? couponAmount;
  final String rating;
  final int sold;
}
