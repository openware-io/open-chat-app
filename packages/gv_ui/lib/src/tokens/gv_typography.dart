import 'package:flutter/cupertino.dart';

/// Global semantic font-size configuration. Adjust these values to tune the
/// app's default typography from one place.
abstract final class GvTypographyScale {
  static const double headline = 32;
  static const double title = 21;
  static const double navTitle = 18;
  static const double body = 16;
  static const double bodySmall = 15;
  static const double caption = 14;
  static const double small = 12;
  static const double tabLabel = 11;

  static const double chatBody = 17;
  static const double chatCaption = 13;
}

abstract final class GvTypography {
  static TextStyle headline(Color color) => TextStyle(
        fontSize: GvTypographyScale.headline,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.4,
        color: color,
      );

  static TextStyle title(Color color) => TextStyle(
        fontSize: GvTypographyScale.title,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle navTitle(Color color) => TextStyle(
        fontSize: GvTypographyScale.navTitle,
        fontWeight: FontWeight.w400,
        height: 1.25,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontSize: GvTypographyScale.body,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color,
      );

  static TextStyle bodySmall(Color color) => TextStyle(
        fontSize: GvTypographyScale.bodySmall,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: GvTypographyScale.caption,
        fontWeight: FontWeight.w400,
        height: 1.3,
        color: color,
      );

  static TextStyle small(Color color) => TextStyle(
        fontSize: GvTypographyScale.small,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: color,
      );

  static TextStyle tabLabel(Color color) => TextStyle(
        fontSize: GvTypographyScale.tabLabel,
        fontWeight: FontWeight.w400,
        height: 1.2,
        color: color,
      );
}
