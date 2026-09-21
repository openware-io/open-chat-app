import 'package:flutter/material.dart';
import 'package:gv_ui/gv_ui.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/mock_service_category.dart';
import '../widgets/gv_nav_bar.dart';
import '../widgets/gv_search_bar.dart';

const _barAssets = [
  'assets/service_image/bar/image.jpg',
  'assets/service_image/bar/image (1).jpg',
  'assets/service_image/bar/image (2).jpg',
  'assets/service_image/bar/image (3).jpg',
  'assets/service_image/bar/image (4).jpg',
  'assets/service_image/bar/image (5).jpg',
];

const _poolHallAssets = [
  'assets/service_image/pool_hall/54d72afbd4d2442fa4ff1b11ae999c85.jpeg~tplv-0es2k971ck-downsize_wm_1_5_marc_b_3_RGwwMjEzTkExSmdtVjFxUVdXMFY=.png',
  'assets/service_image/pool_hall/6493a11b1f17491cab4bb44dba6bcc91.jpeg~tplv-0es2k971ck-downsize_wm_1_5_marc_b_3_RGwwMjEzTkExSmdtVjFxUVdXMFY=.png',
  'assets/service_image/pool_hall/e87d5610ddb24e9fa8b3926e9d17a6fe.jpeg~tplv-0es2k971ck-downsize_wm_1_5_marc_b_3_RGwwMjEzTkExSmdtVjFxUVdXMFY=.png',
];

const _hotelAssets = [
  'assets/service_image/hotel/1.jpg',
  'assets/service_image/hotel/2.jpg',
  'assets/service_image/hotel/3.jpg',
  'assets/service_image/hotel/4.jpg',
];

const _ktvAssets = [
  'assets/service_image/ktv/1.png',
  'assets/service_image/ktv/2.png',
  'assets/service_image/ktv/3.png',
  'assets/service_image/ktv/4.png',
];

const _footBathAssets = [
  'assets/service_image/foot_bath/1.png',
  'assets/service_image/foot_bath/2.png',
  'assets/service_image/foot_bath/3.png',
  'assets/service_image/foot_bath/4.png',
];

class MockVenueListScreen extends StatefulWidget {
  const MockVenueListScreen({super.key, required this.category});

  final MockServiceCategory category;

  @override
  State<MockVenueListScreen> createState() => _MockVenueListScreenState();
}

