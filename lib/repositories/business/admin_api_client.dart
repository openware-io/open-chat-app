import 'package:dio/dio.dart';

import '../../core/config.dart';

/// 移动端 B 端登录：identity 员工账号签发 JWT → 换 B 端门店会话 → 酒店任务。
///
/// 不再复用 SaaS 后台 Web 的 admin Cookie。
class AdminApiClient {
  AdminApiClient._();

  static final AdminApiClient instance = AdminApiClient._();

  static const _appId = 'saas-b';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiPrefix,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  String? _cookie;
  String? _csrfToken;
  String? role;
  String? storeName;
  String? contextId;

  String get _referer {
    final base = AppConfig.apiBase.replaceFirst(RegExp(r'/+$'), '');
    return '$base/b/';
  }

  bool get authenticated => _cookie != null && _cookie!.isNotEmpty;

  Future<void> login(String username, String password) async {
    final login = await _dio.post<Map<String, dynamic>>(
      '/identity/login',
      data: {
        'loginType': 'USERNAME',
        'loginIdentifier': username,
        'credential': password,
      },
    );
    final accessToken = login.data?['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('员工登录未返回访问令牌');
    }
    final session = await _dio.post<Map<String, dynamic>>(
      '/auth/session',
      queryParameters: {'appId': _appId},
      options: Options(headers: {'Authorization': 'Bearer $accessToken', 'Referer': _referer}),
    );
    _cookie = _readCookie(session.headers);
    if (_cookie == null) {
      throw StateError('B端会话未返回 Cookie');
    }
    await _selectStoreContext();
  }

  Future<void> _selectStoreContext() async {
    final csrf = await _dio.get<Map<String, dynamic>>(
      '/auth/csrf',
      queryParameters: {'appId': _appId},
      options: Options(headers: _headers()),
    );
    _csrfToken = csrf.data?['csrfToken'] as String?;
    final contexts = await _dio.get<Map<String, dynamic>>(
      '/auth/contexts',
      queryParameters: {'appId': _appId},
      options: Options(headers: _headers()),
    );
    final items = (contexts.data?['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final store = items.where((item) => (item['storeId'] as num?) != null).toList();
    if (store.isEmpty) {
      throw StateError('当前员工没有门店上下文');
    }
    final selected = store.first;
    contextId = selected['contextId'] as String?;
    storeName = selected['storeName'] as String?;
    final roles = (selected['roles'] as List?)?.cast<String>() ?? const [];
    role = roles.contains('store.cashier') ? 'cashier' : 'manager';
    if (contextId == null) {
      throw StateError('门店上下文缺少 contextId');
    }
    await _dio.post<void>(
      '/auth/context/select',
      queryParameters: {'appId': _appId},
      data: {'contextId': contextId},
      options: Options(headers: {
        ..._headers(),
        if (_csrfToken != null) 'X-CSRF-Token': _csrfToken!,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> hotelTasks() async {
    if (!authenticated) return const [];
    final response = await _dio.get<List<dynamic>>(
      '/business/hotel/frontdesk/tasks',
      options: Options(headers: _headers()),
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Future<Map<String, dynamic>> checkInHotelBooking(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/business/hotel/frontdesk/bookings/$id/checkin',
      options: Options(headers: _csrfHeaders()),
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> checkOutHotelBooking(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/business/hotel/frontdesk/bookings/$id/checkout',
      options: Options(headers: _csrfHeaders()),
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> hotelFolio(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/business/hotel/frontdesk/bookings/$id/folio',
      options: Options(headers: _headers()),
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> collectHotelDeposit(int id, int amountMinor) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/business/hotel/frontdesk/bookings/$id/deposit',
      data: {'amountMinor': amountMinor, 'note': '移动前台押金'},
      options: Options(headers: _csrfHeaders()),
    );
    return response.data ?? const {};
  }

  Future<Map<String, dynamic>> extendHotelBooking(int id, String newCheckOutDate) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/business/hotel/frontdesk/bookings/$id/extend',
      data: {'newCheckOutDate': newCheckOutDate},
      options: Options(headers: _csrfHeaders()),
    );
    return response.data ?? const {};
  }

  Map<String, String> _csrfHeaders() {
    return {
      ..._headers(),
      if (_csrfToken != null) 'X-CSRF-Token': _csrfToken!,
    };
  }

  Map<String, String> _headers() {
    return {
      'Referer': _referer,
      if (_cookie != null) 'Cookie': _cookie!,
    };
  }

  String? _readCookie(Headers headers) {
    for (final entry in headers.map.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') continue;
      for (final raw in entry.value) {
        final part = raw.split(';').first.trim();
        if (part.startsWith('saas_b_session=') || part.startsWith('saas_c_session=')) {
          return part;
        }
      }
    }
    return null;
  }
}
