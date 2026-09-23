import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Short, deterministic feedback for a QR code that the app cannot handle.
///
/// The tone is generated in memory so every platform gets the same concise
/// error sound without adding another binary asset to the application.
class GvScanErrorFeedback {
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;

  Future<void> play() async {
    if (_disposed) return;
    unawaited(HapticFeedback.vibrate());
    try {
      await _player.stop();
      await _player.play(
        BytesSource(_errorToneBytes, mimeType: 'audio/wav'),
        volume: 0.8,
      );
    } catch (error, stackTrace) {
      debugPrint('GvScanErrorFeedback.play: $error\n$stackTrace');
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player.dispose();
  }
}

final Uint8List _errorToneBytes = _buildErrorTone();

Uint8List _buildErrorTone() {
  const sampleRate = 16000;
  const firstToneSamples = 1040;
  const silenceSamples = 160;
  const secondToneSamples = 1200;
  const sampleCount = firstToneSamples + silenceSamples + secondToneSamples;
  const headerSize = 44;
  const bytesPerSample = 2;
  const dataSize = sampleCount * bytesPerSample;
  final wav = ByteData(headerSize + dataSize);

  wav.setUint32(0, 0x52494646, Endian.big); // RIFF
  wav.setUint32(4, headerSize + dataSize - 8, Endian.little);
  wav.setUint32(8, 0x57415645, Endian.big); // WAVE
  wav.setUint32(12, 0x666d7420, Endian.big); // fmt
  wav.setUint32(16, 16, Endian.little);
  wav.setUint16(20, 1, Endian.little); // PCM
  wav.setUint16(22, 1, Endian.little); // mono
  wav.setUint32(24, sampleRate, Endian.little);
  wav.setUint32(28, sampleRate * bytesPerSample, Endian.little);
  wav.setUint16(32, bytesPerSample, Endian.little);
  wav.setUint16(34, 16, Endian.little);
  wav.setUint32(36, 0x64617461, Endian.big); // data
  wav.setUint32(40, dataSize, Endian.little);

  void writeTone({
    required int targetOffset,
    required int length,
    required double frequency,
  }) {
    const fadeSamples = 96;
    for (var index = 0; index < length; index++) {
      final fadeIn = (index / fadeSamples).clamp(0.0, 1.0);
      final fadeOut = ((length - index - 1) / fadeSamples).clamp(0.0, 1.0);
      final envelope = math.min(fadeIn, fadeOut);
      final wave = math.sin(2 * math.pi * frequency * index / sampleRate);
      final sample = (wave * envelope * 0.42 * 32767).round();
      wav.setInt16(
        headerSize + (targetOffset + index) * bytesPerSample,
        sample,
        Endian.little,
      );
    }
  }

  writeTone(targetOffset: 0, length: firstToneSamples, frequency: 760);
  writeTone(
    targetOffset: firstToneSamples + silenceSamples,
    length: secondToneSamples,
    frequency: 480,
  );
  return wav.buffer.asUint8List();
}
