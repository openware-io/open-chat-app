import 'package:flutter/foundation.dart' show Brightness;
import 'package:flutter/painting.dart';

/// Shared spacing values used by app screens and reusable UI primitives.
abstract final class GvSpacing {
  static const double xs = 6;
  static const double sm = 8;
  static const double page = 12;
  static const double lg = 16;

  static const double cellV = 10;
  static const double searchBarOuterV = 6;

  /// Horizontal / vertical padding inside text fields.
  static const double fieldH = 12;
  static const double fieldV = 14;
}

/// Shared corner radii. Keep these conservative so controls remain compact.
abstract final class GvRadii {
  static const double compact = 4;
  static const double input = 10;
  static const double button = 12;
  static const double card = 14;
  static const double cardLg = 16;

  static const double dialog = 16;
  static const double dialogLarge = 28;
  static const double dialogAction = 6;
}

/// Shared layout constants for navigation and desktop content widths.
abstract final class GvLayout {
  static const double navbarContent = 50;
  static const double tabbarHeight = 60;
  static const double tabbarPaddingTop = 3;
  static const double tabbarPaddingBottom = 8;

  static const double desktopContentMaxWidth = 600;
}

/// Theme-aware shadows. The app updates these once when brightness changes.
abstract final class GvShadows {
  static List<BoxShadow> card = _cardLight;
  static List<BoxShadow> bar = _barLight;

  static void updateBrightness(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    card = dark ? _cardDark : _cardLight;
    bar = dark ? _barDark : _barLight;
  }

  static const _cardLight = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 4),
  ];
  static const _cardDark = [
    BoxShadow(color: Color(0x28FFFFFF), offset: Offset(0, 1), blurRadius: 4),
  ];

  static const _barLight = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, -2), blurRadius: 6),
  ];
  static const _barDark = [
    BoxShadow(color: Color(0x24FFFFFF), offset: Offset(0, -2), blurRadius: 6),
  ];
}
