import 'package:flutter/widgets.dart';

/// 等待至少一帧布局 + 首帧光栅化完成后再做采集/绑流。
///
/// 用户刚进通话页就立即建连时，若立刻 [getUserMedia] / [setSrcObject]，部分机型上 Texture 未就绪会长期黑屏；
/// 稍等再操作则正常，故在此处同步渲染管线。
Future<void> waitForCallSurfacePipelineReady() async {
  final binding = WidgetsBinding.instance;
  await binding.endOfFrame;
  try {
    await binding.waitUntilFirstFrameRasterized;
  } catch (_) {
    await Future<void>.delayed(const Duration(milliseconds: 48));
  }
  await binding.endOfFrame;
}