class _MockVenueListScreenState extends State<MockVenueListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int _sortIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = _categoryTitle(l10n, widget.category);
    final venues = _filteredVenues(l10n);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: title, showBack: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: Column(
            children: [
              GvSearchBar(
                controller: _searchController,
                hint: l10n.serviceVenueSearchHint(title),
                onChanged: (value) => setState(() => _query = value),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  GvSpacing.page,
                  GvSpacing.xs,
                  GvSpacing.page,
                  GvSpacing.sm,
                ),
                child: Row(
                  children: [
                    l10n.serviceVenueSmartSort,
                    l10n.serviceDemoFilterNearby,
                    l10n.serviceDemoFilterTopRated,
                    l10n.serviceVenueFilter,
                  ].asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: GvSpacing.sm),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _sortIndex == entry.key,
                        onSelected: (_) =>
                            setState(() => _sortIndex = entry.key),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ),
              Expanded(
                child: venues.isEmpty
                    ? Center(
                        child: Text(
                          l10n.serviceDemoNoResults,
                          style: GvTypography.body(
                            AppColors.textSecondary.resolveFrom(context),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          GvSpacing.page,
                          0,
                          GvSpacing.page,
                          GvSpacing.lg,
                        ),
                        itemCount: venues.length,
                        itemBuilder: (context, index) {
                          final venue = venues[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: GvSpacing.sm),
                            child: _VenueListCard(
                              venue: venue,
                              onTap: () => _openVenue(context, venue),
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

  List<_MockVenue> _filteredVenues(AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    final venues = _buildVenueCatalog(l10n, widget.category)
        .where(
          (venue) => query.isEmpty || venue.name.toLowerCase().contains(query),
        )
        .toList(growable: false);
    if (_sortIndex == 1) {
      venues.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (_sortIndex == 2) {
      venues.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortIndex == 3) {
      venues.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    return venues;
  }

  void _openVenue(BuildContext context, _MockVenue venue) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.category == MockServiceCategory.hotel ||
                widget.category == MockServiceCategory.ktv
            ? _MockBookableVenueDetailScreen(
                category: widget.category,
                venue: venue,
              )
            : _MockVenueDetailScreen(venue: venue),
      ),
    );
  }
}

class _VenueListCard extends StatelessWidget {
  const _VenueListCard({required this.venue, required this.onTap});

  final _MockVenue venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GvRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GvRadii.input),
                    child: _VenueAssetImage(
                      path: venue.imagePaths.first,
                      width: 104,
                      height: 104,
                    ),
                  ),
                  const SizedBox(width: GvSpacing.page),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GvTypography.body(textPrimary).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: GvSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 18, color: primary),
                            const SizedBox(width: 2),
                            Text(
                              venue.rating.toStringAsFixed(1),
                              style: GvTypography.caption(primary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: GvSpacing.sm),
                            Expanded(
                              child: Text(
                                l10n.serviceVenueDistance(
                                  venue.distanceKm.toStringAsFixed(1),
                                ),
                                textAlign: TextAlign.end,
                                style: GvTypography.small(textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: GvSpacing.xs),
                        Text(
                          venue.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GvTypography.small(textSecondary),
                        ),
                        const SizedBox(height: GvSpacing.sm),
                        Wrap(
                          spacing: GvSpacing.xs,
                          runSpacing: GvSpacing.xs,
                          children: [
                            _Tag(label: l10n.serviceVenueFeaturedMerchant),
                            _Tag(label: l10n.serviceVenueCleanTag),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GvSpacing.sm),
              Text(
                venue.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GvTypography.caption(textSecondary),
              ),
              const Divider(height: GvSpacing.lg),
              ...venue.deals.take(2).map(
                    (deal) => Padding(
                      padding: const EdgeInsets.only(bottom: GvSpacing.xs),
                      child: Row(
                        children: [
                          Text(
                            deal.priceYuan == 0
                                ? l10n.serviceDemoFree
                                : l10n.serviceBookingPrice(deal.priceYuan),
                            style: GvTypography.body(primary).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: GvSpacing.sm),
                          Expanded(
                            child: Text(
                              deal.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GvTypography.caption(textPrimary),
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
  }
}

class _MockBookableVenueDetailScreen extends StatefulWidget {
  const _MockBookableVenueDetailScreen({
    required this.category,
    required this.venue,
  });

  final MockServiceCategory category;
  final _MockVenue venue;

  @override
  State<_MockBookableVenueDetailScreen> createState() =>
      _MockBookableVenueDetailScreenState();
}

class _MockBookableVenueDetailScreenState
    extends State<_MockBookableVenueDetailScreen> {
  int? _selectedIndex;
  DateTime? _bookingTime;

  bool get _isHotel => widget.category == MockServiceCategory.hotel;

  _MockVenueDeal? get _selectedDeal =>
      _selectedIndex == null ? null : widget.venue.deals[_selectedIndex!];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    final primary = AppColors.primary.resolveFrom(context);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 270,
            flexibleSpace: FlexibleSpaceBar(
              background: _VenueGallery(paths: widget.venue.imagePaths),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: GvLayout.desktopContentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(GvSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.venue.name,
                              style: GvTypography.title(textPrimary).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: GvSpacing.sm),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: primary),
                                const SizedBox(width: GvSpacing.xs),
                                Text(
                                  widget.venue.rating.toStringAsFixed(1),
                                  style: GvTypography.body(textPrimary),
                                ),
                                const SizedBox(width: GvSpacing.sm),
                                Text(
                                  l10n.serviceVenueReviews(
                                    widget.venue.reviewCount,
                                  ),
                                  style: GvTypography.caption(textSecondary),
                                ),
                              ],
                            ),
                            const Divider(height: GvSpacing.lg * 2),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              title: l10n.serviceVenueAddress,
                              value: widget.venue.address,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: GvSpacing.lg),
                      Text(
                        _isHotel
                            ? l10n.serviceBookingHotelOptionsTitle
                            : l10n.serviceBookingKtvOptionsTitle,
                        style: GvTypography.title(textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: GvSpacing.sm),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.venue.deals.length,
                        itemBuilder: (context, index) {
                          final deal = widget.venue.deals[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: GvSpacing.sm),
                            child: _BookingOptionCard(
                              deal: deal,
                              selected: _selectedIndex == index,
                              onTap: () => setState(() {
                                _selectedIndex = index;
                                _bookingTime = null;
                              }),
                            ),
                          );
                        },
                      ),
                      if (_selectedDeal != null) ...[
                        const SizedBox(height: GvSpacing.sm),
                        _SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.serviceBookingPayment,
                                style: GvTypography.body(textPrimary).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: GvSpacing.sm),
                              Text(
                                l10n.serviceDemoFree,
                                style: GvTypography.title(primary).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Divider(height: GvSpacing.lg * 2),
                              Text(
                                _isHotel
                                    ? l10n.serviceBookingHotelTimeLabel
                                    : l10n.serviceBookingKtvTimeLabel,
                                style: GvTypography.body(textPrimary).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: GvSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: _chooseBookingTime,
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  _bookingTime == null
                                      ? l10n.serviceBookingChooseTime
                                      : _formatBookingTime(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: GvSpacing.sm),
                      Text(
                        l10n.serviceBookingMockNotice,
                        textAlign: TextAlign.center,
                        style: GvTypography.small(textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: FilledButton(
            onPressed: _selectedDeal != null && _bookingTime != null
                ? _submitReservation
                : null,
            child: Text(l10n.serviceBookingReserve),
          ),
        ),
      ),
    );
  }

  Future<void> _chooseBookingTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _bookingTime ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _bookingTime == null
          ? TimeOfDay.fromDateTime(now)
          : TimeOfDay.fromDateTime(_bookingTime!),
    );
    if (time == null || !mounted) return;
    setState(() {
      _bookingTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatBookingTime(BuildContext context) {
    final value = _bookingTime!;
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(value)} '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  void _submitReservation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MockReservationSuccessScreen(
          category: widget.category,
          venue: widget.venue,
          deal: _selectedDeal!,
          bookingTime: _bookingTime!,
        ),
      ),
    );
  }
}

class _BookingOptionCard extends StatelessWidget {
  const _BookingOptionCard({
    required this.deal,
    required this.selected,
    required this.onTap,
  });

  final _MockVenueDeal deal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GvRadii.card),
        side: BorderSide(
          color: selected ? primary : Colors.transparent,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GvRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(GvRadii.input),
                child: _VenueAssetImage(
                  path: deal.imagePath,
                  width: 96,
                  height: 88,
                ),
              ),
              const SizedBox(width: GvSpacing.page),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.title,
                      style: GvTypography.body(textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.xs),
                    Text(
                      deal.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.small(textSecondary),
                    ),
                    const SizedBox(height: GvSpacing.sm),
                    Text(
                      l10n.serviceDemoFree,
                      style: GvTypography.body(primary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? primary : textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockReservationSuccessScreen extends StatelessWidget {
  const _MockReservationSuccessScreen({
    required this.category,
    required this.venue,
    required this.deal,
    required this.bookingTime,
  });

  final MockServiceCategory category;
  final _MockVenue venue;
  final _MockVenueDeal deal;
  final DateTime bookingTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    final localizations = MaterialLocalizations.of(context);
    final time = '${localizations.formatMediumDate(bookingTime)} '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(bookingTime))}';
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.serviceBookingSuccessTitle,
        showBack: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(GvSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.check_circle, size: 88, color: primary),
                const SizedBox(height: GvSpacing.lg),
                Text(
                  l10n.serviceBookingSuccessTitle,
                  textAlign: TextAlign.center,
                  style: GvTypography.headline(textPrimary),
                ),
                const SizedBox(height: GvSpacing.sm),
                Text(
                  l10n.serviceBookingSuccessBody,
                  textAlign: TextAlign.center,
                  style: GvTypography.body(textSecondary),
                ),
                const SizedBox(height: GvSpacing.lg * 2),
                _SurfaceCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        label: l10n.serviceVenueOrderVenue,
                        value: venue.name,
                      ),
                      _DetailRow(
                        label: category == MockServiceCategory.hotel
                            ? l10n.serviceBookingHotelOptionLabel
                            : l10n.serviceBookingKtvOptionLabel,
                        value: deal.title,
                      ),
                      _DetailRow(
                        label: category == MockServiceCategory.hotel
                            ? l10n.serviceBookingHotelTimeLabel
                            : l10n.serviceBookingKtvTimeLabel,
                        value: time,
                      ),
                      _DetailRow(
                        label: l10n.serviceBookingPayment,
                        value: l10n.serviceDemoFree,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GvSpacing.lg),
                FilledButton(
                  onPressed: () => _backToVenueList(context),
                  child: Text(l10n.serviceVenueBackToList),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _backToVenueList(BuildContext context) {
    var poppedRoutes = 0;
    Navigator.of(context).popUntil((route) {
      if (poppedRoutes == 2) return true;
      poppedRoutes++;
      return false;
    });
  }
}

class _MockVenueDetailScreen extends StatelessWidget {
  const _MockVenueDetailScreen({required this.venue});

  final _MockVenue venue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 270,
            flexibleSpace: FlexibleSpaceBar(
              background: _VenueGallery(paths: venue.imagePaths),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: GvLayout.desktopContentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(GvSpacing.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              venue.name,
                              style: GvTypography.title(textPrimary).copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: GvSpacing.sm),
                            Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: AppColors.primary.resolveFrom(context),
                                ),
                                const SizedBox(width: GvSpacing.xs),
                                Text(
                                  venue.rating.toStringAsFixed(1),
                                  style: GvTypography.body(textPrimary),
                                ),
                                const SizedBox(width: GvSpacing.sm),
                                Text(
                                  l10n.serviceVenueReviews(venue.reviewCount),
                                  style: GvTypography.caption(textSecondary),
                                ),
                                const Spacer(),
                                Text(
                                  l10n.serviceDemoFree,
                                  style: GvTypography.body(
                                    AppColors.primary.resolveFrom(context),
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const Divider(height: GvSpacing.lg * 2),
                            _InfoRow(
                              icon: Icons.schedule,
                              title: l10n.serviceVenueOpen,
                              value: l10n.serviceVenueOpenAllDay,
                            ),
                            const SizedBox(height: GvSpacing.page),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              title: l10n.serviceVenueAddress,
                              value: venue.address,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: GvSpacing.lg),
                      Text(
                        l10n.serviceVenueDealsTitle(
                          venue.deals.length,
                        ),
                        style: GvTypography.title(textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: GvSpacing.sm),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: venue.deals.length,
                        itemBuilder: (context, index) {
                          final deal = venue.deals[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: GvSpacing.sm),
                            child: _DealCard(
                              deal: deal,
                              onTap: () => _openDeal(context, deal),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDeal(BuildContext context, _MockVenueDeal deal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MockDealDetailScreen(venue: venue, deal: deal),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal, required this.onTap});

  final _MockVenueDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return _SurfaceCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(GvRadii.input),
            child: _VenueAssetImage(
              path: deal.imagePath,
              width: 94,
              height: 94,
            ),
          ),
          const SizedBox(width: GvSpacing.page),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GvTypography.body(textPrimary).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                Text(
                  deal.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GvTypography.small(textSecondary),
                ),
                const SizedBox(height: GvSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.serviceDemoFree,
                        style: GvTypography.body(
                          AppColors.primary.resolveFrom(context),
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: onTap,
                      child: Text(l10n.serviceVenueBuyNow),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockDealDetailScreen extends StatelessWidget {
  const _MockDealDetailScreen({required this.venue, required this.deal});

  final _MockVenue venue;
  final _MockVenueDeal deal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.serviceVenueDealDetailTitle,
        showBack: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.only(bottom: GvSpacing.lg),
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: _VenueAssetImage(path: deal.imagePath),
              ),
              Padding(
                padding: const EdgeInsets.all(GvSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.serviceDemoFree,
                            style: GvTypography.headline(primary).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: GvSpacing.sm),
                          Text(
                            deal.title,
                            style: GvTypography.title(textPrimary).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: GvSpacing.sm),
                          Wrap(
                            spacing: GvSpacing.xs,
                            runSpacing: GvSpacing.xs,
                            children: [
                              _Tag(label: l10n.serviceVenueHotDeal),
                              _Tag(label: l10n.serviceVenueRefundAnytime),
                              _Tag(label: l10n.serviceVenueValidAnytime),
                            ],
                          ),
                          const SizedBox(height: GvSpacing.page),
                          Text(
                            deal.subtitle,
                            style: GvTypography.body(textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GvSpacing.sm),
                    _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.serviceVenuePackageDetails,
                            style: GvTypography.title(textPrimary).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: GvSpacing.lg),
                          _DetailRow(
                            label: l10n.serviceVenueDuration,
                            value: l10n.serviceVenueDurationValue,
                          ),
                          _DetailRow(
                            label: l10n.serviceVenueRoomType,
                            value: l10n.serviceVenueRoomTypeValue,
                          ),
                          _DetailRow(
                            label: l10n.serviceVenueApplicable,
                            value: l10n.serviceVenueApplicableValue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: GvSpacing.sm),
                    _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.serviceVenueAdditionalInfo,
                            style: GvTypography.title(textPrimary).copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: GvSpacing.sm),
                          Text(
                            l10n.serviceVenueAdditionalInfoBody,
                            style: GvTypography.body(textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _MockCheckoutScreen(
                  venue: venue,
                  deal: deal,
                ),
              ),
            ),
            child: Text(l10n.serviceVenueOrderNow),
          ),
        ),
      ),
    );
  }
}

class _MockCheckoutScreen extends StatefulWidget {
  const _MockCheckoutScreen({required this.venue, required this.deal});

  final _MockVenue venue;
  final _MockVenueDeal deal;

  @override
  State<_MockCheckoutScreen> createState() => _MockCheckoutScreenState();
}

class _MockCheckoutScreenState extends State<_MockCheckoutScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.serviceVenueCheckoutTitle,
        showBack: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(GvSpacing.page),
            children: [
              _SurfaceCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(GvRadii.input),
                      child: _VenueAssetImage(
                        path: widget.deal.imagePath,
                        width: 96,
                        height: 96,
                      ),
                    ),
                    const SizedBox(width: GvSpacing.page),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.deal.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GvTypography.body(textPrimary).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: GvSpacing.sm),
                          Text(
                            l10n.serviceDemoFree,
                            style: GvTypography.body(
                              AppColors.primary.resolveFrom(context),
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GvSpacing.sm),
              _SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.serviceVenueQuantity,
                            style: GvTypography.body(textPrimary),
                          ),
                        ),
                        IconButton.outlined(
                          tooltip: l10n.serviceVenueDecreaseQuantity,
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: GvTypography.body(textPrimary),
                          ),
                        ),
                        IconButton.filled(
                          tooltip: l10n.serviceVenueIncreaseQuantity,
                          onPressed: () => setState(() => _quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const Divider(height: GvSpacing.lg * 2),
                    _DetailRow(
                      label: l10n.serviceVenueTotal,
                      value: l10n.serviceDemoFree,
                    ),
                    _DetailRow(
                      label: l10n.serviceVenueDiscount,
                      value: l10n.serviceVenueFullDiscount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GvSpacing.sm),
              _SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.serviceVenuePurchaseNotice,
                      style: GvTypography.title(textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.sm),
                    Text(
                      l10n.serviceVenuePurchaseNoticeBody,
                      style: GvTypography.body(textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: FilledButton(
            onPressed: _submitOrder,
            child: Text(l10n.serviceVenueFreeOrderAction),
          ),
        ),
      ),
    );
  }

  void _submitOrder() {
    final orderNo = 'GV${DateTime.now().millisecondsSinceEpoch}';
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _MockOrderSuccessScreen(
          venue: widget.venue,
          deal: widget.deal,
          orderNo: orderNo,
        ),
      ),
    );
  }
}

