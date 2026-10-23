import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../repositories/business/admin_api_client.dart';
import '../../widgets/open_nav_bar.dart';

/// 酒店移动前台：任务、入住、退房全部调用真实 B 端接口。
class HotelFrontdeskScreen extends StatefulWidget {
  const HotelFrontdeskScreen({super.key});

  @override
  State<HotelFrontdeskScreen> createState() => _HotelFrontdeskScreenState();
}

class _HotelFrontdeskScreenState extends State<HotelFrontdeskScreen> {
  final _client = AdminApiClient.instance;
  final List<_HotelBooking> _bookings = [];
  bool _loading = true;
  String? _error;

  int get _arrivals => _bookings.where((b) => b.status == _HotelStatus.arrival).length;
  int get _inHouse => _bookings.where((b) => b.status == _HotelStatus.inHouse).length;
  int get _dueOut => _bookings.where((b) => b.status == _HotelStatus.dueOut).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _client.hotelTasks();
      if (!mounted) return;
      setState(() {
        _bookings
          ..clear()
          ..addAll(tasks.map(_HotelBooking.fromJson));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '加载酒店任务失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkIn(_HotelBooking booking) async {
    final confirmed = await _confirm(
      '办理入住',
      '${booking.guest} · ${booking.roomType}\n${booking.dates}',
      '确认入住',
    );
    if (!confirmed) return;
    try {
      await _client.checkInHotelBooking(booking.id);
      _toast('${booking.guest} 已办理入住');
      await _load();
    } catch (error) {
      _toast('办理入住失败：$error');
    }
  }

  Future<void> _checkOut(_HotelBooking booking) async {
    final confirmed = await _confirm(
      '办理退房',
      '${booking.guest} · ${booking.roomNo.isEmpty ? "未分房" : booking.roomNo}\n账单未结清时退房会被服务端拒绝。',
      '确认退房',
    );
    if (!confirmed) return;
    try {
      await _client.checkOutHotelBooking(booking.id);
      _toast('${booking.guest} 已退房');
      await _load();
    } catch (error) {
      _toast('办理退房失败：$error');
    }
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
        ],
      ),
    );
    return result == true;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          onPressed: _load,
          child: const Text('刷新'),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary.resolveFrom(context),
        onRefresh: _load,
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
              total: _bookings.length,
            ),
            const SizedBox(height: GvSpacing.lg),
            _SectionTitle(title: '今日待办', trailing: '${_bookings.length} 条'),
            const SizedBox(height: GvSpacing.sm),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(GvSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else if (_bookings.isEmpty)
              Text('当前门店没有待处理任务', style: GvTypography.body(secondary))
            else
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
    required this.total,
  });

  final int arrivals;
  final int inHouse;
  final int dueOut;
  final int total;

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
        _MetricCard(label: '待入住', value: '$arrivals', hint: '已确认/今日到店'),
        _MetricCard(label: '在住', value: '$inHouse', hint: '当前在店'),
        _MetricCard(label: '待退房', value: '$dueOut', hint: '今日离店'),
        _MetricCard(label: '任务数', value: '$total', hint: '当前门店'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.hint});

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
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(GvRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GvTypography.caption(secondary)),
          Text(value, style: GvTypography.headline(primary).copyWith(fontWeight: FontWeight.w700)),
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
          child: Text(title, style: GvTypography.title(primary).copyWith(fontWeight: FontWeight.w700)),
        ),
        Text(trailing, style: GvTypography.small(secondary)),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondary.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(GvSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgWhite.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: GvTypography.body(secondary)),
          const SizedBox(height: GvSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onCheckIn, required this.onCheckOut});

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
    final canCheckOut = booking.status == _HotelStatus.inHouse || booking.status == _HotelStatus.dueOut;

    return Container(
      padding: const EdgeInsets.all(GvSpacing.lg),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(GvRadii.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${booking.guest} · ${booking.roomType}',
                  style: GvTypography.body(primary).copyWith(fontWeight: FontWeight.w700),
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
            '${booking.bookingNo} · 应收 ${booking.amountText}',
            style: GvTypography.small(secondary),
          ),
          if (canCheckIn || canCheckOut) ...[
            const SizedBox(height: GvSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCheckIn) FilledButton(onPressed: onCheckIn, child: const Text('办理入住')),
                if (canCheckOut) FilledButton(onPressed: onCheckOut, child: const Text('办理退房')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _HotelStatus { confirmed, arrival, inHouse, dueOut, checkedOut, other }

class _HotelBooking {
  _HotelBooking({
    required this.id,
    required this.bookingNo,
    required this.guest,
    required this.roomType,
    required this.dates,
    required this.rooms,
    required this.amountText,
    required this.status,
    required this.roomNo,
  });

  final int id;
  final String bookingNo;
  final String guest;
  final String roomType;
  final String dates;
  final int rooms;
  final String amountText;
  final _HotelStatus status;
  final String roomNo;

  factory _HotelBooking.fromJson(Map<String, dynamic> json) {
    final status = switch (json['status'] as String?) {
      'CONFIRMED' => _HotelStatus.confirmed,
      'ARRIVAL' => _HotelStatus.arrival,
      'IN_HOUSE' => _HotelStatus.inHouse,
      'DUE_OUT' => _HotelStatus.dueOut,
      'CHECKED_OUT' => _HotelStatus.checkedOut,
      _ => _HotelStatus.other,
    };
    final amountMinor = (json['amountMinor'] as num?)?.toInt() ?? 0;
    final currency = (json['currency'] as String?) ?? '';
    return _HotelBooking(
      id: (json['id'] as num).toInt(),
      bookingNo: (json['bookingNo'] as String?) ?? '',
      guest: (json['guestName'] as String?) ?? '住客',
      roomType: (json['roomType'] as String?) ?? '',
      dates: '${json['checkInDate'] ?? ''} → ${json['checkOutDate'] ?? ''}',
      rooms: (json['rooms'] as num?)?.toInt() ?? 1,
      amountText: '${(amountMinor / 100).toStringAsFixed(2)} $currency',
      status: status,
      roomNo: (json['roomNo'] as String?) ?? '',
    );
  }
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
    _HotelStatus.other => ('处理中', hint),
  };
}
