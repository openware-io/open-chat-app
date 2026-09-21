import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:uuid/uuid.dart';

import '../../core/api_failure.dart';
import '../../core/config.dart';
import '../../core/currency.dart';
import '../../core/local_storage.dart';
import '../../models/ktv_models.dart';

/// KTV B 端 SaaS 后端 API 客户端（platform-order-service + common-payment-service）。
///
/// 契约遵循 SAAS_PLATFORM_05_API.md / KTV_BUSINESS_01_SERVICE.md：
/// - base URL 复用现有 [AppConfig.apiPrefix]（即 {apiBase}/api/v1，与 C 端同源）。
/// - 固定携带 Header X-Client-Contract: business-v1；写请求自动带
///   Idempotency-Key（UUID，24h）。
/// - 金额只读后端返回的「最小单位 + 币种字符串」，客户端不做任何金额运算。
/// - 币种：响应体顶层 `currencyCode` / `X-Currency` 响应头（网关兜底）会被捕获，
///   经 [onCurrencyResolved] 交给全局币种状态（CurrencyController）；单据自带的
///   `currency` 快照优先（规范 §3.6）。
///
/// 说明：B 端账号 Token 与租户上下文 Token 的完整存储/选择沿用
/// SAAS_PLATFORM_03 14（见 LocalStorage.bizToken / LocalStorage.bizTenantContext）；
/// 本模块只负责按契约发送这两个 Header，不实现 B 端登录流程。
class KtvApiClient {
  KtvApiClient({
    LocalStorage? storage,
    Dio? dio,
    String? apiPrefix,
    this.onCurrencyResolved,
  })  : _storage = storage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: apiPrefix ?? AppConfig.apiPrefix,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-Client-Contract'] = 'business-v1';
          options.headers['Accept-Language'] = 'zh';
          final token = _authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final context = _storage?.bizTenantContext;
          if (context != null && context.isNotEmpty) {
            options.headers['X-Tenant-Context'] = context;
          }
          if (_isWrite(options.method) &&
              !options.headers.containsKey('Idempotency-Key')) {
            options.headers['Idempotency-Key'] = const Uuid().v4();
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          captureCurrencyFromResponse(response);
          handler.next(response);
        },
      ),
    );
  }

  final LocalStorage? _storage;
  final Dio _dio;

  /// 服务端下发币种时的回调（由 App 装配层接到全局 CurrencyController）。
  final void Function(String currencyCode)? onCurrencyResolved;

  /// 无后端时是否回退到本地 mock（骨架阶段默认开启，真实联调可关闭）。
  ///
  /// 仅当「网络层失败」（DioException 无 HTTP response，即后端不可达）或非
  /// 业务异常时回退；后端返回的 4xx/5xx 业务错误会原样抛出，不会被 mock 吞掉。
  static const bool fallbackToMockOnError = true;

  /// 优先使用 B 端 Token，未配置时退回 C 端 Token（过渡期兼容）。
  String? get _authToken => _storage?.bizToken ?? _storage?.token;

  Dio get dio => _dio;

  // ───────────────────────────── 资源看板 ─────────────────────────────

  /// 包厢看板：GET /api/v1/business/resources（KTV_ROOM）+ 会话状态投影。
  Future<List<KtvRoom>> getRooms({String resourceType = 'KTV_ROOM'}) {
    return _guard(
      op: 'getRooms',
      live: () async {
        final resp = await _dio.get<dynamic>(
          '/business/resources',
          queryParameters: {'resourceType': resourceType},
        );
        return _asList(resp.data)
            .whereType<Map>()
            .map((e) => KtvRoom.fromJson(_asMap(e)))
            .toList(growable: false);
      },
      mock: _mockRooms,
    );
  }

  // ───────────────────────────── 订单 ─────────────────────────────

  /// 快速开台：POST /api/v1/business/orders。
  ///
  /// 价格由服务端重算，客户端只传选择项（businessType/门店/包厢/可选加项），
  /// 不传任何金额。
  Future<KtvOrder> createOrder({
    String? storeId,
    String? customerId,
    String? reservationId,
    String? resourceId,
    List<Map<String, dynamic>> items = const [],
  }) {
    return _guard(
      op: 'createOrder',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/orders',
          data: {
            'businessType': 'KTV',
            if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
            if (customerId != null && customerId.isNotEmpty)
              'customerId': customerId,
            if (resourceId != null && resourceId.isNotEmpty)
              'resourceId': resourceId,
            if (reservationId != null && reservationId.isNotEmpty)
              'reservationId': reservationId,
            'items': items,
          },
        );
        return KtvOrder.fromJson(_asMap(resp.data));
      },
      mock: () => _mockOrder(resourceId: resourceId),
    );
  }

  /// 订单详情：GET /api/v1/business/orders/{id}。
  Future<KtvOrder> getOrder(String orderId) {
    return _guard(
      op: 'getOrder',
      live: () async {
        final resp = await _dio.get<dynamic>('/business/orders/$orderId');
        return KtvOrder.fromJson(_asMap(resp.data));
      },
      mock: () => _mockOrder(orderId: orderId),
    );
  }

  /// 订单列表（收银工作台）：GET /api/v1/business/orders。
  Future<List<KtvOrder>> listOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
    String businessType = 'KTV',
  }) {
    return _guard(
      op: 'listOrders',
      live: () async {
        final resp = await _dio.get<dynamic>(
          '/business/orders',
          queryParameters: {
            'page': page,
            'pageSize': pageSize,
            'businessType': businessType,
            if (status != null && status.isNotEmpty) 'status': status,
          },
        );
        return _asList(resp.data)
            .whereType<Map>()
            .map((e) => KtvOrder.fromJson(_asMap(e)))
            .toList(growable: false);
      },
      mock: _mockOrders,
    );
  }

  /// 加项：POST /api/v1/business/orders/{id}/items。
  /// 价格由服务端重算返回，客户端不传金额。
  Future<KtvOrder> addItems(
    String orderId,
    List<Map<String, dynamic>> items, {
    int? expectedVersion,
  }) {
    return _guard(
      op: 'addItems',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/orders/$orderId/items',
          data: {
            'items': items,
            if (expectedVersion != null) 'expectedVersion': expectedVersion,
          },
        );
        return KtvOrder.fromJson(_asMap(resp.data));
      },
      mock: () => _mockOrder(orderId: orderId, status: 'SERVING'),
    );
  }

  /// 待确认加项聚合视图：GET /api/v1/business/orders/pending-approval。
  ///
  /// C 端客户自助加项落 `PENDING_APPROVAL`，需门店运营确认才计入应收。本接口一次返回
  /// 本门店（租户上下文决定，客户端不传参）的待确认条数/金额/按订单分组的明细：
  /// - 唯一数据源：客户端不再自己扫「订单列表 + 每单明细」拼角标（N+1 且多端口径会漂移）；
  /// - `revision` 用于去重：未变化即视为同一快照，UI 不必重渲染；
  /// - 混币种时 `mixedCurrency=true` 且不给单一币种，调用方只显示条数（禁止跨币种相加）。
  ///
  /// 无后端时返回空视图（绝不编造待确认数据，否则会诱导运营去点不存在的单）。
  Future<KtvPendingApprovalView> getPendingApproval() {
    return _guard(
      op: 'getPendingApproval',
      live: () async {
        final resp =
            await _dio.get<dynamic>('/business/orders/pending-approval');
        return KtvPendingApprovalView.fromJson(_asMap(resp.data));
      },
      mock: () => KtvPendingApprovalView.empty,
    );
  }

  /// 确认客户自助加项：POST /api/v1/business/orders/{orderId}/items/{itemId}/confirm。
  ///
  /// 服务端是**原子条件更新**（`WHERE status='PENDING_APPROVAL'`）：并发下输的一方返回 409
  /// 「该加项已被处理」，已是 ACTIVE 则幂等成功。调用方必须把 409 当作「已被别人处理」收敛，
  /// 不得当成硬失败，也不要本地累加计数。
  Future<void> confirmPendingItem(String orderId, String itemId) {
    return _guard(
      op: 'confirmPendingItem',
      live: () async {
        await _dio.post<dynamic>(
          '/business/orders/$orderId/items/$itemId/confirm',
        );
      },
      mock: () {},
    );
  }

  /// 拒绝客户自助加项：POST /api/v1/business/orders/{orderId}/items/{itemId}/reject。
  ///
  /// 与确认同口径：原子条件更新 + 409 表示已被别人处理，已是 REJECTED 则幂等成功。
  Future<void> rejectPendingItem(String orderId, String itemId) {
    return _guard(
      op: 'rejectPendingItem',
      live: () async {
        await _dio.post<dynamic>(
          '/business/orders/$orderId/items/$itemId/reject',
        );
      },
      mock: () {},
    );
  }

  /// 点单目录：GET /api/v1/business/catalog/items。
  ///
  /// 加项页的数据源：服务端按「已上架商品 + 可用库存」给出 `available` / `unavailableReason` /
  /// `availableQuantity`，客户端据此置灰售罄项并限制加号上限（提交前的防超卖）。
  Future<List<KtvCatalogItem>> listCatalog({String? category}) {
    return _guard(
      op: 'listCatalog',
      live: () async {
        final resp = await _dio.get<dynamic>(
          '/business/catalog/items',
          queryParameters: {
            if (category != null && category.isNotEmpty) 'category': category,
          },
        );
        return _asList(resp.data)
            .whereType<Map>()
            .map((e) => KtvCatalogItem.fromJson(_asMap(e)))
            .toList(growable: false);
      },
      mock: _mockCatalog,
    );
  }

  /// 点服务人员：POST /api/v1/business/orders/{id}/servers。
  Future<KtvOrder> orderServer(
    String orderId,
    String serverResourceId, {
    int? expectedVersion,
  }) {
    return _guard(
      op: 'orderServer',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/orders/$orderId/servers',
          data: {
            'serverResourceId': serverResourceId,
            if (expectedVersion != null) 'expectedVersion': expectedVersion,
          },
        );
        return KtvOrder.fromJson(_asMap(resp.data));
      },
      mock: () => _mockOrder(orderId: orderId, status: 'SERVING'),
    );
  }

  // ───────────────────────────── KTV 会话 ─────────────────────────────

  /// 开台：POST /api/v1/business/ktv/sessions/{id}/open。
  Future<KtvSession> openSession(String sessionId, {int? expectedVersion}) {
    return _guard(
      op: 'openSession',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/ktv/sessions/$sessionId/open',
          data: {
            if (expectedVersion != null) 'expectedVersion': expectedVersion
          },
        );
        return KtvSession.fromJson(_asMap(resp.data));
      },
      mock: () => _mockSession(sessionId: sessionId, status: 'OPEN'),
    );
  }

  /// 暂停：POST /api/v1/business/ktv/sessions/{id}/pause。
  Future<KtvSession> pauseSession(
    String sessionId, {
    String? reason,
    int? expectedVersion,
  }) {
    return _guard(
      op: 'pauseSession',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/ktv/sessions/$sessionId/pause',
          data: {
            if (reason != null && reason.isNotEmpty) 'reason': reason,
            if (expectedVersion != null) 'expectedVersion': expectedVersion,
          },
        );
        return KtvSession.fromJson(_asMap(resp.data));
      },
      mock: () => _mockSession(sessionId: sessionId, status: 'PAUSED'),
    );
  }

  /// 恢复：POST /api/v1/business/ktv/sessions/{id}/resume。
  Future<KtvSession> resumeSession(String sessionId, {int? expectedVersion}) {
    return _guard(
      op: 'resumeSession',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/ktv/sessions/$sessionId/resume',
          data: {
            if (expectedVersion != null) 'expectedVersion': expectedVersion
          },
        );
        return KtvSession.fromJson(_asMap(resp.data));
      },
      mock: () => _mockSession(sessionId: sessionId, status: 'OPEN'),
    );
  }

  /// 结台：POST /api/v1/business/ktv/sessions/{id}/close。
  /// 结算并释放包厢，订单进入 WAITING_SETTLEMENT。
  Future<KtvSession> closeSession(String sessionId, {int? expectedVersion}) {
    return _guard(
      op: 'closeSession',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/ktv/sessions/$sessionId/close',
          data: {
            if (expectedVersion != null) 'expectedVersion': expectedVersion
          },
        );
        return KtvSession.fromJson(_asMap(resp.data));
      },
      mock: () => _mockSession(sessionId: sessionId, status: 'CLOSED'),
    );
  }

  /// 结束服务人员：POST /api/v1/business/ktv/servers/{id}/end。
  Future<void> endServer(String serverSessionId, {int? expectedVersion}) {
    return _guard(
      op: 'endServer',
      live: () async {
        await _dio.post<dynamic>(
          '/business/ktv/servers/$serverSessionId/end',
          data: {
            if (expectedVersion != null) 'expectedVersion': expectedVersion
          },
        );
      },
      mock: () {},
    );
  }

  /// 取消服务人员点单：POST /api/v1/business/ktv/servers/{id}/cancel。
  Future<void> cancelServer(
    String serverSessionId, {
    String? reason,
    int? expectedVersion,
  }) {
    return _guard(
      op: 'cancelServer',
      live: () async {
        await _dio.post<dynamic>(
          '/business/ktv/servers/$serverSessionId/cancel',
          data: {
            if (reason != null && reason.isNotEmpty) 'reason': reason,
            if (expectedVersion != null) 'expectedVersion': expectedVersion,
          },
        );
      },
      mock: () {},
    );
  }

  // ───────────────────────────── 账单 / 收款 ─────────────────────────────

  /// 客户消费账单：GET /api/v1/business/orders/{id}/bill。
  /// 只展示服务端账单快照，不本地计算金额。
  Future<KtvBill> getBill(String orderId) {
    return _guard(
      op: 'getBill',
      live: () async {
        final resp = await _dio.get<dynamic>('/business/orders/$orderId/bill');
        return KtvBill.fromJson(_asMap(resp.data));
      },
      mock: () => _mockBill(orderId: orderId),
    );
  }

  /// 可用支付方式：GET /api/v1/business/payments/available-methods。
  Future<List<KtvPaymentMethod>> availableMethods({
    String? orderId,
    String? amount,
    String? currency,
  }) {
    return _guard(
      op: 'availableMethods',
      live: () async {
        final resp = await _dio.get<dynamic>(
          '/business/payments/available-methods',
          queryParameters: {
            if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
            if (amount != null && amount.isNotEmpty) 'amount': amount,
            if (currency != null && currency.isNotEmpty) 'currency': currency,
          },
        );
        return _asList(resp.data)
            .whereType<Map>()
            .map((e) => KtvPaymentMethod.fromJson(_asMap(e)))
            .toList(growable: false);
      },
      mock: _mockPaymentMethods,
    );
  }

  /// 组合收款：POST /api/v1/business/orders/{id}/collect（common-payment）。
  /// 逐笔金额 ≤ 剩余应收；返回 remainingAmount + collectedByMethod + changeAmount。
  Future<KtvCollectResult> collect(
    String orderId,
    List<Map<String, dynamic>> payments, {
    int? expectedVersion,
  }) {
    return _guard(
      op: 'collect',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/orders/$orderId/collect',
          data: {
            'payments': payments,
            if (expectedVersion != null) 'expectedVersion': expectedVersion,
          },
        );
        return KtvCollectResult.fromJson(_asMap(resp.data));
      },
      mock: () => _mockCollect(payments),
    );
  }

  // ───────────────────────────── 班次 ─────────────────────────────

  /// 开班：POST /api/v1/business/shifts/open。
  Future<KtvShift> openShift({String? terminalId, String? openingCash}) {
    return _guard(
      op: 'openShift',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/shifts/open',
          data: {
            if (terminalId != null && terminalId.isNotEmpty)
              'terminalId': terminalId,
            if (openingCash != null && openingCash.isNotEmpty)
              'openingCash': openingCash,
          },
        );
        return KtvShift.fromJson(_asMap(resp.data));
      },
      mock: () => _mockShift(status: 'OPEN'),
    );
  }

  /// 交班：POST /api/v1/business/shifts/{id}/close。
  Future<KtvShift> closeShift(
    String shiftId, {
    String? actualCash,
    String? remark,
  }) {
    return _guard(
      op: 'closeShift',
      live: () async {
        final resp = await _dio.post<dynamic>(
          '/business/shifts/$shiftId/close',
          data: {
            if (actualCash != null && actualCash.isNotEmpty)
              'actualCash': actualCash,
            if (remark != null && remark.isNotEmpty) 'remark': remark,
          },
        );
        return KtvShift.fromJson(_asMap(resp.data));
      },
      mock: () => _mockShift(status: 'CLOSED'),
    );
  }

  // ───────────────────────────── 通用 ─────────────────────────────

  bool _isWrite(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
      case 'PUT':
      case 'PATCH':
      case 'DELETE':
        return true;
      default:
        return false;
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return List<dynamic>.from(data);
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final items = map['items'];
      if (items is List) return List<dynamic>.from(items);
      final nested = map['data'];
      if (nested is List) return List<dynamic>.from(nested);
    }
    return const <dynamic>[];
  }

  /// 真实请求 + 本地 mock 回退。
  ///
  /// - DioException 且无 HTTP response（后端不可达/网络断开）→ 回退 mock。
  /// - 其他非 [ApiFailure] 异常 → 回退 mock（骨架期容错）。
  /// - 后端 4xx/5xx 业务错误（有 response）→ 原样抛出，不吞。
  Future<T> _guard<T>({
    required Future<T> Function() live,
    required T Function() mock,
    required String op,
  }) async {
    try {
      return await live();
    } on DioException catch (e) {
      if (e.response == null && fallbackToMockOnError) {
        debugPrint('[KTV API] ' + op + ' 无后端，回退本地 mock: ' + (e.message ?? ''));
        return mock();
      }
      rethrow;
    } catch (e) {
      if (fallbackToMockOnError) {
        debugPrint('[KTV API] ' + op + ' 回退本地 mock: ' + e.toString());
        return mock();
      }
      rethrow;
    }
  }

  /// 供 UI 展示的统一错误信息提取。
  static String describeError(Object error) => ApiFailure.messageOf(error);

  /// 从业务响应中捕获当前租户币种：响应体顶层 `currencyCode` 优先，
  /// 其次网关兜底响应头 `X-Currency`（规范 §3.5）。
  ///
  /// 只认**顶层**字段（单据级 `currency` 快照不参与全局币种推断），
  /// 避免历史单据的快照币种反向污染当前租户币种。
  @visibleForTesting
  void captureCurrencyFromResponse(Response<dynamic> response) {
    final fromBody = _topLevelCurrencyCode(response.data);
    final fromHeader = response.headers.value('x-currency');
    final raw = (fromBody ?? fromHeader ?? '').trim();
    if (raw.isEmpty) return;
    final code = Currency.normalize(raw);
    if (code == Currency.currentCode) return;
    onCurrencyResolved?.call(code);
  }

  String? _topLevelCurrencyCode(dynamic data) {
    if (data is! Map) return null;
    final body = Map<String, dynamic>.from(data);
    final direct = body['currencyCode'] ?? body['currency_code'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    final nested = body['data'];
    if (nested is Map) {
      final inner = Map<String, dynamic>.from(nested);
      final code = inner['currencyCode'] ?? inner['currency_code'];
      if (code != null && code.toString().trim().isNotEmpty) {
        return code.toString();
      }
    }
    return null;
  }

  // ───────────────────────────── Mock 数据 ─────────────────────────────

  // 本地 mock 仅用于「无后端」时的 UI 兜底演示，金额字段仍按最小单位 + 币种
  // 返回，与真实契约同构；真实后端可达时以上 live 请求为准。
  //
  // dev-only mock：mock 金额一律跟随全局当前租户币种（缺省 USD），
  // 避免「无后端时全链路永远显示 ¥、币种切换看起来正常」的假象。
  String get _devMockCurrency => Currency.currentCode;

  List<KtvRoom> _mockRooms() {
    const now = '2026-08-17T10:00:00Z';
    KtvRoom room(String id, String code, String board, String? orderId,
            String? sessionId) =>
        KtvRoom(
          id: id,
          code: code,
          name: code,
          resourceType: 'KTV_ROOM',
          status: 'ENABLED',
          boardStatus: board,
          occupationStatus: board == 'AVAILABLE' ? null : board,
          orderId: orderId,
          sessionId: sessionId,
          updatedAt: DateTime.tryParse(now),
        );
    return [
      room('res_001', 'A01', 'AVAILABLE', null, null),
      room('res_002', 'A02', 'IN_USE', 'ord_002', 'ses_002'),
      room('res_003', 'A03', 'UNAVAILABLE', null, null),
      room('res_004', 'A05', 'RESERVED', 'ord_004', 'ses_004'),
      room('res_005', 'A06', 'IN_USE', 'ord_005', 'ses_005'),
      room('res_006', 'A08', 'AVAILABLE', null, null),
      room('res_007', 'B01', 'AVAILABLE', null, null),
      room('res_008', 'B02', 'IN_USE', 'ord_008', 'ses_008'),
      room('res_009', 'B03', 'AVAILABLE', null, null),
      room('res_010', 'B05', 'IN_USE', 'ord_010', 'ses_010'),
    ];
  }

  KtvOrder _mockOrder({
    String? orderId,
    String? resourceId,
    String status = 'DRAFT',
    String sessionStatus = 'RESERVED',
  }) {
    final id = orderId ?? 'ord_001';
    return KtvOrder(
      id: id,
      orderNo: 'KT20260817-' + id.hashCode.toString().substring(0, 4),
      status: status,
      roomId: resourceId ?? 'res_002',
      roomName: 'A02',
      customerMasked: '138****0001',
      sessionId: 'ses_002',
      sessionStatus: sessionStatus,
      totalAmount: KtvMoney(minorUnits: 32400, currency: _devMockCurrency),
      paidAmount: KtvMoney(minorUnits: 0, currency: _devMockCurrency),
      currency: _devMockCurrency,
      allowedActions: const [
        'ktv.session.open',
        'ktv.session.close',
        'order.add_item'
      ],
      expectedVersion: 1,
      createdAt: DateTime.tryParse('2026-08-17T10:00:00Z'),
    );
  }

  List<KtvOrder> _mockOrders() {
    KtvOrder order(String id, String room, int amount) => KtvOrder(
          id: id,
          orderNo: 'KT20260817-' + room.hashCode.toString().substring(0, 4),
          status: 'WAITING_SETTLEMENT',
          roomName: room,
          customerMasked: '139****0002',
          sessionId: 'ses_' + room,
          sessionStatus: 'CLOSED',
          totalAmount: KtvMoney(minorUnits: amount, currency: _devMockCurrency),
          paidAmount: KtvMoney(minorUnits: 0, currency: _devMockCurrency),
          currency: _devMockCurrency,
          allowedActions: const ['payment.collect'],
          expectedVersion: 1,
          createdAt: DateTime.tryParse('2026-08-17T09:30:00Z'),
        );
    return [
      order('ord_002', 'A02', 51200),
      order('ord_008', 'B02', 38800),
      order('ord_005', 'A06', 12000),
      order('ord_010', 'B05', 64000),
    ];
  }

  /// 无后端时的点单目录兜底：与真实响应同构，含售罄（available=false）与库存上限两种分支，
  /// 让「售罄置灰」与「加号受库存限制」在没有后端时也能被看到。
  List<KtvCatalogItem> _mockCatalog() {
    final currency = _devMockCurrency;
    KtvCatalogItem item(String id, String name, String unit, int price,
        {bool available = true,
        String reason = '',
        bool stockControlled = false,
        double? availableQuantity}) {
      return KtvCatalogItem(
        id: id,
        name: name,
        unit: unit,
        unitPrice: KtvMoney(minorUnits: price, currency: currency),
        category: '酒水',
        available: available,
        unavailableReason: reason,
        stockControlled: stockControlled,
        availableQuantity: availableQuantity,
      );
    }

    return [
      item('item_001', '果盘', '份', 8800,
          stockControlled: true, availableQuantity: 5),
      item('item_002', '啤酒（打）', '打', 12000,
          stockControlled: true, availableQuantity: 2),
      item('item_003', '小吃拼盘', '份', 6800),
      item('item_004', '茶水', '壶', 3000, available: false, reason: '已售罄'),
    ];
  }

  KtvSession _mockSession({required String sessionId, required String status}) {
    return KtvSession(
      id: sessionId,
      orderId: 'ord_002',
      status: status,
      billingStartAt: DateTime.tryParse('2026-08-17T10:05:00Z'),
      pausedSeconds: status == 'PAUSED' ? 180 : 0,
      openedAt: DateTime.tryParse('2026-08-17T10:05:00Z'),
      closedAt:
          status == 'CLOSED' ? DateTime.tryParse('2026-08-17T12:05:00Z') : null,
      expectedVersion: 2,
    );
  }

  KtvBill _mockBill({required String orderId}) {
    // dev-only mock：无后端演示数据，币种跟随全局当前租户币种（缺省 USD）。
    final currency = _devMockCurrency;
    return KtvBill(
      orderId: orderId,
      orderNo: 'KT20260817-0001',
      currency: currency,
      roomFee: KtvBillLine(
        itemType: 'ROOM_FEE',
        name: '包厢计时费（2 小时）',
        unitPrice: KtvMoney(minorUnits: 12800, currency: currency),
        quantity: 2,
        amount: KtvMoney(minorUnits: 25600, currency: currency),
      ),
      items: [
        KtvBillLine(
          itemType: 'PRODUCT',
          name: '果盘',
          unitPrice: KtvMoney(minorUnits: 8800, currency: currency),
          quantity: 1,
          amount: KtvMoney(minorUnits: 8800, currency: currency),
        ),
      ],
      serverFee: KtvBillLine(
        itemType: 'SERVICE',
        name: '服务人员费',
        unitPrice: KtvMoney(minorUnits: 0, currency: currency),
        quantity: 1,
        amount: KtvMoney(minorUnits: 0, currency: currency),
      ),
      promotions: [
        KtvPromotionLine(
          type: 'DISCOUNT',
          name: '满减',
          amount: KtvMoney(minorUnits: -2000, currency: currency),
        ),
      ],
      subtotalAmount: KtvMoney(minorUnits: 34400, currency: currency),
      discountAmount: KtvMoney(minorUnits: 2000, currency: currency),
      taxAmount: KtvMoney(minorUnits: 0, currency: currency),
      totalAmount: KtvMoney(minorUnits: 32400, currency: currency),
      paidAmount: KtvMoney(minorUnits: 0, currency: currency),
      paidByMethod: KtvMoney(minorUnits: 0, currency: currency),
      changeAmount: KtvMoney(minorUnits: 0, currency: currency),
    );
  }

  List<KtvPaymentMethod> _mockPaymentMethods() {
    return [
      KtvPaymentMethod(
        method: 'CASH',
        enabled: true,
        displayName: '现金',
        balance: KtvMoney(minorUnits: 0, currency: _devMockCurrency),
        hasBalance: true,
      ),
      KtvPaymentMethod(
        method: 'WALLET',
        enabled: true,
        // 品牌名只有一个缺省来源（core/currency.dart），不在业务代码里再写一份字面量。
        displayName: defaultTokenBrandName,
        // dev-only mock：余额 100000 最小单位（= 1000 个主单位），按缺省比例 100
        // 降级换算为 100,000 个代币；数量口径换算/展示统一走 core/currency.dart。
        balance: KtvMoney(minorUnits: 100000, currency: _devMockCurrency),
        hasBalance: true,
      ),
      KtvPaymentMethod(
        method: 'POINT',
        enabled: true,
        displayName: pointUnitName,
        // 积分就是个数（1:1，不乘任何比例）。
        balance: KtvMoney(minorUnits: 5000, currency: _devMockCurrency),
        hasBalance: true,
      ),
    ];
  }

  KtvCollectResult _mockCollect(List<Map<String, dynamic>> payments) {
    // mock 收款视为全部收清：剩余 0，各渠道原样返回输入金额。
    final entries = payments.map((p) {
      final method = (p['method']?.toString() ?? 'CASH').toUpperCase();
      return KtvCollectEntry(
        method: method,
        amount: KtvMoney.parse(p['amount'], _devMockCurrency),
      );
    }).toList(growable: false);
    return KtvCollectResult(
      remainingAmount: KtvMoney(minorUnits: 0, currency: _devMockCurrency),
      currency: _devMockCurrency,
      collectedByMethod: entries,
      changeAmount: KtvMoney(minorUnits: 0, currency: _devMockCurrency),
    );
  }

  KtvShift _mockShift({required String status}) {
    return KtvShift(
      id: 'shift_001',
      status: status,
      openingCash: KtvMoney(minorUnits: 50000, currency: _devMockCurrency),
      expectedCash: KtvMoney(minorUnits: 82400, currency: _devMockCurrency),
      actualCash: status == 'CLOSED'
          ? KtvMoney(minorUnits: 82400, currency: _devMockCurrency)
          : KtvMoney(minorUnits: 0, currency: _devMockCurrency),
      differenceAmount: KtvMoney(minorUnits: 0, currency: _devMockCurrency),
      currency: _devMockCurrency,
      openedAt: DateTime.tryParse('2026-08-17T08:00:00Z'),
      closedAt:
          status == 'CLOSED' ? DateTime.tryParse('2026-08-17T16:00:00Z') : null,
    );
  }
}

/// 组合收款单笔拆分入参构造（method 取值 CASH/WALLET/POINT，amount 为最小单位）。
///
/// 数量腿（WALLET 储值币 / POINT 积分）的 `amount` 是**折算后**的最小货币单位金额：
/// `WALLET` 走 `tokensToMinor(数量, wallet_ratio)`，`POINT` 是 1:1 的个数；
/// wire 契约不变，各腿折算后金额合计必须等于应收。
///
/// 规范 §3.6：写路径必须带上收款币种 —— 有单据快照时传单据币种，
/// 否则回退当前租户币种；不得写死 `CNY`，也不得省略（与
/// `availableMethods(currency:)` 口径对齐）。
Map<String, dynamic> ktvPaymentEntry({
  required String method,
  required int amount,
  String? currency,
}) {
  final raw = Currency.normalize(currency);
  final code = raw.isEmpty ? Currency.currentCode : raw;
  return {
    'method': method,
    'amount': amount,
    'currency': code,
  };
}
