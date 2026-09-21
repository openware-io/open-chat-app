import 'mini_program_route_args.dart';

/// 最近使用小程序（按 [lastUsedAtMs] 新→旧排序展示）。
class RecentMiniProgramEntry {
  const RecentMiniProgramEntry({
    required this.url,
    required this.title,
    this.introduction = '',
    this.iconUrl = '',
    this.miniProgramId = '',
    required this.lastUsedAtMs,
  });

  final String url;
  final String title;
  final String introduction;
  final String iconUrl;
  final String miniProgramId;
  final int lastUsedAtMs;

  String get dedupeKey =>
      miniProgramId.trim().isNotEmpty ? miniProgramId.trim() : url.trim();

  factory RecentMiniProgramEntry.fromJson(Map<String, dynamic> j) {
    return RecentMiniProgramEntry(
      url: (j['url'] as String?) ?? '',
      title: (j['title'] as String?) ?? '',
      introduction: (j['introduction'] as String?) ?? '',
      iconUrl: (j['iconUrl'] as String?) ?? '',
      miniProgramId: (j['miniProgramId'] as String?) ?? '',
      lastUsedAtMs: (j['lastUsedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'introduction': introduction,
        'iconUrl': iconUrl,
        'miniProgramId': miniProgramId,
        'lastUsedAtMs': lastUsedAtMs,
      };

  MiniProgramRouteArgs toRouteArgs() => MiniProgramRouteArgs(
        url: url,
        title: title,
        introduction: introduction,
        iconUrl: iconUrl,
        miniProgramId: miniProgramId,
      );
}
