import 'dart:convert';

import '../l10n/app_localizations.dart';

String formatCallTraceDurationMmSs(int seconds) {
  if (seconds < 0) seconds = 0;
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class CallTraceDisplay {
  const CallTraceDisplay({required this.isVideo, required this.line});

  final bool isVideo;
  final String line;
}

/// 会话列表预览 / 气泡正文：解析 `call` 消息 JSON。
CallTraceDisplay parseCallTraceDisplay(
  AppLocalizations l10n,
  String? content,
) {
  if (content == null || content.isEmpty) {
    return CallTraceDisplay(isVideo: false, line: l10n.callTraceFallback);
  }
  try {
    final raw = jsonDecode(content);
    if (raw is! Map) {
      return CallTraceDisplay(isVideo: false, line: l10n.callTraceFallback);
    }
    final m = Map<String, dynamic>.from(raw);
    final media =
        (m['media'] ?? m['mediaType'] ?? m['media_type'])?.toString() ??
            'audio';
    final kind = (m['kind'] ?? m['endReason'] ?? m['end_reason'])?.toString() ??
        'completed';
    final durationRaw = m['durationSec'] ?? m['duration_sec'];
    final durationSec = durationRaw is num
        ? durationRaw.toInt()
        : int.tryParse(durationRaw?.toString() ?? '') ?? 0;
    final isVideo = media == 'video';
    final dur = formatCallTraceDurationMmSs(durationSec);
    late final String line;
    switch (kind) {
      case 'completed':
        line = isVideo
            ? l10n.callTraceVideoCompleted(dur)
            : l10n.callTraceAudioCompleted(dur);
        break;
      case 'cancelled':
        line = isVideo
            ? l10n.callTraceVideoCancelled
            : l10n.callTraceAudioCancelled;
        break;
      case 'rejected':
        line =
            isVideo ? l10n.callTraceVideoRejected : l10n.callTraceAudioRejected;
        break;
      case 'busy':
        line = isVideo ? l10n.callTraceVideoBusy : l10n.callTraceAudioBusy;
        break;
      case 'failed':
        line = isVideo ? l10n.callTraceVideoFailed : l10n.callTraceAudioFailed;
        break;
      case 'resolved':
        line = l10n.callTraceResolvedOtherDevice;
        break;
      default:
        line = l10n.callTraceFallback;
    }
    return CallTraceDisplay(isVideo: isVideo, line: line);
  } catch (_) {
    return CallTraceDisplay(isVideo: false, line: l10n.callTraceFallback);
  }
}

String formatCallTraceLine(AppLocalizations l10n, String? content) =>
    parseCallTraceDisplay(l10n, content).line;
