import 'package:gv_core/gv_core.dart' show parseUtcDateTime;

import '../core/currency.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KTV B 端领域模型与金额格式化。
//
// 契约遵循 SAAS_PLATFORM_05_API.md / KTV_BUSINESS_01_SERVICE.md：
// - 金额只由服务端计算，客户端只读「最小单位 + 币种字符串」，不自行计算
//   税费/折扣/抵扣/找零。
// - ID/订单号 JSON 使用字符串；时间为 RFC3339 UTC。
// - allowedActions 由服务端下发，决定按钮是否展示（无权限不展示伪入口）。
//
// 金额在响应里以「最小货币单位整数」的字符串形式返回（如 CNY 的 100 分 = "100"），
// 同时返回 currency 币种。客户端仅做「最小单位 -> 展示字符串」的格式化，
// 不做任何金额运算。
//
// 币种符号/小数位与格式化实现在 `lib/core/currency.dart`（唯一入口
// formatMoney），本文件不再自建映射表。
// ─────────────────────────────────────────────────────────────────────────────

int _jsonInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? fallback;
}

String _jsonString(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

int? _jsonIntOrNull(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '');
}

/// 数量类字段（可能是小数，如 0.5 斤）：解析不出返回 null（= 不限量/未知）。
double? _jsonDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '');
}

String? _jsonStringOrNull(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

Map<String, dynamic> _stringKeyMap(Map<dynamic, dynamic> value) =>
    value.map((key, item) => MapEntry(key.toString(), item));

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map) return _stringKeyMap(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_asMap).toList(growable: false);
}

/// 记录级币种字段：既有契约用 `currency`，规范 16 §2 统一字段名 `currencyCode`。
/// 两者都支持，快照优先（`currency` > `currencyCode` > `currency_code`）。
Object? _currencyRaw(Map<String, dynamic> json) =>
    json['currency'] ?? json['currencyCode'] ?? json['currency_code'];

/// 最小单位金额 + 币种。金额本身不做任何运算，格式化只做最小单位 -> 主单位的展示换算。
class KtvMoney {
  const KtvMoney({required this.minorUnits, this.currency = ''});

  /// 记录自带币种为空时回退当前租户币种（规范 §3.6：有快照以快照为准）。
  factory KtvMoney.parse(Object? amount, Object? currency) {
    final code = Currency.normalize(_jsonString(currency));
    return KtvMoney(
      minorUnits: _jsonInt(amount),
      currency: code.isEmpty ? Currency.currentCode : code,
    );
  }

  final int minorUnits;
  final String currency;

  bool get isZero => minorUnits == 0;

  /// 展示字符串：符号 + 主单位金额（如 32400 CNY -> "¥324.00"）。
  String get formatted => formatMoney(minorUnits, currency);

  /// 无符号主单位文本（输入框回填，如 32400 CNY -> "324.00"）。
  String get amountPlain => formatAmountPlain(minorUnits, currency);

  /// 币种展示名称（如 CNY -> 人民币），界面不得裸露 `CNY` 裸码。
  String get currencyLabel => Currency.labelOf(currency);

  @override
  String toString() => formatted;
}

/// 兼容旧调用点的别名：等价于 `lib/core/currency.dart` 的 `formatMoney`。
@Deprecated('唯一入口已收敛到 lib/core/currency.dart 的 formatMoney')
String formatKtvAmount(int minorUnits, String currency) =>
    formatMoney(minorUnits, currency);

/// 订单状态中文（`ord_order.status`）：后端全部状态都要有中文，**不得把英文枚举透给收银员**。
///
/// 口径与 Web 后台 `gv_saas_admin` 的 `constants/terms.js#ORDER_STATUS_TEXT` 对齐（含 `WAITING_SETTLEMENT`
/// =「待结算」）；未登记的新状态回退原码（可见、可排查），不用猜的中文。
const Map<String, String> ktvOrderStatusText = {
  'DRAFT': '进行中',
  'SERVING': '服务中',
  'WAITING_SETTLEMENT': '待结算',
  'WAITING_PAYMENT': '待支付',
  'WAITING_ARRIVAL': '待到店',
  'COMPLETED': '已完成',
  'PARTIAL_REFUNDED': '部分退款',
  'REFUNDED': '已退款',
  'VOIDED': '已作废',
  'CANCELLED': '已取消',
};

