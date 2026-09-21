import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/mock_service_category.dart';
import '../widgets/gv_nav_bar.dart';

/// 机票与打车的纯前端演示流程，不发起网络请求或创建真实订单。
String _travelPriceLabel(AppLocalizations l10n, int price) =>
    price == 0 ? l10n.serviceDemoFree : '¥$price';

class MockTravelSearchScreen extends StatefulWidget {
  const MockTravelSearchScreen({super.key, required this.category});

  final MockServiceCategory category;

  @override
  State<MockTravelSearchScreen> createState() => _MockTravelSearchScreenState();
}

class _MockTravelSearchScreenState extends State<MockTravelSearchScreen> {
  int _modeIndex = 0;
  int _fromIndex = 0;
  int _toIndex = 1;
  late DateTime _departureAt;

  bool get _isFlight => widget.category == MockServiceCategory.flights;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _departureAt = _isFlight
        ? DateTime(now.year, now.month, now.day + 1, 8)
        : now.add(const Duration(hours: 2));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final places = _places(l10n);
    final primary = AppColors.primary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    final modes = _isFlight
        ? [
            l10n.travelDomestic,
            l10n.travelInternational,
            l10n.travelRoundTrip,
            l10n.travelMultiCity,
            l10n.travelSpecialFare,
          ]
        : [
            l10n.travelInstantRide,
            l10n.travelAirportPickup,
            l10n.travelAirportDropoff,
          ];

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: _isFlight ? l10n.servicesFlights : l10n.servicesTaxi,
        showBack: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              GvSpacing.page,
              GvSpacing.sm,
              GvSpacing.page,
              GvSpacing.lg,
            ),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: modes.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: GvSpacing.sm),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _modeIndex == entry.key,
                        onSelected: (_) =>
                            setState(() => _modeIndex = entry.key),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ),
              const SizedBox(height: GvSpacing.sm),
              _TravelCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PlaceButton(
                            label: l10n.travelFrom,
                            place: places[_fromIndex],
                            alignEnd: false,
                            onTap: () => _selectPlace(from: true),
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.travelSwap,
                          onPressed: () => setState(() {
                            final previous = _fromIndex;
                            _fromIndex = _toIndex;
                            _toIndex = previous;
                          }),
                          icon: const Icon(Icons.swap_horiz_rounded),
                        ),
                        Expanded(
                          child: _PlaceButton(
                            label: l10n.travelTo,
                            place: places[_toIndex],
                            alignEnd: true,
                            onTap: () => _selectPlace(from: false),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: GvSpacing.lg * 2),
                    _PickerRow(
                      icon: _isFlight
                          ? Icons.calendar_month_outlined
                          : Icons.schedule_outlined,
                      label: _isFlight
                          ? l10n.travelDepartureDate
                          : l10n.travelPickupTime,
                      value: _formatDeparture(context),
                      onTap: _selectDeparture,
                    ),
                    const Divider(height: GvSpacing.lg * 2),
                    _PickerRow(
                      icon: _isFlight
                          ? Icons.airline_seat_recline_normal
                          : Icons.people_outline,
                      label: _isFlight
                          ? l10n.travelPassengerCabin
                          : l10n.travelPassengerCount,
                      value: _isFlight
                          ? l10n.travelEconomyCabin
                          : l10n.travelOnePassenger,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GvSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 17, color: textSecondary),
                  const SizedBox(width: GvSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.travelMockNotice,
                      style: GvTypography.small(textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GvSpacing.lg),
              FilledButton.icon(
                onPressed: _search,
                icon: Icon(
                  _isFlight ? Icons.flight_takeoff : Icons.local_taxi,
                ),
                label: Text(
                  _isFlight ? l10n.travelSearchFlights : l10n.travelSearchRides,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: GvSpacing.lg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_TravelPlace> _places(AppLocalizations l10n) {
    final airports = [
      _TravelPlace(l10n.travelShenzhen, l10n.travelShenzhenAirport, 'SZX'),
      _TravelPlace(l10n.travelChongqing, l10n.travelChongqingAirport, 'CKG'),
      _TravelPlace(l10n.travelGuangzhou, l10n.travelGuangzhouAirport, 'CAN'),
      _TravelPlace(l10n.travelShanghai, l10n.travelShanghaiAirport, 'SHA'),
    ];
    if (_isFlight) return airports;
    return [
      airports.first,
      _TravelPlace(l10n.travelFutianCbd, l10n.travelShenzhen, ''),
      _TravelPlace(l10n.travelShenzhenNorthStation, l10n.travelShenzhen, ''),
      _TravelPlace(l10n.travelNanshanSciencePark, l10n.travelShenzhen, ''),
    ];
  }

  Future<void> _selectPlace({required bool from}) async {
    final l10n = AppLocalizations.of(context)!;
    final places = _places(l10n);
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GvSpacing.lg,
                0,
                GvSpacing.lg,
                GvSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isFlight
                      ? l10n.travelSelectAirport
                      : l10n.travelSelectLocation,
                  style: GvTypography.title(
                    AppColors.textPrimary.resolveFrom(sheetContext),
                  ),
                ),
              ),
            ),
            ...places.asMap().entries.map(
                  (entry) => ListTile(
                    leading: Icon(
                      _isFlight
                          ? Icons.flight_takeoff_outlined
                          : Icons.location_on_outlined,
                    ),
                    title: Text(entry.value.title),
                    subtitle: Text(entry.value.subtitle),
                    trailing: entry.value.code.isEmpty
                        ? null
                        : Text(entry.value.code),
                    onTap: () => Navigator.pop(sheetContext, entry.key),
                  ),
                ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (from && selected == _toIndex || !from && selected == _fromIndex) {
      setState(() {
        final previous = _fromIndex;
        _fromIndex = _toIndex;
        _toIndex = previous;
      });
      return;
    }
    setState(() {
      if (from) {
        _fromIndex = selected;
      } else {
        _toIndex = selected;
      }
    });
  }

  Future<void> _selectDeparture() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _departureAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (date == null || !mounted) return;
    if (_isFlight) {
      setState(() => _departureAt = DateTime(date.year, date.month, date.day));
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departureAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _departureAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDeparture(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final date = material.formatMediumDate(_departureAt);
    if (_isFlight) return date;
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(_departureAt));
    return '$date $time';
  }

  void _search() {
    final places = _places(AppLocalizations.of(context)!);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MockTravelResultsScreen(
          search: _TravelSearch(
            category: widget.category,
            from: places[_fromIndex],
            to: places[_toIndex],
            departureAt: _departureAt,
          ),
        ),
      ),
    );
  }
}

