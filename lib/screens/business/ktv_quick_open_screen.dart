import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../models/ktv_models.dart';
import '../../repositories/business/ktv_api_client.dart';
import '../../widgets/gv_nav_bar.dart';

/// KTV 快速开台：POST /api/v1/business/orders（businessType=KTV + 包厢 + 可选客户）。
/// 成功后携带返回的订单/会话上下文跳转到计时页。
class KtvQuickOpenScreen extends StatefulWidget {
  const KtvQuickOpenScreen({super.key, this.args});

  final KtvSessionArgs? args;

  @override
  State<KtvQuickOpenScreen> createState() => _KtvQuickOpenScreenState();
}

class _KtvQuickOpenScreenState extends State<KtvQuickOpenScreen> {
  late final TextEditingController _room;
  final _people = TextEditingController();
  final _customer = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _room = TextEditingController(text: widget.args?.roomName ?? '');
  }

  @override
  void dispose() {
    _room.dispose();
    _people.dispose();
    _customer.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.bgWhite.resolveFrom(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.fieldH,
        vertical: GvSpacing.fieldV,
      ),
    );
  }

  Future<void> _submit() async {
    final roomName = _room.text.trim();
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择包厢')));
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final client = context.read<KtvApiClient>();
      final order = await client.createOrder(
        resourceId: widget.args?.roomId,
        customerId: _customer.text.trim().isEmpty ? null : _customer.text.trim(),
      );
      if (!mounted) return;
      context.push(
        AppRoutes.ktvTiming,
        extra: KtvSessionArgs(
          orderId: order.id,
          sessionId: order.sessionId,
          roomId: order.roomId ?? widget.args?.roomId,
          roomName: order.roomName ?? roomName,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(KtvApiClient.describeError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = gvPageScaffoldBackground(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final accent = AppColors.primary.resolveFrom(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: '快速开台',
        showBack: true,
        backgroundColor: pageBg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GvSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _room,
              decoration: _decoration('包厢（如 A01）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customer,
              keyboardType: TextInputType.phone,
              decoration: _decoration('客户手机号（可跳过，建待认领）'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _people,
              keyboardType: TextInputType.number,
              decoration: _decoration('人数（可选）'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: Text(_submitting ? '提交中…' : '开台'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '提交后由服务端创建订单并锁定包厢，价格以服务端返回为准。',
              textAlign: TextAlign.center,
              style: GvTypography.caption(primary),
            ),
          ],
        ),
      ),
    );
  }
}