/// 订单状态 -> 中文（唯一入口；大小写不敏感，未知状态回退原码）。
String orderStatusLabel(String status) {
  final key = status.toUpperCase();
  return ktvOrderStatusText[key] ?? status;
}

/// 包厢/服务人员资源看板条目（GET /api/v1/business/resources）。
class KtvRoom {
  const KtvRoom({
    required this.id,
    required this.code,
    required this.name,
    required this.resourceType,
    required this.status,
    required this.boardStatus,
    this.occupationStatus,
    this.orderId,
    this.sessionId,
    this.updatedAt,
  });

  factory KtvRoom.fromJson(Map<String, dynamic> json) {
    final occupation = _asMap(json['occupation']);
    return KtvRoom(
      id: _jsonString(json['id'] ?? json['resourceId']),
      code: _jsonString(json['resourceCode'] ?? json['code']),
      name: _jsonString(json['name'] ?? json['resourceName']),
      resourceType: _jsonString(json['resourceType'] ?? json['type']),
      status: _jsonString(json['status']),
      boardStatus: _jsonString(
        json['boardStatus'] ?? json['sessionStatus'] ?? occupation['status'],
      ),
      occupationStatus: _jsonString(occupation['status']),
      orderId: _jsonString(json['orderId'] ?? occupation['orderId']),
      sessionId: _jsonString(json['sessionId'] ?? occupation['sessionId']),
      updatedAt: _parseTime(json['updatedAt']),
    );
  }

  final String id;
  final String code;
  final String name;
  final String resourceType;
  final String status;
  final String boardStatus;
  final String? occupationStatus;
  final String? orderId;
  final String? sessionId;
  final DateTime? updatedAt;

  bool get isRoom => resourceType == 'KTV_ROOM';

  /// 看板投影：可用 / 已预订 / 使用中 / 不可用（KTV_BUSINESS_01 3.2）。
  /// 「已预订」与 Web 后台 `RESOURCE_STATE_TEXT.RESERVED` 一致（包厢被预订是资源态，
  /// 不要和会话态「待开台」混用，见 [KtvSession.statusText]）。
  String get displayStatus => switch (boardStatus.toUpperCase()) {
        'RESERVED' => '已预订',
        'IN_USE' || 'OPEN' || 'PAUSED' => '使用中',
        'DISABLED' || 'MAINTENANCE' || 'UNAVAILABLE' => '不可用',
        _ => '可用',
      };

  bool get isBusy => const {'IN_USE', 'OPEN', 'PAUSED', 'RESERVED'}.contains(
        boardStatus.toUpperCase(),
      );

  bool get isAvailable => !isBusy && boardStatus.toUpperCase() != 'UNAVAILABLE';
}

