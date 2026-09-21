import 'package:dio/dio.dart';

import '../services/api_message_localizer.dart';

String? _readErrorText(Object? value) {
  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
  if (value is List) {
    final texts = value.map(_readErrorText).whereType<String>().toList();
    return texts.isEmpty ? null : texts.join(', ');
  }
  if (value is Map) {
    return _readErrorText(value['message']) ??
        _readErrorText(value['error']) ??
        _readErrorText(value['detail']);
  }
  return null;
}

class ApiFailure implements Exception {
  const ApiFailure({
    required this.message,
    this.statusCode,
    this.code,
    this.requestId,
    this.retryable = false,
    this.fieldErrors = const {},
  });

  factory ApiFailure.fromDio(
    DioException error, {
    required String fallbackMessage,
  }) {
    final response = error.response;
    final raw = response?.data;
    final body = raw is Map ? Map<String, dynamic>.from(raw) : const {};
    final message = _readErrorText(body['message']) ??
        _readErrorText(body['error']) ??
        _readErrorText(body['detail']) ??
        _readErrorText(raw) ??
        fallbackMessage;
    final rawFieldErrors = body['fieldErrors'];
    return ApiFailure(
      statusCode: response?.statusCode,
      code: body['code']?.toString(),
      message: message,
      requestId: body['requestId']?.toString() ??
          response?.headers.value('x-request-id'),
      retryable: body['retryable'] == true ||
          response?.statusCode == 429 ||
          (response?.statusCode ?? 0) >= 500,
      fieldErrors: rawFieldErrors is Map
          ? rawFieldErrors.map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : const {},
    );
  }

  /// 从任意异常中提取面向用户的友好信息：优先取 [ApiFailure.message]，
  /// 其次取 DioException 内部注入的 [ApiFailure]（ApiClient 拦截器统一转换），
  /// 最后才回退到原始字符串，避免把 DioException 堆栈暴露给用户。
  ///
  /// 提取后统一做**服务端文案本地化**：服务端没有 i18n，错误一律返回英文
  /// （另有少量硬编码中文），若不翻译会在界面上漏出另一种语言。
  ///
  /// 币种类错误（`CURRENCY_MISMATCH` /
  /// `CURRENCY_PAYMENT_METHOD_UNSUPPORTED` /
  /// `CURRENCY_SWITCH_BLOCKED_BY_BALANCE`）按**错误码**优先翻译，
  /// 因为码比文案稳定。
  static String messageOf(Object error) {
    final byCode = localizeErrorCode(codeOf(error));
    if (byCode != null) return byCode;
    return localizeServerMessage(rawMessageOf(error));
  }

  /// 提取服务端错误码（[ApiFailure.code]，含 DioException 内层注入的实例）。
  static String? codeOf(Object error) {
    if (error is ApiFailure) return error.code;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiFailure) return inner.code;
    }
    return null;
  }

  /// 不做本地化的原始提取（仅用于需要自行处理的场景）。
  static String rawMessageOf(Object error) {
    if (error is ApiFailure) return error.message;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiFailure) return inner.message;
      // 拦截器正常情况下必注入 ApiFailure；此处兜底避免网络异常时泄露堆栈。
      return ApiFailure.fromDio(error, fallbackMessage: '').message;
    }
    if (error is String) {
      final text = error.trim();
      if (text.isNotEmpty) return text;
    }
    return error.toString();
  }

  final int? statusCode;
  final String? code;
  final String message;
  final String? requestId;
  final bool retryable;
  final Map<String, dynamic> fieldErrors;

  bool get requiresLogin =>
      statusCode == 401 ||
      code == 'AUTH_TOKEN_INVALID' ||
      code == 'AUTH_TOKEN_EXPIRED';

  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}
