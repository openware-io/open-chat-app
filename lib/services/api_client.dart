import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../core/api_failure.dart';
import '../core/config.dart';
import '../core/local_storage.dart';
import 'api_message_localizer.dart';

typedef OnUnauthorized = void Function();

class ApiClient {
  ApiClient(this._storage) {
    _packageInfo = PackageInfo.fromPlatform().catchError(
      (_) => PackageInfo(
        appName: 'VVVChat',
        packageName: 'unknown',
        version: 'unknown',
        buildNumber: 'unknown',
      ),
    );
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiPrefix,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = _storage.token;
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          options.headers['x-lang'] = _storage.resolveApiLanguageCode();
          options.headers['X-Client-Contract'] = 'im-v1';
          options.headers['X-Client-Platform'] =
              kIsWeb ? 'web' : defaultTargetPlatform.name;
          final packageInfo = await _packageInfo;
          options.headers['X-Client-Version'] = packageInfo.version;
          options.headers['X-Client-Build'] = packageInfo.buildNumber;
          if (_isWriteMethod(options.method) &&
              !options.headers.containsKey('Idempotency-Key')) {
            options.headers['Idempotency-Key'] = const Uuid().v4();
          }
          _logApiRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final raw = response.data;
          if (raw is Map &&
              raw.containsKey('data') &&
              (raw.containsKey('requestId') || raw.length <= 2)) {
            response.data = raw['data'];
          }
          _logApiResponse(response);
          return handler.next(response);
        },
        onError: (e, handler) {
          _logApiError(e);
          final failure = ApiFailure.fromDio(
            e,
            fallbackMessage: _networkErrorMessage,
          );
          if (failure.requiresLogin) {
            onUnauthorized?.call();
          }
          return handler.next(e.copyWith(error: failure));
        },
      ),
    );
  }

  final LocalStorage _storage;
  OnUnauthorized? onUnauthorized;
  late final Dio _dio;
  late final Future<PackageInfo> _packageInfo;

  Dio get dio => _dio;

  String get _networkErrorMessage => lookupAppLocalizations(
        Locale(_storage.resolveApiLanguageCode()),
      ).commonNetworkError;

  bool _isWriteMethod(String method) {
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

  Future<String> requestWebSocketTicket() async {
    final response = await _dio.post<dynamic>('/auth/ws-ticket');
    final raw = response.data;
    final body = raw is Map ? Map<String, dynamic>.from(raw) : null;
    final nested = body?['data'];
    final payload = nested is Map ? Map<String, dynamic>.from(nested) : body;
    final ticket = payload?['ticket']?.toString().trim() ?? '';
    if (ticket.isEmpty) {
      throw StateError('WebSocket ticket response is missing ticket');
    }
    return ticket;
  }

  bool _shouldLog(RequestOptions _) => kDebugMode;

  String _prettyJson(Object? value) {
    if (value == null) return 'null';
    try {
      return const JsonEncoder.withIndent('  ').convert(_redact(value));
    } catch (_) {
      return '<unserializable>';
    }
  }

  Object? _redact(Object? value) {
    if (value is FormData) {
      return {
        'fields': {
          for (final field in value.fields) field.key: field.value,
        },
        'files': [
          for (final file in value.files)
            {
              'field': file.key,
              'filename': file.value.filename,
              'length': file.value.length,
            },
        ],
      };
    }
    if (value is List) return value.map(_redact).toList(growable: false);
    if (value is! Map) return value;
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final normalized = key.toLowerCase();
      final sensitive = normalized.contains('token') ||
          normalized.contains('password') ||
          normalized == 'phone' ||
          normalized == 'contactname' ||
          normalized == 'content' ||
          normalized == 'url' ||
          normalized == 'ticket';
      result[key] = sensitive ? '<redacted>' : _redact(entry.value);
    }
    return result;
  }

  void _logApiRequest(RequestOptions options) {
    if (!_shouldLog(options)) return;
    debugPrint('[API DEBUG] -> ${options.method} ${options.uri}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint(
        '[API DEBUG] query:\n${_prettyJson(options.queryParameters)}',
      );
    }
    if (options.data != null) {
      debugPrint('[API DEBUG] body:\n${_prettyJson(options.data)}');
    }
  }

  void _logApiResponse(Response<dynamic> response) {
    if (!_shouldLog(response.requestOptions)) return;
    debugPrint(
      '[API DEBUG] <- ${response.statusCode} '
      '${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    debugPrint('[API DEBUG] response:\n${_prettyJson(response.data)}');
  }

  void _logApiError(DioException error) {
    if (!kDebugMode) return;
    final request = error.requestOptions;
    debugPrint(
      '[API DEBUG] !! ${error.response?.statusCode ?? 'NETWORK'} '
      '${request.method} ${request.uri}',
    );
    debugPrint(
      '[API DEBUG] error type: ${error.type}\n'
      '[API DEBUG] error message: ${error.message}',
    );
    if (request.queryParameters.isNotEmpty) {
      debugPrint(
        '[API DEBUG] error query:\n${_prettyJson(request.queryParameters)}',
      );
    }
    if (request.data != null) {
      debugPrint('[API DEBUG] error body:\n${_prettyJson(request.data)}');
    }
    debugPrint(
      '[API DEBUG] error response:\n${_prettyJson(error.response?.data)}',
    );
  }

  String extractErrorMessage(dynamic err) {
    if (err is ApiFailure) return _localizeApiMessage(err.message);
    if (err is DioException) {
      final failure = err.error;
      if (failure is ApiFailure) return _localizeApiMessage(failure.message);
      return _localizeApiMessage(ApiFailure.fromDio(
        err,
        fallbackMessage: _networkErrorMessage,
      ).message);
    }
    return err.toString();
  }

  /// 服务端错误文案本地化：统一走 [localizeServerMessage]，
  /// 保证与 [ApiFailure.messageOf] 使用同一张表、同一套语言判定（避免两套路径语言不一致）。
  String _localizeApiMessage(String message) => localizeServerMessage(message);
}
