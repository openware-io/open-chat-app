import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/gv_http_headers.dart';

void main() {
  const bearer = <String, String>{'Authorization': 'Bearer test-token'};

  test('does not attach app auth to the managed media origin', () {
    final headers = gvMediaRequestHeaders(
      'http://192.168.1.3:9000/private/image.jpg?X-Amz-Signature=test',
      bearer,
      managedMediaBase: 'http://192.168.1.3:9000',
    );

    expect(headers, isNull);
  });

  test('keeps app auth for a different origin', () {
    final headers = gvMediaRequestHeaders(
      'http://192.168.1.3:3002/api/v1/avatar/1',
      bearer,
      managedMediaBase: 'http://192.168.1.3:9000',
    );

    expect(headers, bearer);
  });
}