class _MockOrderSuccessScreen extends StatelessWidget {
  const _MockOrderSuccessScreen({
    required this.venue,
    required this.deal,
    required this.orderNo,
  });

  final _MockVenue venue;
  final _MockVenueDeal deal;
  final String orderNo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.serviceVenueOrderSuccessTitle,
        showBack: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(GvSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.check_circle, size: 88, color: primary),
                const SizedBox(height: GvSpacing.lg),
                Text(
                  l10n.serviceVenueOrderSuccessTitle,
                  textAlign: TextAlign.center,
                  style: GvTypography.headline(textPrimary),
                ),
                const SizedBox(height: GvSpacing.sm),
                Text(
                  l10n.serviceVenueOrderSuccessBody,
                  textAlign: TextAlign.center,
                  style: GvTypography.body(textSecondary),
                ),
                const SizedBox(height: GvSpacing.lg * 2),
                _SurfaceCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        label: l10n.serviceVenueOrderVenue,
                        value: venue.name,
                      ),
                      _DetailRow(
                        label: l10n.serviceVenueOrderItem,
                        value: deal.title,
                      ),
                      _DetailRow(
                        label: l10n.serviceVenueOrderNumber,
                        value: orderNo,
                      ),
                      _DetailRow(
                        label: l10n.serviceVenueTotal,
                        value: l10n.serviceDemoFree,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GvSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  ),
                  child: Text(l10n.serviceVenueBackToList),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueGallery extends StatefulWidget {
  const _VenueGallery({required this.paths});

  final List<String> paths;

  @override
  State<_VenueGallery> createState() => _VenueGalleryState();
}

