import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/api_failure.dart';

void main() {
  test('maps v1 error fields and authentication semantics', () {
    final request = RequestOptions(path: '/users/me');
    final failure = ApiFailure.fromDio(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 401,
          data: {
            'code': 'AUTH_TOKEN_EXPIRED',
            'message': '登录已过期',
            'requestId': 'request-1',
            'retryable': false,
            'fieldErrors': <String, dynamic>{},
          },
        ),
      ),
      fallbackMessage: '网络错误',
    );

    expect(failure.statusCode, 401);
    expect(failure.code, 'AUTH_TOKEN_EXPIRED');
    expect(failure.message, '登录已过期');
    expect(failure.requestId, 'request-1');
    expect(failure.requiresLogin, isTrue);
    expect(failure.isForbidden, isFalse);
  });

  test('403 keeps login state and 5xx is retryable', () {
    final forbiddenRequest = RequestOptions(path: '/groups/1');
    final forbidden = ApiFailure.fromDio(
      DioException(
        requestOptions: forbiddenRequest,
        response: Response<dynamic>(
          requestOptions: forbiddenRequest,
          statusCode: 403,
          data: {'code': 'FORBIDDEN', 'message': '无权限'},
        ),
      ),
      fallbackMessage: '网络错误',
    );
    expect(forbidden.requiresLogin, isFalse);
    expect(forbidden.isForbidden, isTrue);

    final serverRequest = RequestOptions(path: '/messages/history');
    final server = ApiFailure.fromDio(
      DioException(
        requestOptions: serverRequest,
        response: Response<dynamic>(
          requestOptions: serverRequest,
          statusCode: 503,
          data: {'code': 'INTERNAL_ERROR', 'message': '稍后重试'},
        ),
      ),
      fallbackMessage: '网络错误',
    );
    expect(server.retryable, isTrue);
  });

  test('uses the backend error field without Dio exception details', () {
    final request = RequestOptions(path: '/media/upload-sessions');
    final failure = ApiFailure.fromDio(
      DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 400,
          data: {'error': 'MEDIA_TYPE_NOT_ALLOWED'},
        ),
      ),
      fallbackMessage: 'Network error',
    );

    expect(failure.message, 'MEDIA_TYPE_NOT_ALLOWED');
    expect(failure.toString(), 'MEDIA_TYPE_NOT_ALLOWED');
  });

  test('uses a friendly fallback instead of raw Dio exception text', () {
    final request = RequestOptions(path: '/media/upload-sessions');
    final failure = ApiFailure.fromDio(
      DioException(requestOptions: request),
      fallbackMessage: 'Network error',
    );

    expect(failure.message, 'Network error');
  });
}
