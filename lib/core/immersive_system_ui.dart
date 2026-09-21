import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralizes app-wide system bar behavior.
///
/// The app uses edge-to-edge layout on mobile while keeping system bars visible.
/// Page chrome such as [GvNavBar] and bottom navigation remains responsible for
/// safe-area padding.
final class ImmersiveSystemUi {
  const ImmersiveSystemUi._();

  static Future<void> enable() async {
    if (!_supportsMobileSystemUi) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(styleFor(Brightness.light));
  }

  static SystemUiOverlayStyle styleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }
}

class GvImmersiveSystemUi extends StatelessWidget {
  const GvImmersiveSystemUi({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = ImmersiveSystemUi.styleFor(brightness);
    SystemChrome.setSystemUIOverlayStyle(style);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: child,
    );
  }
}

bool get _supportsMobileSystemUi {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
