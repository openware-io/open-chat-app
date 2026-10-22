import 'package:dio/dio.dart';

import '../../core/config.dart';

/// 移动端 B 端登录/门店上下文/酒店任务的轻量客户端。
///
/// 复用 SaaS 后台的 HttpOnly 会话：登录后保存 `saas_admin_session` Cookie，
/// 选择门店上下文后按角色读取酒店前台任务。原型阶段不做持久化 Cookie。
class AdminApiClient {
  AdminApiClient._();

  static final AdminApiClient instance = AdminApiClient._();

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

  bool get authenticated => _cookie != null && _cookie!.isNotEmpty;

  Future<void> login(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/auth/login',
      data: {'username': username, 'password': password, 'ttlHours': 8},
    );
    _cookie = _readCookie(response.headers);
    if (_cookie == null) {
      throw StateError('后台未返回会话 Cookie');
    }
    final roles =
        (response.data?['roles'] as List?)?.cast<String>() ?? const [];
    role = roles.contains('store.cashier')
        ? 'cashier'
        : roles.contains('store.manager')
            ? 'manager'
            : 'manager';
    await _selectStoreContext();
  }

  Future<void> _selectStoreContext() async {
    final csrf = await _dio.get<Map<String, dynamic>>(
      '/admin/auth/csrf',
      options: Options(headers: _headers()),
    );
    _csrfToken = csrf.data?['csrfToken'] as String?;
    final contexts = await _dio.get<Map<String, dynamic>>(
      '/admin/contexts',
      options: Options(headers: _headers()),
    );
    final items =
        (contexts.data?['items'] as List?)?.cast<Map<String, dynamic>>() ??
            const [];
    final store =
        items.where((item) => (item['storeId'] as num?) != null).toList();
    if (store.isEmpty) {
      throw StateError('当前账号没有门店上下文');
    }
    final selected = store.first;
    contextId = selected['contextId'] as String?;
    storeName = selected['storeName'] as String?;
    if (contextId == null) {
      throw StateError('门店上下文缺少 contextId');
    }
    await _dio.post<void>(
      '/admin/context/select',
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
      '/admin/hotel/frontdesk/tasks',
      options: Options(headers: _headers()),
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }

  Map<String, String> _headers() {
    return {
      if (_cookie != null) 'Cookie': _cookie!,
    };
  }

  String? _readCookie(Headers headers) {
    for (final entry in headers.map.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') continue;
      for (final raw in entry.value) {
        final part = raw.split(';').first.trim();
        if (part.startsWith('saas_admin_session=')) return part;
      }
    }
    return null;
  }
}
