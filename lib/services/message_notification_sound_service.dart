import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays the short foreground chime used for newly received chat messages.
class MessageNotificationSoundService {
  final AudioPlayer _player = AudioPlayer();
  DateTime? _lastPlayedAt;
  bool _disposed = false;

  static const _minimumInterval = Duration(milliseconds: 350);

  Future<void> play() async {
    if (_disposed) return;

    final now = DateTime.now();
    final lastPlayedAt = _lastPlayedAt;
    if (lastPlayedAt != null &&
        now.difference(lastPlayedAt) < _minimumInterval) {
      return;
    }
    _lastPlayedAt = now;

    try {
      await _player.stop();
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationCommunicationInstant,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        ),
      );
      await _player.play(
        BytesSource(_messageToneBytes, mimeType: 'audio/wav'),
        volume: 0.46,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'MessageNotificationSoundService.play: $error\n$stackTrace',
      );
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player.dispose();
  }
}

final Uint8List _messageToneBytes = _buildMessageTone();

Uint8List _buildMessageTone() {
  const sampleRate = 16000;
  const firstToneSamples = 1280;
  const silenceSamples = 240;
  const secondToneSamples = 1920;
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
    const attackSamples = 128;
    const releaseSamples = 240;
    for (var index = 0; index < length; index++) {
      final attack = (index / attackSamples).clamp(0.0, 1.0);
      final release = ((length - index - 1) / releaseSamples).clamp(0.0, 1.0);
      final decay = math.exp(-2.8 * index / length);
      final envelope = attack * release * decay;
      final fundamental = math.sin(
        2 * math.pi * frequency * index / sampleRate,
      );
      final overtone = math.sin(
        2 * math.pi * frequency * 2 * index / sampleRate,
      );
      final sample =
          ((fundamental + overtone * 0.06) * envelope * 0.24 * 32767).round();
      wav.setInt16(
        headerSize + (targetOffset + index) * bytesPerSample,
        sample.clamp(-32768, 32767).toInt(),
        Endian.little,
      );
    }
  }

  writeTone(targetOffset: 0, length: firstToneSamples, frequency: 523.25);
  writeTone(
    targetOffset: firstToneSamples + silenceSamples,
    length: secondToneSamples,
    frequency: 659.25,
  );
  return wav.buffer.asUint8List();
}
