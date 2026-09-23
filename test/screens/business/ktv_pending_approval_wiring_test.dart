import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 客户「待确认加项」提醒的**接线守卫**（A380 收银端）。
///
/// 背景：C 端客户自助加项落 `PENDING_APPROVAL`，门店运营不确认就不计应收。
/// 提醒链路由四处组成：唯一聚合接口 + 全局轮询状态 + 三处提示 + 一个集中处理页。
/// 这里用源码断言把它钉住，避免以后有人只改一处（例如把接口路径改回不存在的前缀、
/// 把轮询间隔改大、或把并发 409 当硬失败）而没人发现。
void main() {
  String read(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: '缺少文件：$path');
    return file.readAsStringSync();
  }

  test('聚合接口路径是被网关白名单放行的 /business/orders/pending-approval', () {
    final source = read('lib/repositories/business/ktv_api_client.dart');
    expect(source.contains("'/business/orders/pending-approval'"), isTrue,
        reason: '唯一数据源路径不得改动：/business/order-items/** 不在网关白名单内，会 404');
    expect(source.contains('/business/order-items/pending-approval'), isFalse,
        reason: '老前缀经网关 404，已被废弃');
  });

  test('轮询 15s + 前后台暂停/补拉 + 快照去重都在', () {
    final source = read('lib/providers/pending_approval_provider.dart');
    expect(source.contains('pollIntervalMs = 15000'), isTrue,
        reason: '与服务端读缓存 TTL（3s）和后台端保持同一口径');
    expect(source.contains('Timer.periodic'), isTrue);
    expect(source.contains('setForeground'), isTrue,
        reason: '后台必须停止轮询、回前台立即补拉');
    expect(source.contains('revision'), isTrue,
        reason: 'revision 未变化不得重渲染（防角标闪烁）');
    // 写路径必须让缓存/快照立即失效重拉，而不是本地长期为准。
    expect(source.contains('refresh(silent: true)'), isTrue);
  });

  test('并发 409 是「已被别人处理」而不是失败', () {
    final source = read('lib/providers/pending_approval_provider.dart');
    expect(source.contains('_statusCodeOf(e) == 409'), isTrue,
        reason: '服务端是原子条件更新，输家必然拿到 409，不能报成红色失败');
    expect(source.contains('alreadyHandled'), isTrue);
    expect(source.contains('PendingApprovalAction.failed'), isTrue,
        reason: '其它错误仍要如实暴露，不能一律吞掉');
  });

  test('三处提示 + 一个集中处理页都接上了同一个数据源', () {
    final routes = read('lib/app/app_routes.dart');
    expect(
        routes
            .contains("ktvPendingApproval = '/business/ktv/pending-approval'"),
        isTrue);
    expect(read('lib/app_router.dart').contains('KtvPendingApprovalScreen'),
        isTrue);

    // ① 侧边导航角标（工作台每一级页都看得到）
    final nav = read('lib/screens/business/ktv_bottom_nav.dart');
    expect(nav.contains('PendingApprovalController'), isTrue);
    expect(nav.contains('Badge('), isTrue);

    // ② 计时加项页横幅（客户加项发生在这张单上）
    expect(
        read('lib/screens/business/ktv_timing_screen.dart')
            .contains('GvPendingApprovalBanner(orderId: widget.args?.orderId)'),
        isTrue);

    // ③ 收银列表卡片角标 + 收款前提示
    final cashier = read('lib/screens/business/ktv_cashier_screen.dart');
    expect(cashier.contains('待确认加项 ×'), isTrue);
    expect(cashier.contains('GvPendingApprovalBanner(orderId: _selected?.id)'),
        isTrue);

    // 看板入口横幅
    expect(
        read('lib/screens/business/ktv_dashboard_screen.dart')
            .contains('GvPendingApprovalBanner'),
        isTrue);

    // 集中处理页：逐条确认/拒绝 + 本单全部确认，且金额只走唯一入口
    final screen =
        read('lib/screens/business/ktv_pending_approval_screen.dart');
    expect(screen.contains("'确认'"), isTrue);
    expect(screen.contains("'拒绝'"), isTrue);
    expect(screen.contains('本单全部确认'), isTrue);
    expect(screen.contains('confirmOrder'), isTrue);
  });

  test('工作台三页与生命周期都做了引用计数式的启停', () {
    for (final path in const [
      'lib/screens/business/ktv_dashboard_screen.dart',
      'lib/screens/business/ktv_cashier_screen.dart',
      'lib/screens/business/ktv_shift_screen.dart',
    ]) {
      final source = read(path);
      expect(source.contains("PendingApprovalController?>()?..start()"), isTrue,
          reason: '$path 未在工作台范围内启动待确认加项轮询');
      expect(source.contains('?.stop()'), isTrue,
          reason: '$path 未释放轮询（切页会把新页刚启动的轮询关掉）');
    }
    final provider = read('lib/providers/pending_approval_provider.dart');
    expect(provider.contains('_holders'), isTrue,
        reason: '必须引用计数：三个一级页切页时不能互相关掉轮询');
    final deps = read('lib/app/app_dependencies.dart');
    expect(deps.contains('PendingApprovalController'), isTrue,
        reason: '提醒态必须在 App 装配层注册，否则角标永远为 0');
    expect(deps.contains('pendingApproval.setForeground(false)'), isTrue);
    expect(deps.contains('pendingApproval.setForeground(true)'), isTrue);
    expect(deps.contains('pendingApproval.reset()'), isTrue,
        reason: '退出登录要清空角标，不能留给下一位收银员');
  });

  test('集中处理页把包厢作为第一识别信息，缺失时给「未关联包厢」', () {
    final screen =
        read('lib/screens/business/ktv_pending_approval_screen.dart');
    expect(screen.contains("Text('包厢 ' + order.roomLabel"), isTrue,
        reason: '收银员必须先看清是「哪间包厢」的需求，订单号只是次要定位');
    final model = read('lib/models/ktv_models.dart');
    expect(model.contains('未关联包厢'), isTrue,
        reason: '订单没有包厢会话 / 资源服务不可达时不能留空（空白会被当成加载失败）');
  });

  test('提醒 UI 不自己发请求、不硬编码币种', () {
    final banner = read('lib/widgets/open_pending_approval_banner.dart');
    expect(banner.contains('getPendingApproval'), isFalse,
        reason: '横幅只消费全局快照，避免每个入口各拉一次');
    expect(banner.contains('amountText'), isTrue,
        reason: '混币种时金额文案由模型统一裁决（禁止跨币种相加）');
    final model = read('lib/models/ktv_models.dart');
    expect(model.contains('mixedCurrency'), isTrue);
    expect(model.contains('formatMoney'), isTrue, reason: '金额展示必须走唯一入口');
  });
}