class _MockTravelResultsScreen extends StatefulWidget {
  const _MockTravelResultsScreen({required this.search});

  final _TravelSearch search;

  @override
  State<_MockTravelResultsScreen> createState() =>
      _MockTravelResultsScreenState();
}

class _MockTravelResultsScreenState extends State<_MockTravelResultsScreen> {
  int _sortIndex = 0;
  late DateTime _selectedDate;

  bool get _isFlight => widget.search.category == MockServiceCategory.flights;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.search.departureAt;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _sortedOptions(l10n);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: _isFlight
            ? l10n.travelFlightResultsTitle
            : l10n.travelTaxiResultsTitle,
        showBack: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  GvSpacing.page,
                  GvSpacing.sm,
                  GvSpacing.page,
                  GvSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${widget.search.from.title} → ${widget.search.to.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.title(
                        AppColors.textPrimary.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: GvSpacing.xs),
                    Text(
                      l10n.travelMockNotice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.small(textSecondary),
                    ),
                  ],
                ),
              ),
              if (_isFlight)
                _DateStrip(
                  selected: _selectedDate,
                  onSelected: (value) => setState(() => _selectedDate = value),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
                child: Row(
                  children: [
                    l10n.travelSmartSort,
                    l10n.travelPriceSort,
                    _isFlight
                        ? l10n.travelDepartureSort
                        : l10n.travelRecommended,
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
              const SizedBox(height: GvSpacing.xs),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    GvSpacing.page,
                    GvSpacing.xs,
                    GvSpacing.page,
                    GvSpacing.lg,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: GvSpacing.sm),
                      child: _TravelOptionCard(
                        option: option,
                        isFlight: _isFlight,
                        onTap: () => _openDetail(option),
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

  List<_TravelOption> _sortedOptions(AppLocalizations l10n) {
    final options = _isFlight
        ? [
            _TravelOption(
              id: 'ZH9327',
              title: l10n.travelShenzhenAirlines,
              subtitle: 'ZH9327 · Airbus A320',
              startTime: '06:25',
              endTime: '08:35',
              duration: '2h 10m',
              price: 0,
              direct: true,
            ),
            _TravelOption(
              id: 'CZ3465',
              title: l10n.travelChinaSouthern,
              subtitle: 'CZ3465 · Airbus A321',
              startTime: '09:10',
              endTime: '11:25',
              duration: '2h 15m',
              price: 0,
              direct: true,
            ),
            _TravelOption(
              id: '9C8613',
              title: l10n.travelSpringAirlines,
              subtitle: '9C8613 · Airbus A320',
              startTime: '14:35',
              endTime: '17:00',
              duration: '2h 25m',
              price: 0,
              direct: true,
            ),
            _TravelOption(
              id: 'MF8382',
              title: l10n.travelXiamenAir,
              subtitle: 'MF8382 · Boeing 737-800',
              startTime: '20:20',
              endTime: '23:55',
              duration: '3h 35m',
              price: 0,
              direct: false,
            ),
          ]
        : [
            _TravelOption(
              id: 'ride-comfort',
              title: l10n.travelComfortCar,
              subtitle: 'BYD Han EV',
              startTime: '8 min',
              endTime: '42 min',
              duration: '34 min',
              price: 0,
              direct: true,
            ),
            _TravelOption(
              id: 'ride-business',
              title: l10n.travelBusinessCar,
              subtitle: 'Buick GL8',
              startTime: '12 min',
              endTime: '46 min',
              duration: '34 min',
              price: 0,
              direct: true,
            ),
            _TravelOption(
              id: 'ride-premium',
              title: l10n.travelPremiumCar,
              subtitle: 'Mercedes-Benz E-Class',
              startTime: '15 min',
              endTime: '49 min',
              duration: '34 min',
              price: 0,
              direct: true,
            ),
          ];
    if (_sortIndex == 1) {
      options.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortIndex == 2 && _isFlight) {
      options.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return options;
  }

  void _openDetail(_TravelOption option) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MockTravelDetailScreen(
          search: widget.search.copyWith(departureAt: _selectedDate),
          option: option,
        ),
      ),
    );
  }
}

