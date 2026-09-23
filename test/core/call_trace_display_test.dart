import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/call_trace_display.dart';
import 'package:open_chat_app/l10n/app_localizations_zh.dart';

void main() {
  final l10n = AppLocalizationsZh();

  test('formats a completed voice call using the call duration', () {
    final display = parseCallTraceDisplay(
      l10n,
      '{"v":1,"media":"audio","kind":"completed","durationSec":451}',
    );

    expect(display.isVideo, isFalse);
    expect(display.line, '通话时长 07:31');
  });

  test('recognizes video cancellation payloads', () {
    final display = parseCallTraceDisplay(
      l10n,
      '{"v":1,"media":"video","kind":"cancelled","durationSec":0}',
    );

    expect(display.isVideo, isTrue);
    expect(display.line, '视频通话 已取消');
  });

  test('accepts backend snake case call fields', () {
    final display = parseCallTraceDisplay(
      l10n,
      '{"media_type":"audio","end_reason":"completed","duration_sec":65}',
    );

    expect(display.line, '通话时长 01:05');
  });
}
