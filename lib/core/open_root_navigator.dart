import 'package:flutter/material.dart';

/// 根 [Navigator]，与 [GoRouter] 共用；扫码跳转等场景在页面已 pop 后仍可用。
final GlobalKey<NavigatorState> gvRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
