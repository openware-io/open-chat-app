import 'package:flutter/material.dart';

/// Stable gradient pairs for generated avatars.
List<Color> avatarGradientColorsForId(dynamic id) {
  const pairs = <List<Color>>[
    [Color(0xFF5AC8FA), Color(0xFF007AFF)],
    [Color(0xFFFF6482), Color(0xFFFF2D55)],
    [Color(0xFFFFCC00), Color(0xFFFF9500)],
    [Color(0xFF4CD964), Color(0xFF34C759)],
    [Color(0xFFBF5AF2), Color(0xFFAF52DE)],
    [Color(0xFFFF6B6B), Color(0xFFFF3B30)],
    [Color(0xFF64D2FF), Color(0xFF30B0C7)],
    [Color(0xFFFFD426), Color(0xFFFF9F0A)],
  ];
  final num = id is int ? id : int.tryParse('$id') ?? 0;
  return pairs[num.abs() % pairs.length];
}
