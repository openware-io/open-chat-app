import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/screens/services_screen.dart';

void main() {
  group('resolveServiceEntryUrl', () {
    test('resolves an absolute SaaS path against the API origin', () {
      expect(
        resolveServiceEntryUrl(
          '/a380/#/service/hotel',
          'http://192.168.3.35:30080',
        ),
        'http://192.168.3.35:30080/a380/#/service/hotel',
      );
    });

    test('keeps absolute http links and custom schemes unchanged', () {
      expect(
        resolveServiceEntryUrl(
          'https://miniservice.example.com/a380/',
          'http://192.168.3.35:30080',
        ),
        'https://miniservice.example.com/a380/',
      );
      expect(
        resolveServiceEntryUrl(
          'app://business/ktv',
          'http://192.168.3.35:30080',
        ),
        'app://business/ktv',
      );
    });

    test('returns empty for an empty entry', () {
      expect(resolveServiceEntryUrl('  ', 'http://host:30080'), '');
    });
  });
}