class _MockTravelDetailScreen extends StatelessWidget {
  const _MockTravelDetailScreen({required this.search, required this.option});

  final _TravelSearch search;
  final _TravelOption option;

  bool get _isFlight => search.category == MockServiceCategory.flights;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fares = _fares(l10n);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: _isFlight ? l10n.travelFlightDetails : l10n.travelRideDetails,
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
              _TravelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${search.from.title} → ${search.to.title}',
                      style: GvTypography.title(textPrimary),
                    ),
                    const SizedBox(height: GvSpacing.lg),
                    Row(
                      children: [
                        _TimeBlock(
                          time: option.startTime,
                          place: search.from.subtitle,
                          alignEnd: false,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                _isFlight
                                    ? Icons.flight_takeoff
                                    : Icons.local_taxi,
                                color: AppColors.primary.resolveFrom(context),
                              ),
                              Text(
                                option.duration,
                                style: GvTypography.small(textSecondary),
                              ),
                            ],
                          ),
                        ),
                        _TimeBlock(
                          time: option.endTime,
                          place: search.to.subtitle,
                          alignEnd: true,
                        ),
                      ],
                    ),
                    const Divider(height: GvSpacing.lg * 2),
                    Text(
                      option.title,
                      style: GvTypography.body(textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GvSpacing.xs),
                    Text(option.subtitle,
                        style: GvTypography.small(textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: GvSpacing.page),
              Text(
                _isFlight ? l10n.travelFareOptions : l10n.travelIncludes,
                style: GvTypography.title(textPrimary),
              ),
              const SizedBox(height: GvSpacing.sm),
              if (_isFlight)
                ...fares.map(
                  (fare) => Padding(
                    padding: const EdgeInsets.only(bottom: GvSpacing.sm),
                    child: _FareCard(
                      fare: fare,
                      onBook: () => _openOrder(context, fare),
                    ),
                  ),
                )
              else
                _TravelCard(
                  child: Column(
                    children: [
                      _BenefitRow(
                        icon: Icons.people_outline,
                        text: l10n.travelVehicleCapacity,
                      ),
                      _BenefitRow(
                        icon: Icons.support_agent_outlined,
                        text: l10n.travelDriverService,
                      ),
                      _BenefitRow(
                        icon: Icons.event_available_outlined,
                        text: l10n.travelFreeCancellation,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isFlight
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(GvSpacing.page),
                child: FilledButton(
                  onPressed: () => _openOrder(
                    context,
                    _FarePlan(option.title, option.price),
                  ),
                  child: Text(
                    '${l10n.travelBook} · '
                    '${_travelPriceLabel(l10n, option.price)}',
                  ),
                ),
              ),
            ),
    );
  }

  List<_FarePlan> _fares(AppLocalizations l10n) => [
        _FarePlan(l10n.travelEconomyValue, 0),
        _FarePlan(l10n.travelEconomyFlexible, 0),
        _FarePlan(l10n.travelBusinessCabin, 0),
      ];

  void _openOrder(BuildContext context, _FarePlan fare) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MockTravelOrderScreen(
          search: search,
          option: option,
          fare: fare,
        ),
      ),
    );
  }
}

