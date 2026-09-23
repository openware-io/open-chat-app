import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/services/hybrid_bridge_dispatcher.dart';

void main() {
  test('dispatches structured method and params', () async {
    final dispatcher = HybridBridgeDispatcher(
      handlers: {'profile.read': (request) async => request.params['appId']},
    );
    final response = await dispatcher.dispatch(
      jsonEncode({
        'id': '1',
        'method': 'profile.read',
        'params': {'appId': 'saas-a380-c'},
        'nonce': 'n1',
      }),
    );
    expect(response, {'id': '1', 'ok': true, 'result': 'saas-a380-c'});
  });

  test('rejects unknown methods and duplicate nonces', () async {
    final dispatcher = HybridBridgeDispatcher(handlers: {});
    final unknown = await dispatcher.dispatch(
      '{"id":"1","method":"unknown","params":{},"nonce":"n1"}',
    );
    final duplicate = await dispatcher.dispatch(
      '{"id":"2","method":"unknown","params":{},"nonce":"n1"}',
    );
    expect(unknown['error']['code'], 'unknown_method');
    expect(duplicate['error']['code'], 'duplicate_nonce');
  });

  test('returns structured timeout errors', () async {
    final dispatcher = HybridBridgeDispatcher(
      timeout: const Duration(milliseconds: 10),
      handlers: {
        'slow': (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return true;
        },
      },
    );
    final response = await dispatcher.dispatch(
      '{"id":"1","method":"slow","params":{},"nonce":"n1"}',
    );
    expect(response['error']['code'], 'timeout');
  });

  test('preserves a handler structured error code', () async {
    final dispatcher = HybridBridgeDispatcher(
      handlers: {
        'login': (_) async => throw const HybridBridgeException(
              'im_session_expired',
              'IM login session has expired',
            ),
      },
    );
    final response = await dispatcher.dispatch(
      '{"id":"1","method":"login","params":{},"nonce":"n1"}',
    );
    expect(response['error']['code'], 'im_session_expired');
  });
}