/// 订单（创建 / 详情 / 工作台）。金额由服务端返回，客户端只读。
class KtvOrder {
  const KtvOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    this.roomId,
    this.roomName,
    this.customerMasked,
    this.sessionId,
    this.sessionStatus,
    required this.totalAmount,
    KtvMoney? liveTotalAmount,
    required this.paidAmount,
    required this.currency,
    required this.allowedActions,
    this.expectedVersion = 0,
    this.createdAt,
  }) : liveTotalAmount = liveTotalAmount ?? totalAmount;

  factory KtvOrder.fromJson(Map<String, dynamic> json) {
    // 「可直接展示总额」：服务端订单投影给 liveTotalAmount（也已见 live_total_amount
    // 的 snake_case 契约）。老后端 / 字段为空时回退 totalAmount，展示口径恒定。
    final liveRaw = json['liveTotalAmount'] ?? json['live_total_amount'];
    return KtvOrder(
      id: _jsonString(json['id'] ?? json['orderId']),
      orderNo: _jsonString(json['orderNo']),
      status: _jsonString(json['status']),
      roomId: _jsonString(json['roomId']),
      roomName: _jsonString(json['roomName'] ?? json['roomCode']),
      customerMasked: _jsonString(json['customerMasked'] ?? json['customer']),
      sessionId: _jsonString(json['sessionId']),
      sessionStatus: _jsonString(json['sessionStatus']),
      totalAmount: KtvMoney.parse(json['totalAmount'], _currencyRaw(json)),
      liveTotalAmount: KtvMoney.parse(
        _jsonStringOrNull(liveRaw) == null ? json['totalAmount'] : liveRaw,
        _currencyRaw(json),
      ),
      paidAmount: KtvMoney.parse(json['paidAmount'], _currencyRaw(json)),
      currency: _jsonString(_currencyRaw(json)).toUpperCase(),
      allowedActions: _asStringList(json['allowedActions']),
      expectedVersion: _jsonInt(json['expectedVersion'] ?? json['version']),
      createdAt: _parseTime(json['createdAt']),
    );
  }

  final String id;
  final String orderNo;
  final String status;
  final String? roomId;
  final String? roomName;
  final String? customerMasked;
  final String? sessionId;
  final String? sessionStatus;

  /// 落库总额（结台后为最终应收）。界面展示**不要**直接用它，见 [liveTotalAmount]。
  final KtvMoney totalAmount;

  /// 服务端「可直接展示的实时总额」：已包含当前会话的实时包厢费，结台后退回落库总额。
  ///
  /// **界面一律展示这个值**（唯一入口），**绝不在它上面再加一次包厢费估算**：
  /// Web 后台曾用「订单总额 + 前端包厢费估算」拼展示金额，同一单账单 6150 / 卡片 10150，
  /// 包厢费被算了两遍。服务端已经算好了，客户端只负责格式化。
  ///
  /// 兼容：响应里 `liveTotalAmount` / `live_total_amount` 都认；都没有（老后端）时
  /// 构造期回退 [totalAmount]，所以展示口径恒定。
  final KtvMoney liveTotalAmount;

  final KtvMoney paidAmount;
  final String currency;
  final List<String> allowedActions;
  final int expectedVersion;
  final DateTime? createdAt;

  /// 币种展示名称（如 人民币），界面不得裸露 `CNY` 裸码。
  String get currencyLabel => Currency.labelOf(currency);

  bool can(String action) =>
      allowedActions.map((a) => a.toLowerCase()).contains(action.toLowerCase());
}

/// KTV 会话（履约状态机：RESERVED/OPEN/PAUSED/CLOSED/CANCELLED）。
class KtvSession {
  const KtvSession({
    required this.id,
    required this.orderId,
    required this.status,
    this.billingStartAt,
    this.pausedSeconds = 0,
    this.openedAt,
    this.closedAt,
    this.expectedVersion = 0,
  });

  factory KtvSession.fromJson(Map<String, dynamic> json) => KtvSession(
        id: _jsonString(json['id'] ?? json['sessionId']),
        orderId: _jsonString(json['orderId']),
        status: _jsonString(json['status']),
        billingStartAt:
            _parseTime(json['billingStartAt'] ?? json['billing_start_at']),
        pausedSeconds:
            _jsonInt(json['pausedSeconds'] ?? json['paused_seconds']),
        openedAt: _parseTime(json['openedAt'] ?? json['opened_at']),
        closedAt: _parseTime(json['closedAt'] ?? json['closed_at']),
        expectedVersion: _jsonInt(json['expectedVersion'] ?? json['version']),
      );

  final String id;
  final String orderId;
  final String status;
  final DateTime? billingStartAt;
  final int pausedSeconds;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final int expectedVersion;

  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isPaused => status.toUpperCase() == 'PAUSED';
  bool get isReserved => status.toUpperCase() == 'RESERVED';
  bool get isClosed => status.toUpperCase() == 'CLOSED';

  /// 会话状态中文：SESSION 的 `RESERVED` 是「**待开台**」（会话尚未开始），不是「包厢被预订」；
  /// 与后台 `SESSION_STATUS_TEXT`、H5 `SESSION_STATUS_TEXT` 三端一致，未知状态回退原码。
  String get statusText => switch (status.toUpperCase()) {
        'RESERVED' => '待开台',
        'OPEN' => '计时中',
        'PAUSED' => '已暂停',
        'CLOSED' => '已结台',
        'CANCELLED' => '已取消',
        _ => status,
      };
}

/// 账单明细行（计时费/加项/服务人员费）。
class KtvBillLine {
  const KtvBillLine({
    required this.itemType,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
  });

