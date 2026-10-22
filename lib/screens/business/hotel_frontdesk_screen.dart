import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/open_nav_bar.dart';

/// 酒店移动前台原型。
///
/// 数据全部为本地 mock，不调用后端；用于确认入住、押金、退房结算的交互。
/// 接入真实 BFF 后替换 [_bookings] / [_rooms] 的数据源即可。
class HotelFrontdeskScreen extends StatefulWidget {
  const HotelFrontdeskScreen({super.key});

  @override
  State<HotelFrontdeskScreen> createState() => _HotelFrontdeskScreenState();
}

class _HotelFrontdeskScreenState extends State<HotelFrontdeskScreen> {
  final List<_HotelBooking> _bookings = [
    _HotelBooking(
      bookingNo: 'H202610220001',
      guest: '王先生',
      phone: '138****6688',
      roomType: '豪华大床房',
      dates: '10-22 → 10-24',
      rooms: 1,
      amount: 736,
      deposit: 300,
      status: _HotelStatus.arrival,
      roomNo: '1208',
    ),
    _HotelBooking(
      bookingNo: 'H202610220002',
      guest: '李女士',
      phone: '139****2233',
      roomType: '景观双床房',
      dates: '10-22 → 10-23',
      rooms: 2,
      amount: 856,
      deposit: 600,
      status: _HotelStatus.inHouse,
      roomNo: '1506 / 1507',
    ),
    _HotelBooking(
      bookingNo: 'H202610220003',
      guest: '陈先生',
      phone: '137****9911',
      roomType: '行政套房',
      dates: '10-23 → 10-25',
      rooms: 1,
      amount: 1376,
      deposit: 500,
      status: _HotelStatus.confirmed,
      roomNo: '',
    ),
    _HotelBooking(
      bookingNo: 'H202610220004',
      guest: '周女士',
      phone: '136****5522',
      roomType: '豪华大床房',
      dates: '10-22 → 10-23',
      rooms: 1,
      amount: 368,
      deposit: 300,
      status: _HotelStatus.dueOut,
      roomNo: '0806',
    ),
  ];

  final List<_RoomState> _rooms = [
    const _RoomState('0801', _RoomStatus.available),
    const _RoomState('0802', _RoomStatus.occupied),
    const _RoomState('0803', _RoomStatus.cleaning),
    const _RoomState('0805', _RoomStatus.available),
    const _RoomState('0806', _RoomStatus.dueOut),
    const _RoomState('0808', _RoomStatus.occupied),
    const _RoomState('1201', _RoomStatus.available),
    const _RoomState('1202', _RoomStatus.occupied),
    const _RoomState('1203', _RoomStatus.available),
    const _RoomState('1205', _RoomStatus.maintenance),
    const _RoomState('1206', _RoomStatus.occupied),
    const _RoomState('1208', _RoomStatus.arrival),
  ];

  int get _arrivals =>
      _bookings.where((b) => b.status == _HotelStatus.arrival).length;
  int get _inHouse =>
      _bookings.where((b) => b.status == _HotelStatus.inHouse).length;
  int get _dueOut =>
      _bookings.where((b) => b.status == _HotelStatus.dueOut).length;

