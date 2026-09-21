import 'dart:async';

import 'hybrid_bridge_contract.dart';

typedef HybridBridgeHandler = Future<dynamic> Function(
  HybridBridgeRequest request,
);

class HybridBridgeException implements Exception {
  const HybridBridgeException(this.code, this.message);

  final String code;
  final String message;
}

class HybridBridgeDispatcher {
  HybridBridgeDispatcher({
    required Map<String, HybridBridgeHandler> handlers,
    this.timeout = const Duration(seconds: 15),
  }) : _handlers = Map.unmodifiable(handlers);

  final Map<String, HybridBridgeHandler> _handlers;
  final Duration timeout;
  final Set<String> _nonces = <String>{};

  Future<Map<String, dynamic>> dispatch(String payload) async {
    late final HybridBridgeRequest request;
    try {
      request = HybridBridgeRequest.fromJson(payload);
    } on FormatException catch (error) {
      return bridgeFailure('', 'invalid_request', error.message);
    } on Object {
      return bridgeFailure('', 'invalid_request', 'invalid bridge payload');
    }
    if (!_nonces.add(request.nonce)) {
      return bridgeFailure(request.id, 'duplicate_nonce', 'nonce already used');
    }
    final handler = _handlers[request.method];
    if (handler == null) {
      return bridgeFailure(
        request.id,
        'unknown_method',
        'method is not registered',
      );
    }
    try {
      final result = await handler(request).timeout(timeout);
      return bridgeSuccess(request, result);
    } on TimeoutException {
      return bridgeFailure(request.id, 'timeout', 'bridge method timed out');
    } on HybridBridgeException catch (error) {
      return bridgeFailure(request.id, error.code, error.message);
    } on Object catch (error) {
      return bridgeFailure(request.id, 'handler_error', error.toString());
    }
  }
}
