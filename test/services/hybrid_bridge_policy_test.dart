import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/services/hybrid_bridge_policy.dart';

void main() {
  test('resolves only registered HTTPS page origins and paths', () {
    expect(
      HybridBridgePolicy.forPage(
        Uri.parse('https://miniservice.dev.example.com/c/'),
      )?.appId,
      'saas-c',
    );
    expect(
      HybridBridgePolicy.forPage(
        Uri.parse('https://evil.example/c/'),
      ),
      isNull,
    );
    expect(
      HybridBridgePolicy.forPage(
        Uri.parse('http://miniservice.dev.example.com/c/'),
      ),
      isNull,
    );
  });

  test('accepts exact app, scope, and redirect transaction only', () {
    final policy = HybridBridgePolicy.forPage(
      Uri.parse('https://miniservice.dev.example.com/c/'),
    )!;
    expect(
      policy.accepts(
        requestedAppId: 'saas-c',
        scope: 'profile.basic',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com/c/',
        ),
      ),
      isTrue,
    );
    expect(
      policy.accepts(
        requestedAppId: 'saas-b',
        scope: 'profile.basic',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com/c/',
        ),
      ),
      isFalse,
    );
    expect(
      policy.accepts(
        requestedAppId: 'saas-c',
        scope: 'profile.phone',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com/c/',
        ),
      ),
      isFalse,
    );
    expect(
      policy.accepts(
        requestedAppId: 'saas-c',
        scope: 'profile.basic',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com:444/c/',
        ),
      ),
      isFalse,
    );
  });
}