  void _checkIn(_HotelBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _CheckInSheet(
        booking: booking,
        onConfirm: () {
          setState(() {
            booking.status = _HotelStatus.inHouse;
            booking.roomNo = booking.roomNo.isEmpty ? '1208' : booking.roomNo;
          });
          Navigator.of(context).pop();
          _toast('${booking.guest} 已入住，已收取押金 \$${booking.deposit}');
        },
      ),
    );
  }

  void _checkOut(_HotelBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _CheckOutSheet(
        booking: booking,
        onConfirm: () {
          setState(() {
            booking.status = _HotelStatus.checkedOut;
          });
          Navigator.of(context).pop();
          _toast('${booking.guest} 已退房，押金已结算');
        },
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = gvPageScaffoldBackground(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: '酒店前台',
        backgroundColor: pageBg,
        right: TextButton(
          onPressed: () => _toast('原型：切换门店/交接班后续接入'),
          child: const Text('早班'),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary.resolveFrom(context),
        onRefresh: () async => _toast('原型数据已刷新'),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            GvSpacing.page,
            GvSpacing.sm,
            GvSpacing.page,
            GvSpacing.lg,
          ),
          children: [
            _MetricGrid(
              arrivals: _arrivals,
              inHouse: _inHouse,
              dueOut: _dueOut,
              occupancy: '75%',
            ),
            const SizedBox(height: GvSpacing.lg),
            _SectionTitle(title: '今日待办', trailing: '${_bookings.length} 条'),
            const SizedBox(height: GvSpacing.sm),
            ..._bookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: GvSpacing.sm),
                child: _BookingCard(
                  booking: booking,
                  onCheckIn: () => _checkIn(booking),
                  onCheckOut: () => _checkOut(booking),
                ),
              ),
            ),
            const SizedBox(height: GvSpacing.lg),
            _SectionTitle(title: '房态', trailing: '共 ${_rooms.length} 间'),
            const SizedBox(height: GvSpacing.sm),
            _RoomGrid(rooms: _rooms),
            const SizedBox(height: GvSpacing.lg),
            Text(
              '原型数据仅用于交互确认，不写入后端；押金/账单/房号在接入 BFF 后由真实接口返回。',
              style: GvTypography.small(secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.arrivals,
    required this.inHouse,
    required this.dueOut,
    required this.occupancy,
  });

  final int arrivals;
  final int inHouse;
  final int dueOut;
  final String occupancy;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: GvSpacing.sm,
      crossAxisSpacing: GvSpacing.sm,
      childAspectRatio: 1.9,
      children: [
        _MetricCard(label: '今日到店', value: '$arrivals', hint: '待办理入住'),
        _MetricCard(label: '在住', value: '$inHouse', hint: '含续住'),
        _MetricCard(label: '待退房', value: '$dueOut', hint: '今日离店'),
        _MetricCard(label: '出租率', value: occupancy, hint: '实时房态'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final card = AppColors.bgWhite.resolveFrom(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(GvSpacing.lg),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(GvRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GvTypography.caption(secondary)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GvTypography.headline(primary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(hint, style: GvTypography.small(secondary)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GvTypography.title(primary).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(trailing, style: GvTypography.small(secondary)),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final _HotelBooking booking;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    final card = AppColors.bgWhite.resolveFrom(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final (label, color) = _statusStyle(context, booking.status);
    final canCheckIn = booking.status == _HotelStatus.arrival;
    final canCheckOut = booking.status == _HotelStatus.dueOut ||
        booking.status == _HotelStatus.inHouse;

    return Container(
      padding: const EdgeInsets.all(GvSpacing.lg),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(GvRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.guest} · ${booking.roomType}',
                  style: GvTypography.body(primary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label, style: GvTypography.small(color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.dates} · ${booking.rooms} 间 · ${booking.roomNo.isEmpty ? "待排房" : booking.roomNo}',
            style: GvTypography.small(secondary),
          ),
          const SizedBox(height: 2),
          Text(
            '${booking.bookingNo} · 应付 \$${booking.amount} · 押金 \$${booking.deposit}',
            style: GvTypography.small(secondary),
          ),
          if (canCheckIn || canCheckOut) ...[
            const SizedBox(height: GvSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCheckIn)
                  FilledButton(
                    onPressed: onCheckIn,
                    child: const Text('办理入住'),
                  ),
                if (canCheckOut)
                  FilledButton(
                    onPressed: onCheckOut,
                    child: const Text('结账退房'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomGrid extends StatelessWidget {
  const _RoomGrid({required this.rooms});

  final List<_RoomState> rooms;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rooms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final (label, color) = _roomStyle(context, room.status);
        final card = AppColors.bgWhite.resolveFrom(context);
        final primary = AppColors.textPrimary.resolveFrom(context);
        return Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(GvRadii.compact),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                room.no,
                style: GvTypography.body(primary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: GvTypography.small(color)),
            ],
          ),
        );
      },
    );
  }
}

class _CheckInSheet extends StatelessWidget {
  const _CheckInSheet({required this.booking, required this.onConfirm});

  final _HotelBooking booking;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GvSpacing.page,
          0,
          GvSpacing.page,
          GvSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '办理入住',
              style: GvTypography.title(primary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: GvSpacing.sm),
            Text(
              '${booking.guest} · ${booking.roomType} · ${booking.dates}',
              style: GvTypography.body(primary),
            ),
            const SizedBox(height: 4),
            Text(
              '需收取押金 \$${booking.deposit}（退房结算/退还）',
              style: GvTypography.body(secondary),
            ),
            const SizedBox(height: GvSpacing.lg),
            FilledButton(
              onPressed: onConfirm,
              child: const Text('收取押金并入住'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckOutSheet extends StatelessWidget {
  const _CheckOutSheet({required this.booking, required this.onConfirm});

  final _HotelBooking booking;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    const minibar = 18;
    final refund = booking.deposit - minibar;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GvSpacing.page,
          0,
          GvSpacing.page,
          GvSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '结账退房',
              style: GvTypography.title(primary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: GvSpacing.sm),
            Text('${booking.guest} · ${booking.roomNo}',
                style: GvTypography.body(primary)),
            const SizedBox(height: 4),
            Text('押金 \$${booking.deposit}',
                style: GvTypography.body(secondary)),
            Text('迷你吧消费 \$$minibar', style: GvTypography.body(secondary)),
            Text(
              '应退押金 \$$refund',
              style: GvTypography.body(primary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: GvSpacing.lg),
            FilledButton(
              onPressed: onConfirm,
              child: const Text('确认结算并退房'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HotelStatus { confirmed, arrival, inHouse, dueOut, checkedOut }

enum _RoomStatus { available, occupied, cleaning, maintenance, dueOut, arrival }

class _HotelBooking {
  _HotelBooking({
    required this.bookingNo,
    required this.guest,
    required this.phone,
    required this.roomType,
    required this.dates,
    required this.rooms,
    required this.amount,
    required this.deposit,
    required this.status,
    required this.roomNo,
  });

  final String bookingNo;
  final String guest;
  final String phone;
  final String roomType;
  final String dates;
  final int rooms;
  final int amount;
  final int deposit;
  _HotelStatus status;
  String roomNo;
}

class _RoomState {
  const _RoomState(this.no, this.status);

  final String no;
  final _RoomStatus status;
}

(String, Color) _statusStyle(BuildContext context, _HotelStatus status) {
  final primary = AppColors.primary.resolveFrom(context);
  final success = AppColors.success.resolveFrom(context);
  final hint = AppColors.textHint.resolveFrom(context);
  final danger = AppColors.danger.resolveFrom(context);
  return switch (status) {
    _HotelStatus.confirmed => ('已确认', primary),
    _HotelStatus.arrival => ('待入住', primary),
    _HotelStatus.inHouse => ('在住', success),
    _HotelStatus.dueOut => ('待退房', danger),
    _HotelStatus.checkedOut => ('已退房', hint),
  };
}

(String, Color) _roomStyle(BuildContext context, _RoomStatus status) {
  final primary = AppColors.primary.resolveFrom(context);
  final success = AppColors.success.resolveFrom(context);
  final hint = AppColors.textHint.resolveFrom(context);
  final danger = AppColors.danger.resolveFrom(context);
  return switch (status) {
    _RoomStatus.available => ('可用', success),
    _RoomStatus.occupied => ('在住', primary),
    _RoomStatus.cleaning => ('清扫', hint),
    _RoomStatus.maintenance => ('维修', danger),
    _RoomStatus.dueOut => ('待退', danger),
    _RoomStatus.arrival => ('待入', primary),
  };
}
