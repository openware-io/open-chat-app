import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;

/// 桌面端 [MaterialPageRoute] 等：不参与过场，避免 [ThemeData.platform] 强行 iOS 时在 Windows 仍出现 Cupertino 滑入。
class _GvInstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _GvInstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

const _kGvInstantTransition = _GvInstantPageTransitionsBuilder();

/// 覆盖全部 [TargetPlatform]，避免查找漏网。
const PageTransitionsTheme _kGvInstantMaterialPageTransitionsTheme =
    PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: _kGvInstantTransition,
    TargetPlatform.fuchsia: _kGvInstantTransition,
    TargetPlatform.iOS: _kGvInstantTransition,
    TargetPlatform.linux: _kGvInstantTransition,
    TargetPlatform.macOS: _kGvInstantTransition,
    TargetPlatform.windows: _kGvInstantTransition,
  },
);

/// 全局 UI 默认字体：优先 **微软雅黑**（Windows 常见）；无该字体时按 [fontFamilyFallback] 回退。
const String kGvGlobalUIFontFamily = 'Microsoft YaHei';

const List<String> kGvGlobalUIFontFallbacks = [
  'Microsoft YaHei UI',
  'PingFang SC',
  'Noto Sans CJK SC',
];

ThemeData buildAppTheme({
  required Brightness brightness,

  /// Windows/macOS/Linux 下限制弹窗最大宽度（像素）；为 null 时不限制（移动端等）。
  double? desktopDialogMaxWidth,

  /// 桌面为 true 时，[MaterialPageRoute] 等无进出场动画（本应用 [ThemeData.platform] 恒为 iOS，否则桌面仍走 Cupertino 过场）。
  bool useInstantMaterialRouteTransitions = false,
}) {
  final isDark = brightness == Brightness.dark;

  final primary =
      isDark ? AppColors.primary.darkColor : AppColors.primary.color;
  final scaffoldBg =
      isDark ? AppColors.bgPage.darkColor : AppColors.bgPage.color;
  final surface =
      isDark ? AppColors.bgWhite.darkColor : AppColors.bgWhite.color;
  final onSurface =
      isDark ? AppColors.textPrimary.darkColor : AppColors.textPrimary.color;
  final fill = isDark ? AppColors.bgInput.darkColor : AppColors.bgInput.color;
  final divider = isDark ? AppColors.border.darkColor : AppColors.border.color;
  final danger = isDark ? AppColors.danger.darkColor : AppColors.danger.color;

  var theme = ThemeData(
    useMaterial3: false,
    brightness: brightness,
    platform: TargetPlatform.iOS,
    fontFamily: kGvGlobalUIFontFamily,
    fontFamilyFallback: kGvGlobalUIFontFallbacks,
    textTheme: TextTheme(
      displaySmall: GvTypography.headline(onSurface),
      titleLarge: GvTypography.title(onSurface),
      titleMedium: GvTypography.navTitle(onSurface),
      bodyLarge: GvTypography.body(onSurface),
      bodyMedium: GvTypography.bodySmall(onSurface),
      bodySmall: GvTypography.caption(onSurface),
      labelLarge: GvTypography.bodySmall(onSurface),
      labelMedium: GvTypography.caption(onSurface),
      labelSmall: GvTypography.small(onSurface),
    ),
    primaryColor: primary,
    scaffoldBackgroundColor: scaffoldBg,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    dividerColor: divider,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      error: danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: onSurface,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.page,
        vertical: 12,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GvRadii.button),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: danger,
        side: BorderSide(color: danger.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GvRadii.button),
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: primary,
      textColor: onSurface,
    ),
    iconTheme: IconThemeData(color: primary, size: 22),
    dialogTheme: () {
      final base = ThemeData().dialogTheme.copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GvRadii.dialog),
            ),

            /// 底部按钮由 [GvDialogActions.weChatFooter] 通栏绘制，此处不再留白。
            actionsPadding: EdgeInsets.zero,
          );
      if (desktopDialogMaxWidth == null) return base;
      return base.copyWith(
        constraints: BoxConstraints(maxWidth: desktopDialogMaxWidth),
      );
    }(),
  );

  if (useInstantMaterialRouteTransitions) {
    theme = theme.copyWith(
      pageTransitionsTheme: _kGvInstantMaterialPageTransitionsTheme,
    );
  }

  return theme;
}

/// 与 [ThemeData.scaffoldBackgroundColor] 一致（[buildAppTheme] 内由 [AppColors.bgPage] 的 `.color` / `darkColor` 写入）。
///
/// 页面 [Scaffold.backgroundColor] 与主导航 Tab 壳请优先用此，避免 iOS 上 `CupertinoDynamicColor.resolveFrom`、
/// [CupertinoTheme.applyThemeToAll] 与嵌套 [Navigator] 叠色时，Tab 区与二三级页出现肉眼色差。
Color gvPageScaffoldBackground(BuildContext context) {
  return Theme.of(context).scaffoldBackgroundColor;
}