  factory KtvBillLine.fromJson(Map<String, dynamic> json) => KtvBillLine(
        itemType: _jsonString(json['itemType'] ?? json['type']),
        name: _jsonString(json['name']),
        unitPrice: KtvMoney.parse(json['unitPrice'], _currencyRaw(json)),
        quantity: _jsonInt(json['quantity'], 1),
        amount: KtvMoney.parse(json['amount'], _currencyRaw(json)),
      );

  final String itemType;
  final String name;
  final KtvMoney unitPrice;
  final int quantity;
  final KtvMoney amount;
}

/// 优惠明细行（券/折扣/满减/会员价）。
class KtvPromotionLine {
  const KtvPromotionLine(
      {required this.type, required this.name, required this.amount});

  factory KtvPromotionLine.fromJson(Map<String, dynamic> json) =>
      KtvPromotionLine(
        type: _jsonString(json['type']),
        name: _jsonString(json['name']),
        amount: KtvMoney.parse(json['amount'], _currencyRaw(json)),
      );

  final String type;
  final String name;
  final KtvMoney amount;
}

/// 客户消费账单（GET /api/v1/business/orders/{id}/bill）。
/// 只展示服务端账单快照，不本地计算金额。
class KtvBill {
  const KtvBill({
    required this.orderId,
    required this.orderNo,
    required this.currency,
    required this.roomFee,
    required this.items,
    required this.serverFee,
    required this.promotions,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.paidByMethod,
    required this.changeAmount,
  });

  factory KtvBill.fromJson(Map<String, dynamic> json) {
    final currency = _jsonString(_currencyRaw(json)).toUpperCase();
    final paidByMethod = _asMap(json['paidByMethod']);
    return KtvBill(
      orderId: _jsonString(json['orderId']),
      orderNo: _jsonString(json['orderNo']),
      currency: currency,
      roomFee: KtvBillLine.fromJson(_asMap(json['roomFee'])),
      items: _asMapList(json['items'])
          .map(KtvBillLine.fromJson)
          .toList(growable: false),
      serverFee: KtvBillLine.fromJson(_asMap(json['serverFee'])),
      promotions: _asMapList(json['promotions'])
          .map(KtvPromotionLine.fromJson)
          .toList(growable: false),
      subtotalAmount: KtvMoney.parse(json['subtotalAmount'], currency),
      discountAmount: KtvMoney.parse(json['discountAmount'], currency),
      taxAmount: KtvMoney.parse(json['taxAmount'], currency),
      totalAmount: KtvMoney.parse(json['totalAmount'], currency),
      paidAmount: KtvMoney.parse(json['paidAmount'], currency),
      paidByMethod: KtvMoney.parse(paidByMethod['cash'], currency),
      changeAmount: KtvMoney.parse(json['changeAmount'], currency),
    );
  }

  final String orderId;
  final String orderNo;
  final String currency;
  final KtvBillLine roomFee;
  final List<KtvBillLine> items;
  final KtvBillLine serverFee;
  final List<KtvPromotionLine> promotions;
  final KtvMoney subtotalAmount;
  final KtvMoney discountAmount;
  final KtvMoney taxAmount;
  final KtvMoney totalAmount;
  final KtvMoney paidAmount;
  final KtvMoney paidByMethod;
  final KtvMoney changeAmount;

  /// 币种展示名称（如 人民币），界面不得裸露 `CNY` 裸码。
  String get currencyLabel => Currency.labelOf(currency);
}

/// 可用支付方式（GET /api/v1/business/payments/available-methods）。
///
/// **数量口径**：`WALLET`（储值币/代币）与 `POINT`（积分）不是货币，界面只显示
/// 个数，绝不出现货币符号与币种码：
/// - `WALLET` 的数量优先取服务端 `tokenAmount`（纯数字字符串）；字段缺失时按
///   租户比例 `walletRatio`（缺省 100）从 [balance]（最小货币单位）降级换算；
/// - `POINT` 就是个数（1:1，不乘任何比例），服务端给数量就用数量，否则退回
///   服务端下发的余额数值本身。
class KtvPaymentMethod {
  const KtvPaymentMethod({
    required this.method,
    required this.enabled,
    required this.displayName,
    this.balance = const KtvMoney(minorUnits: 0, currency: ''),
    this.hasBalance = false,
    this.tokenAmount,
    this.tokenBrandName,
    this.walletRatio,
  });

