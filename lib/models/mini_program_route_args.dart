/// 进入小程序 WebView 页时通过 [GoRouter] `extra` 传入。
class MiniProgramRouteArgs {
  const MiniProgramRouteArgs({
    required this.url,
    required this.title,
    this.introduction = '',
    this.iconUrl = '',
    this.iconHttpHeaders,
    this.miniProgramId = '',
  });

  final String url;
  final String title;
  final String introduction;

  /// 已解析的小程序图标 URL（与列表展示一致）；空则加载态使用占位图标。
  final String iconUrl;

  /// 拉取图标时的请求头（如 Bearer），与 [CachedNetworkImage] 一致。
  final Map<String, String>? iconHttpHeaders;

  /// 后台小程序 ID，用于 `GV_MINA:` 分享码与扫码打开。
  final String miniProgramId;
}