class _VenueGalleryState extends State<_VenueGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.paths.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) => _VenueAssetImage(
            path: widget.paths[index],
          ),
        ),
        Positioned(
          right: GvSpacing.page,
          bottom: GvSpacing.page,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(GvRadii.button),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GvSpacing.sm,
                vertical: GvSpacing.xs,
              ),
              child: Text(
                '${_index + 1}/${widget.paths.length}',
                style: GvTypography.small(Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VenueAssetImage extends StatelessWidget {
  const _VenueAssetImage({
    required this.path,
    this.width,
    this.height,
  });

  final String path;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: AppColors.bgInput.resolveFrom(context),
        child: SizedBox(
          width: width,
          height: height,
          child: Icon(
            Icons.storefront_outlined,
            color: AppColors.textHint.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.bgWhite.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.card),
        boxShadow: GvShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(GvSpacing.lg),
        child: child,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GvRadii.compact),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GvSpacing.xs,
          vertical: 3,
        ),
        child: Text(label, style: GvTypography.small(primary)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary.resolveFrom(context)),
        const SizedBox(width: GvSpacing.sm),
        Text(
          title,
          style: GvTypography.body(
            AppColors.textPrimary.resolveFrom(context),
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: GvSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: GvTypography.body(
              AppColors.textSecondary.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GvSpacing.page),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: GvTypography.body(
                AppColors.textSecondary.resolveFrom(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GvTypography.body(
                AppColors.textPrimary.resolveFrom(context),
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryTitle(
  AppLocalizations l10n,
  MockServiceCategory category,
) {
  return switch (category) {
    MockServiceCategory.hotel => l10n.servicesHotel,
    MockServiceCategory.ktv => l10n.servicesKtv,
    MockServiceCategory.bar => l10n.servicesBar,
    MockServiceCategory.massage => l10n.servicesMassage,
    _ => l10n.servicesBilliards,
  };
}

List<_MockVenue> _buildVenueCatalog(
  AppLocalizations l10n,
  MockServiceCategory category,
) {
  final assets = switch (category) {
    MockServiceCategory.hotel => _hotelAssets,
    MockServiceCategory.ktv => _ktvAssets,
    MockServiceCategory.bar => _barAssets,
    MockServiceCategory.massage => _footBathAssets,
    _ => _poolHallAssets,
  };
  // These are frontend-only demo merchants. Use neutral A380 names so the
  // mock catalog does not resemble real businesses.
  final names = List.generate(
    4,
    (index) => 'A380${_categoryTitle(l10n, category)}${index + 1}',
    growable: false,
  );
  final addresses = [
    l10n.serviceVenueAddress1,
    l10n.serviceVenueAddress2,
    l10n.serviceVenueAddress3,
    l10n.serviceVenueAddress4,
  ];
  final descriptions = [
    l10n.serviceVenueDescription1,
    l10n.serviceVenueDescription2,
    l10n.serviceVenueDescription3,
    l10n.serviceVenueDescription4,
  ];
  final dealTitles = switch (category) {
    MockServiceCategory.hotel => [
        l10n.serviceVenueHotelOption1,
        l10n.serviceVenueHotelOption2,
        l10n.serviceVenueHotelOption3,
      ],
    MockServiceCategory.ktv => [
        l10n.serviceVenueKtvOption1,
        l10n.serviceVenueKtvOption2,
        l10n.serviceVenueKtvOption3,
      ],
    MockServiceCategory.bar => [
        l10n.serviceVenueBarDeal1,
        l10n.serviceVenueBarDeal2,
        l10n.serviceVenueBarDeal3,
      ],
    MockServiceCategory.massage => [
        l10n.serviceVenueFootBathDeal1,
        l10n.serviceVenueFootBathDeal2,
        l10n.serviceVenueFootBathDeal3,
      ],
    _ => [
        l10n.serviceVenuePoolDeal1,
        l10n.serviceVenuePoolDeal2,
        l10n.serviceVenuePoolDeal3,
      ],
  };
  return List.generate(names.length, (venueIndex) {
    final gallery = List.generate(
      assets.length,
      (index) => assets[(venueIndex + index) % assets.length],
      growable: false,
    );
    final deals = List.generate(
      dealTitles.length,
      (dealIndex) => _MockVenueDeal(
        title: dealTitles[dealIndex],
        subtitle: dealIndex.isEven
            ? l10n.serviceVenueDealSubtitle1
            : l10n.serviceVenueDealSubtitle2,
        imagePath: gallery[dealIndex % gallery.length],
        priceYuan: 0,
      ),
      growable: false,
    );
    return _MockVenue(
      name: names[venueIndex],
      address: addresses[venueIndex],
      description: descriptions[venueIndex],
      imagePaths: gallery,
      rating: 4.6 + (venueIndex % 3) * 0.1,
      reviewCount: 860 + venueIndex * 327,
      distanceKm: 0.6 + venueIndex * 0.8,
      deals: deals,
    );
  }, growable: false);
}

class _MockVenue {
  const _MockVenue({
    required this.name,
    required this.address,
    required this.description,
    required this.imagePaths,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.deals,
  });

  final String name;
  final String address;
  final String description;
  final List<String> imagePaths;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final List<_MockVenueDeal> deals;
}

class _MockVenueDeal {
  const _MockVenueDeal({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.priceYuan = 0,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final int priceYuan;
}