  factory KtvPaymentMethod.fromJson(Map<String, dynamic> json) {
    final ratio = _jsonIntOrNull(json['walletRatio'] ?? json['wallet_ratio']);
    return KtvPaymentMethod(
      method: _jsonString(json['method']).toUpperCase(),
      enabled: json['enabled'] == true || json['enabled'] != false,
      displayName: _jsonString(json['displayName'] ?? json['name']),
      balance: KtvMoney.parse(json['balance'], _currencyRaw(json)),
      hasBalance: json['balance'] != null,
      tokenAmount:
          _jsonStringOrNull(json['tokenAmount'] ?? json['token_amount']),
      tokenBrandName:
          _jsonStringOrNull(json['tokenBrandName'] ?? json['token_brand_name']),
      walletRatio: ratio == null || ratio <= 0 ? null : ratio,
    );
  }

  final String method;
  final bool enabled;
  final String displayName;
  final KtvMoney balance;

  /// 服务端是否下发了 `balance` 字段（缺失表示能力数据未发布，前端不做超用拦截）。
  final bool hasBalance;

  /// 服务端算好的代币**数量**（纯数字字符串，不带货币符号/币种；只对储值币有意义）。
  final String? tokenAmount;

  /// 储值币品牌展示名（租户配置 `wallet_brand_name` 下发值）。
  final String? tokenBrandName;

  /// 租户储值比例（1 个主单位 = ratio 个代币）；缺失/非法为 null，按缺省 100 降级。
  final int? walletRatio;

  bool get isCash => method == 'CASH';
  bool get isWallet => method == 'WALLET';
  bool get isPoint => method == 'POINT';

  /// 储值币品牌展示名（仅 `WALLET` 使用）：服务端 `tokenBrandName` 优先，其次沿用
  /// 既有 `displayName`（服务端当前就把它当作品牌名），都缺失才回落到唯一缺省。
  String get tokenBrand =>
      tokenBrandName ??
      (displayName.isEmpty ? defaultTokenBrandName : displayName);

  /// 本方式的可用**数量**（个数，与币种无关，绝不参与金额合计）。
  int get availableTokenCount {
    final fromServer = parseTokenCountInput(tokenAmount ?? '');
    if (fromServer != null) return fromServer;
    if (isPoint) return balance.minorUnits;
    return tokenCountFromMinor(balance.minorUnits, walletRatio);
  }

  /// 服务端是否下发了可用于「超用拦截」的可用数量；都没有时交给服务端判定。
  bool get canCheckAvailableBalance =>
      hasBalance || parseTokenCountInput(tokenAmount ?? '') != null;
}

/// 组合收款结果（POST /api/v1/business/orders/{id}/collect）。
class KtvCollectResult {
  const KtvCollectResult({
    required this.remainingAmount,
    required this.currency,
    required this.collectedByMethod,
    required this.changeAmount,
  });

  factory KtvCollectResult.fromJson(Map<String, dynamic> json) {
    final currency = _jsonString(_currencyRaw(json)).toUpperCase();
    return KtvCollectResult(
      remainingAmount: KtvMoney.parse(json['remainingAmount'], currency),
      currency: currency,
      collectedByMethod: _asMapList(json['collectedByMethod'])
          .map(
            (e) => KtvCollectEntry(
              method: _jsonString(e['method']).toUpperCase(),
              amount: KtvMoney.parse(e['amount'], currency),
            ),
          )
          .toList(growable: false),
      changeAmount: KtvMoney.parse(json['changeAmount'], currency),
    );
  }

  final KtvMoney remainingAmount;
  final String currency;
  final List<KtvCollectEntry> collectedByMethod;
  final KtvMoney changeAmount;

  /// 币种展示名称（如 人民币），界面不得裸露 `CNY` 裸码。
  String get currencyLabel => Currency.labelOf(currency);
}

class KtvCollectEntry {
  const KtvCollectEntry({required this.method, required this.amount});

  final String method;
  final KtvMoney amount;
}

/// 班次（POST /api/v1/business/shifts/open|close）。
class KtvShift {
  const KtvShift({
    required this.id,
    required this.status,
    required this.openingCash,
    required this.expectedCash,
    required this.actualCash,
    required this.differenceAmount,
    required this.currency,
    this.openedAt,
    this.closedAt,
  });

