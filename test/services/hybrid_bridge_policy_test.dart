import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/services/hybrid_bridge_policy.dart';

void main() {
  test('resolves only registered HTTPS page origins and paths', () {
    expect(
      HybridBridgePolicy.forPage(
        Uri.parse('https://miniservice.dev.example.com/a380/'),
      )?.appId,
      'saas-a380-c',
    );
    expect(
      HybridBridgePolicy.forPage(
        Uri.parse('https://evil.example/a380/'),
      ),
      isNull,
    );
    expect(
      HybridBridgePolicy.forPage(
        Uri.parse('http://miniservice.dev.example.com/a380/'),
      ),
      isNull,
    );
  });

  test('accepts exact app, scope, and redirect transaction only', () {
    final policy = HybridBridgePolicy.forPage(
      Uri.parse('https://miniservice.dev.example.com/a380/'),
    )!;
    expect(
      policy.accepts(
        requestedAppId: 'saas-a380-c',
        scope: 'profile.basic',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com/a380/',
        ),
      ),
      isTrue,
    );
    expect(
      policy.accepts(
        requestedAppId: 'saas-a380-h5',
        scope: 'profile.basic',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com/a380/',
        ),
      ),
      isFalse,
    );
    expect(
      policy.accepts(
        requestedAppId: 'saas-a380-c',
        scope: 'profile.phone',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com/a380/',
        ),
      ),
      isFalse,
    );
    expect(
      policy.accepts(
        requestedAppId: 'saas-a380-c',
        scope: 'profile.basic',
        redirectUri: Uri.parse(
          'https://miniservice.dev.example.com:444/a380/',
        ),
      ),
      isFalse,
    );
  });
}
