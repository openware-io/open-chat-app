import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:go_router/go_router.dart';

/// 路由进出场动画时长（非 iOS 真机：自定义过渡用）。
const Duration kGvPageTransitionDuration = Duration(milliseconds: 500);

/// 应用内统一路由页。
///
/// **iOS 真机**默认使用 [CupertinoPage]，与系统一致并带**左缘侧滑返回**。
/// [CustomTransitionPage] 仅能做视觉过渡，不会挂上 [CupertinoPageRoute] 的手势。
///
/// 将 [iosInteractivePopGesture] 设为 `false` 时，iOS 也走
/// [CustomTransitionPage]，从路由层去掉边缘交互式返回，仍保留相同转场动画；
/// 返回逻辑由页面内 [PopScope] 等自行处理。
Page<void> gvTransitionPage(
  GoRouterState state,
  Widget child, {
  bool fullscreenDialog = false,
  bool iosInteractivePopGesture = true,
}) {
  final routeArgs = <String, String>{
    ...state.pathParameters,
    ...state.uri.queryParameters,
  };

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      iosInteractivePopGesture) {
    return CupertinoPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      arguments: routeArgs,
      restorationId: state.pageKey.value,
      fullscreenDialog: fullscreenDialog,
      child: child,
    );
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: routeArgs,
    restorationId: state.pageKey.value,
    transitionDuration: kGvPageTransitionDuration,
    reverseTransitionDuration: kGvPageTransitionDuration,
    fullscreenDialog: fullscreenDialog,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: false,
        child: child,
      );
    },
    child: child,
  );
}

/// 无进出场动画（用于通话页等需立即显示、避免与 WebRTC/采集抢首帧的场景）。
Page<void> gvNoTransitionPage(
  GoRouterState state,
  Widget child, {
  bool fullscreenDialog = false,
}) {
  final routeArgs = <String, String>{
    ...state.pathParameters,
    ...state.uri.queryParameters,
  };
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name ?? state.path,
    arguments: routeArgs,
    restorationId: state.pageKey.value,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
    child: child,
  );
}