  factory KtvShift.fromJson(Map<String, dynamic> json) {
    final currency = _jsonString(_currencyRaw(json)).toUpperCase();
    return KtvShift(
      id: _jsonString(json['id'] ?? json['shiftId']),
      status: _jsonString(json['status']),
      openingCash:
          KtvMoney.parse(json['openingCash'] ?? json['opening_cash'], currency),
      expectedCash: KtvMoney.parse(
          json['expectedCash'] ?? json['expected_cash'], currency),
      actualCash:
          KtvMoney.parse(json['actualCash'] ?? json['actual_cash'], currency),
      differenceAmount: KtvMoney.parse(
        json['differenceAmount'] ?? json['difference_amount'],
        currency,
      ),
      currency: currency,
      openedAt: _parseTime(json['openedAt'] ?? json['opened_at']),
      closedAt: _parseTime(json['closedAt'] ?? json['closed_at']),
    );
  }

  final String id;
  final String status;
  final KtvMoney openingCash;
  final KtvMoney expectedCash;
  final KtvMoney actualCash;
  final KtvMoney differenceAmount;
  final String currency;
  final DateTime? openedAt;
  final DateTime? closedAt;

  bool get isOpen => status.toUpperCase() == 'OPEN';

  /// 币种展示名称（如 人民币），界面不得裸露 `CNY` 裸码。
  String get currencyLabel => Currency.labelOf(currency);
}

/// 点单目录项（GET /api/v1/business/catalog/items）。
///
/// 加项页用它渲染菜单与**可用库存**：`availableQuantity` 为 null 表示该商品不控制库存（不限量），
/// 非 null 时「加号」不得超过它——这是提交前的防超卖；最终扣减仍由 add-item 的服务端原子扣减兜底。
class KtvCatalogItem {
  const KtvCatalogItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.category,
    required this.available,
    required this.unavailableReason,
    required this.stockControlled,
    required this.availableQuantity,
  });

  factory KtvCatalogItem.fromJson(Map<String, dynamic> json) => KtvCatalogItem(
        id: _jsonString(json['id']),
        name: _jsonString(json['name']),
        unit: _jsonString(json['unit']),
        unitPrice: KtvMoney.parse(
            json['unitPrice'] ?? json['unit_price'], _currencyRaw(json)),
        category: _jsonString(json['category']),
        // 缺字段时按「可点」处理：老后端没有 available 字段，不应把整个目录判成售罄。
        available: json['available'] == null ? true : json['available'] == true,
        unavailableReason: _jsonString(
            json['unavailableReason'] ?? json['unavailable_reason']),
        stockControlled:
            json['stockControlled'] == true || json['stock_controlled'] == true,
        availableQuantity: _jsonDouble(
            json['availableQuantity'] ?? json['available_quantity']),
      );

  final String id;
  final String name;
  final String unit;
  final KtvMoney unitPrice;
  final String category;
  final bool available;
  final String unavailableReason;
  final bool stockControlled;
  final double? availableQuantity;

  bool get isSoldOut => !available;

  /// 还能不能再加一件：售罄不可加；受库存控制时不得超过可用库存（提交前的防超卖）。
  /// 服务端 add-item 的原子扣减仍是最终事实（不足会 409 INVENTORY_INSUFFICIENT）。
  bool canIncrease(int currentQuantity) {
    if (!available) return false;
    final limit = availableQuantity;
    return limit == null || currentQuantity < limit;
  }

  /// 展示用库存文案：不控制库存 → 空串；控制库存 → 「库存 N」。
  String get stockText {
    final quantity = availableQuantity;
    if (quantity == null) return '';
    final text = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    return '库存 ' + text;
  }
}

/// 客户自助加项的待确认聚合视图（GET /api/v1/business/orders/pending-approval）。
///
/// 唯一数据源：门店范围内的待确认明细一次拿全，客户端不再自己扫「订单 + 明细」
/// （N+1，且多端计数口径会漂移）。金额语义：
/// - `pendingAmount` 是**最小单位整数**，展示只走 [KtvMoney]；
/// - 仅当命中行币种一致时 `currencyCode` 才有值；混币种时 `mixedCurrency=true`
///   且**不得**把 `pendingAmount` 当成某个币种的金额展示（规范 16 §3 禁止跨币种相加）。
/// - `revision` 是本门店命中行的最大明细 id：未变化即视为同一快照，UI 不必重渲染。
class KtvPendingApprovalView {
  const KtvPendingApprovalView({
    required this.pendingCount,
    required this.pendingAmount,
    required this.currencyCode,
    required this.mixedCurrency,
    required this.revision,
    required this.serverTimeMillis,
    required this.orders,
  });

