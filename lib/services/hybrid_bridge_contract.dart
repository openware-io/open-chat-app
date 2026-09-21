import 'dart:convert';

class HybridBridgeRequest {
  const HybridBridgeRequest({
    required this.id,
    required this.method,
    required this.params,
    required this.nonce,
  });

  final String id;
  final String method;
  final Map<String, dynamic> params;
  final String nonce;

  factory HybridBridgeRequest.fromJson(String payload) {
    final value = jsonDecode(payload);
    if (value is! Map) throw const FormatException('invalid bridge payload');
    final id = value['id']?.toString() ?? '';
    final method = value['method']?.toString() ?? '';
    final nonce = value['nonce']?.toString() ?? '';
    final paramsValue = value['params'];
    if (id.isEmpty || method.isEmpty || nonce.isEmpty || paramsValue is! Map) {
      throw const FormatException('invalid bridge request');
    }
    return HybridBridgeRequest(
      id: id,
      method: method,
      params: Map<String, dynamic>.from(paramsValue),
      nonce: nonce,
    );
  }
}

Map<String, dynamic> bridgeSuccess(
        HybridBridgeRequest request, dynamic result) =>
    {
      'id': request.id,
      'ok': true,
      'result': result,
    };

Map<String, dynamic> bridgeFailure(
  String id,
  String code,
  String message,
) =>
    {
      'id': id,
      'ok': false,
      'error': {'code': code, 'message': message},
    };