class _MockTravelOrderScreen extends StatefulWidget {
  const _MockTravelOrderScreen({
    required this.search,
    required this.option,
    required this.fare,
  });

  final _TravelSearch search;
  final _TravelOption option;
  final _FarePlan fare;

  @override
  State<_MockTravelOrderScreen> createState() => _MockTravelOrderScreenState();
}

class _MockTravelOrderScreenState extends State<_MockTravelOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _remarkController = TextEditingController();

  bool get _isFlight => widget.search.category == MockServiceCategory.flights;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.travelFillOrder, showBack: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GvLayout.desktopContentMaxWidth,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(GvSpacing.page),
              children: [
                Text(
                  l10n.travelTripSummary,
                  style: GvTypography.title(textPrimary),
                ),
                const SizedBox(height: GvSpacing.sm),
                _TravelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${widget.search.from.title} → ${widget.search.to.title}',
                        style: GvTypography.body(textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: GvSpacing.xs),
                      Text(
                        '${widget.option.title} · ${widget.fare.title}',
                        style: GvTypography.small(textSecondary),
                      ),
                      const SizedBox(height: GvSpacing.xs),
                      Text(
                        _formatDateTime(context, widget.search.departureAt),
                        style: GvTypography.small(textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GvSpacing.lg),
                Text(
                  _isFlight ? l10n.travelPassengerInfo : l10n.travelBookerInfo,
                  style: GvTypography.title(textPrimary),
                ),
                const SizedBox(height: GvSpacing.sm),
                _TravelCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: _isFlight
                              ? l10n.travelPassengerName
                              : l10n.travelBookerName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? l10n.travelNameRequired
                                : null,
                      ),
                      if (_isFlight) ...[
                        const SizedBox(height: GvSpacing.sm),
                        TextFormField(
                          controller: _idController,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9xX]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.travelIdNumber,
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? l10n.travelIdRequired
                                  : null,
                        ),
                      ],
                      const SizedBox(height: GvSpacing.sm),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.travelPhone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.isEmpty) return l10n.travelPhoneRequired;
                          if (!RegExp(r'^\+?[0-9 -]{7,20}$').hasMatch(phone)) {
                            return l10n.travelPhoneInvalid;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: GvSpacing.sm),
                      TextFormField(
                        controller: _remarkController,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.travelRemark,
                          prefixIcon: const Icon(Icons.edit_note_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GvSpacing.sm),
                Text(
                  l10n.travelMockNotice,
                  style: GvTypography.small(textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: FilledButton(
            onPressed: _submit,
            child: Text(
              '${l10n.travelSubmitOrder} · '
              '${_travelPriceLabel(l10n, widget.fare.price)}',
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _MockTravelSuccessScreen(
          search: widget.search,
          option: widget.option,
          fare: widget.fare,
          bookerName: _nameController.text.trim(),
          orderNo: 'GV${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }
}

class _MockTravelSuccessScreen extends StatelessWidget {
  const _MockTravelSuccessScreen({
    required this.search,
    required this.option,
    required this.fare,
    required this.bookerName,
    required this.orderNo,
  });

  final _TravelSearch search;
  final _TravelOption option;
  final _FarePlan fare;
  final String bookerName;
  final String orderNo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.travelOrderSuccessTitle, showBack: true),
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
                  l10n.travelOrderSuccessTitle,
                  textAlign: TextAlign.center,
                  style: GvTypography.headline(textPrimary),
                ),
                const SizedBox(height: GvSpacing.sm),
                Text(
                  l10n.travelOrderSuccessBody,
                  textAlign: TextAlign.center,
                  style: GvTypography.body(textSecondary),
                ),
                const SizedBox(height: GvSpacing.lg * 2),
                _TravelCard(
                  child: Column(
                    children: [
                      _SummaryRow(
                          label: l10n.travelOrderNumber, value: orderNo),
                      _SummaryRow(
                        label: l10n.travelItinerary,
                        value: '${search.from.title} → ${search.to.title}',
                      ),
                      _SummaryRow(
                        label: l10n.travelTraveler,
                        value: bookerName,
                      ),
                      _SummaryRow(
                        label: l10n.travelTotal,
                        value: _travelPriceLabel(l10n, fare.price),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GvSpacing.lg),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.services),
                  child: Text(l10n.travelBackServices),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selected, required this.onSelected});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime(
            selected.year,
            selected.month,
            selected.day + index - 2,
          );
          final active = _sameDay(date, selected);
          return Padding(
            padding: const EdgeInsets.only(right: GvSpacing.sm),
            child: ChoiceChip(
              selected: active,
              onSelected: (_) => onSelected(date),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(material.narrowWeekdays[date.weekday % 7]),
                  Text(material.formatCompactDate(date)),
                  Text(l10n.serviceDemoFree),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TravelOptionCard extends StatelessWidget {
  const _TravelOptionCard({
    required this.option,
    required this.isFlight,
    required this.onTap,
  });

  final _TravelOption option;
  final bool isFlight;
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
                children: [
                  Icon(
                    isFlight
                        ? Icons.flight_outlined
                        : Icons.local_taxi_outlined,
                    color: primary,
                  ),
                  const SizedBox(width: GvSpacing.sm),
                  Expanded(
                    child: Text(
                      option.title,
                      style: GvTypography.body(textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _travelPriceLabel(l10n, option.price),
                    style: GvTypography.title(primary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GvSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option.startTime,
                      style: GvTypography.title(textPrimary),
                    ),
                  ),
                  Text(
                    isFlight
                        ? option.direct
                            ? l10n.travelDirectFlight
                            : l10n.travelTransfer
                        : option.duration,
                    style: GvTypography.small(textSecondary),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: GvSpacing.sm),
                    child: Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                  Expanded(
                    child: Text(
                      option.endTime,
                      textAlign: TextAlign.end,
                      style: GvTypography.title(textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GvSpacing.sm),
              Text(option.subtitle, style: GvTypography.small(textSecondary)),
              const SizedBox(height: GvSpacing.sm),
              Wrap(
                spacing: GvSpacing.xs,
                runSpacing: GvSpacing.xs,
                children: [
                  _Pill(
                    text: isFlight
                        ? l10n.travelBaggage
                        : l10n.travelVehicleCapacity,
                  ),
                  _Pill(text: l10n.travelRefundable),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({required this.fare, required this.onBook});

  final _FarePlan fare;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return _TravelCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fare.title,
                  style: GvTypography.body(textPrimary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                Text(l10n.travelBaggage,
                    style: GvTypography.small(textSecondary)),
                Text(
                  l10n.travelRefundable,
                  style: GvTypography.small(textSecondary),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                _travelPriceLabel(l10n, fare.price),
                style: GvTypography.title(primary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: GvSpacing.xs),
              FilledButton(onPressed: onBook, child: Text(l10n.travelBook)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceButton extends StatelessWidget {
  const _PlaceButton({
    required this.label,
    required this.place,
    required this.alignEnd,
    required this.onTap,
  });

  final String label;
  final _TravelPlace place;
  final bool alignEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GvRadii.input),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GvSpacing.sm),
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label, style: GvTypography.small(textSecondary)),
            const SizedBox(height: GvSpacing.xs),
            Text(
              place.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GvTypography.headline(textPrimary),
            ),
            const SizedBox(height: GvSpacing.xs),
            Text(
              place.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GvTypography.small(textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.time,
    required this.place,
    required this.alignEnd,
  });

  final String time;
  final String place;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary.resolveFrom(context);
    final textSecondary = AppColors.textSecondary.resolveFrom(context);
    return Expanded(
      flex: 2,
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(time, style: GvTypography.headline(textPrimary)),
          Text(
            place,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: GvTypography.small(textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GvSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.resolveFrom(context)),
          const SizedBox(width: GvSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GvSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: GvTypography.small(
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(GvRadii.compact),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GvSpacing.sm,
          vertical: GvSpacing.xs,
        ),
        child: Text(text, style: GvTypography.small(primary)),
      ),
    );
  }
}

class _TravelCard extends StatelessWidget {
  const _TravelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: Padding(
        padding: const EdgeInsets.all(GvSpacing.page),
        child: child,
      ),
    );
  }
}

class _TravelPlace {
  const _TravelPlace(this.title, this.subtitle, this.code);

  final String title;
  final String subtitle;
  final String code;
}

class _TravelSearch {
  const _TravelSearch({
    required this.category,
    required this.from,
    required this.to,
    required this.departureAt,
  });

  final MockServiceCategory category;
  final _TravelPlace from;
  final _TravelPlace to;
  final DateTime departureAt;

  _TravelSearch copyWith({DateTime? departureAt}) => _TravelSearch(
        category: category,
        from: from,
        to: to,
        departureAt: departureAt ?? this.departureAt,
      );
}

class _TravelOption {
  const _TravelOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.price,
    required this.direct,
  });

  final String id;
  final String title;
  final String subtitle;
  final String startTime;
  final String endTime;
  final String duration;
  final int price;
  final bool direct;
}

class _FarePlan {
  const _FarePlan(this.title, this.price);

  final String title;
  final int price;
}

String _formatDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final date = material.formatMediumDate(value);
  final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(value));
  return '$date $time';
}