  factory KtvPendingApprovalView.fromJson(Map<String, dynamic> json) =>
      KtvPendingApprovalView(
        pendingCount: _jsonInt(json['pendingCount'] ?? json['pending_count']),
        pendingAmount:
            _jsonInt(json['pendingAmount'] ?? json['pending_amount']),
        currencyCode: Currency.normalize(
            _jsonString(json['currencyCode'] ?? json['currency_code'])),
        mixedCurrency:
            json['mixedCurrency'] == true || json['mixed_currency'] == true,
        revision: _jsonInt(json['revision']),
        serverTimeMillis:
            _jsonInt(json['serverTimeMillis'] ?? json['server_time_millis']),
        orders: _asMapList(json['orders'])
            .map(KtvPendingOrder.fromJson)
            .toList(growable: false),
      );

  /// 空视图：接口不可达或本门店没有待确认项时使用（不编造任何待确认数据）。
  static const KtvPendingApprovalView empty = KtvPendingApprovalView(
    pendingCount: 0,
    pendingAmount: 0,
    currencyCode: '',
    mixedCurrency: false,
    revision: 0,
    serverTimeMillis: 0,
    orders: <KtvPendingOrder>[],
  );

  final int pendingCount;
  final int pendingAmount;
  final String currencyCode;
  final bool mixedCurrency;
  final int revision;
  final int serverTimeMillis;
  final List<KtvPendingOrder> orders;

  bool get hasPending => pendingCount > 0;

  /// 金额展示文案：混币种时返回空串（调用方只显示条数），其余走唯一金额入口。
  String get amountText => mixedCurrency || currencyCode.isEmpty
      ? ''
      : formatMoney(pendingAmount, currencyCode);

  /// 某订单的待确认条数（订单不在视图里时为 0）。
  int pendingCountOf(String orderId) {
    for (final order in orders) {
      if (order.orderId == orderId) return order.pendingCount;
    }
    return 0;
  }

  KtvPendingOrder? orderOf(String orderId) {
    for (final order in orders) {
      if (order.orderId == orderId) return order;
    }
    return null;
  }

  /// 乐观移除某条明细（确认/拒绝成功后立即收敛角标，随后仍以服务端快照为准）。
  ///
  /// 只做「计数与金额同步减」这一件事，**不**重算币种口径：命中行的币种组合不变时，
  /// 原视图的 `currencyCode`/`mixedCurrency` 仍然成立；减到 0 才清空。
  KtvPendingApprovalView withoutItem(String itemId) {
    final nextOrders = <KtvPendingOrder>[];
    var removed = 0;
    var removedAmount = 0;
    for (final order in orders) {
      final gone = order.items
          .where((item) => item.id == itemId)
          .toList(growable: false);
      if (gone.isEmpty) {
        nextOrders.add(order);
        continue;
      }
      removed += gone.length;
      removedAmount +=
          gone.fold(0, (sum, item) => sum + item.amount.minorUnits);
      final kept = order.items
          .where((item) => item.id != itemId)
          .toList(growable: false);
      if (kept.isEmpty) continue;
      nextOrders.add(order.copyWith(
        pendingCount: order.pendingCount - gone.length,
        pendingAmount: order.pendingAmount -
            gone.fold(0, (sum, item) => sum + item.amount.minorUnits),
        items: kept,
      ));
    }
    if (removed == 0) return this;
    final nextCount = pendingCount - removed;
    return KtvPendingApprovalView(
      pendingCount: nextCount,
      pendingAmount: nextCount <= 0 ? 0 : pendingAmount - removedAmount,
      currencyCode: nextCount <= 0 ? '' : currencyCode,
      mixedCurrency: nextCount <= 0 ? false : mixedCurrency,
      revision: revision,
      serverTimeMillis: serverTimeMillis,
      orders: nextOrders,
    );
  }
}

/// 待确认加项按订单分组的条目。
class KtvPendingOrder {
  const KtvPendingOrder({
    required this.orderId,
    required this.orderNo,
    required this.storeId,
    required this.roomName,
    required this.roomCode,
    required this.sessionStatus,
    required this.orderElapsedSeconds,
    required this.pendingCount,
    required this.pendingAmount,
    required this.items,
  });

  factory KtvPendingOrder.fromJson(Map<String, dynamic> json) =>
      KtvPendingOrder(
        orderId: _jsonString(json['orderId'] ?? json['order_id']),
        orderNo: _jsonString(json['orderNo'] ?? json['order_no']),
        storeId: _jsonString(json['storeId'] ?? json['store_id']),
        roomName: _jsonString(json['roomName'] ?? json['room_name']),
        roomCode: _jsonString(json['roomCode'] ?? json['room_code']),
        sessionStatus:
            _jsonString(json['sessionStatus'] ?? json['session_status']),
        orderElapsedSeconds: _jsonIntOrNull(
            json['orderElapsedSeconds'] ?? json['order_elapsed_seconds']),
        pendingCount: _jsonInt(json['pendingCount'] ?? json['pending_count']),
        pendingAmount:
            _jsonInt(json['pendingAmount'] ?? json['pending_amount']),
        items: _asMapList(json['items'])
            .map(KtvPendingItem.fromJson)
            .toList(growable: false),
      );

  final String orderId;
  final String orderNo;
  final String storeId;
  final String roomName;
  final String roomCode;
  final String sessionStatus;
  final int? orderElapsedSeconds;
  final int pendingCount;
  final int pendingAmount;
  final List<KtvPendingItem> items;

  KtvPendingOrder copyWith({
    int? pendingCount,
    int? pendingAmount,
    List<KtvPendingItem>? items,
  }) =>
      KtvPendingOrder(
        orderId: orderId,
        orderNo: orderNo,
        storeId: storeId,
        roomName: roomName,
        roomCode: roomCode,
        sessionStatus: sessionStatus,
        orderElapsedSeconds: orderElapsedSeconds,
        pendingCount: pendingCount ?? this.pendingCount,
        pendingAmount: pendingAmount ?? this.pendingAmount,
        items: items ?? this.items,
      );

  /// 包厢展示名（可直接渲染）：服务端 `roomName` 已按「会话名称快照 → 编码快照 → 按资源 ID 回源」
  /// 给全，缺失时先退回 `roomCode`；两者都没有（订单没有包厢会话 / 资源服务不可达）时明确
  /// 「未关联包厢」—— 收银端处理待确认加项时必须先看清是**哪间包厢**的需求，留空会被当成加载失败。
  String get roomLabel {
    if (roomName.isNotEmpty) return roomName;
    if (roomCode.isNotEmpty) return roomCode;
    return '未关联包厢';
  }
}

/// 客户自助提交、等待运营确认的加项明细。
class KtvPendingItem {
  const KtvPendingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.createdAt,
  });

  factory KtvPendingItem.fromJson(Map<String, dynamic> json) {
    final currency = _currencyRaw(json);
    return KtvPendingItem(
      id: _jsonString(json['id']),
      name: _jsonString(json['name'] ?? json['nameSnapshot']),
      quantity: _jsonDouble(json['quantity']) ?? 1,
      unitPrice: KtvMoney.parse(
        json['unitPrice'] ?? json['unit_price'],
        currency,
      ),
      amount: KtvMoney.parse(json['amount'], currency),
      createdAt: _parseTime(json['createdAt'] ?? json['created_at']),
    );
  }

  final String id;
  final String name;
  final double quantity;
  final KtvMoney unitPrice;
  final KtvMoney amount;
  final DateTime? createdAt;

  /// 数量文案：整数不显示小数点（1.0 → "1"）。
  String get quantityText => quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();
}

/// 路由间传递的 KTV 会话上下文（orderId / sessionId / 包厢）。
class KtvSessionArgs {
  const KtvSessionArgs({
    this.orderId,
    this.sessionId,
    this.roomId,
    this.roomName,
  });

  final String? orderId;
  final String? sessionId;
  final String? roomId;
  final String? roomName;
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList(growable: false);
}

DateTime? _parseTime(Object? value) {
  if (value == null) return null;
  return parseUtcDateTime(value) ?? DateTime.tryParse(value.toString());
}
