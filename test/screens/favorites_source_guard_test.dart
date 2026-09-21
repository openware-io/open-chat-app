import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 收藏功能源码守卫：锁定本次产品决策，避免回归。
///
/// 1. 收藏列表点击进入**收藏详情页**，不得再直接跳原会话；
/// 2. 详情页「查看原消息」必须先调用可用性查询（lookupSource）再决定是否跳转；
/// 3. 聊天室多选工具栏提供「收藏」，并走批量收藏接口（一次请求）。
void main() {
  String read(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: '未找到 $path（测试需在包根目录运行）');
    return file.readAsStringSync();
  }

  test('收藏列表点击不再直接跳原会话，而是进入收藏详情页', () {
    final source = read('lib/screens/favorites_screen.dart');
    expect(source.contains('gvOpenChat('), isFalse,
        reason: '收藏列表不得再直接跳转原会话（gvOpenChat）');
    expect(source.contains('AppRoutes.favoriteDetail'), isTrue,
        reason: '收藏列表点击应进入收藏详情页');
  });

  test('收藏详情页先查可用性再跳转，且只认 AVAILABLE', () {
    final source = read('lib/screens/favorite_detail_screen.dart');
    final lookupAt = source.indexOf('lookupSource(');
    final openAt = source.indexOf('gvOpenChat(');
    expect(lookupAt, greaterThanOrEqualTo(0),
        reason: '详情页「查看原消息」必须调用 lookupSource');
    expect(openAt, greaterThan(lookupAt),
        reason: '跳转必须发生在可用性查询之后');
    expect(source.contains('FavoriteSourceState.available'), isTrue,
        reason: '只有 AVAILABLE 才允许跳转');
    // 查询失败/其它状态的中文说明必须存在。
    expect(source.contains('favoritesSourceLookupUnavailable'), isTrue);
    expect(source.contains('favoritesSourceMessageDeleted'), isTrue);
    expect(source.contains('favoritesSourceConversationUnavailable'), isTrue);
    expect(source.contains('favoritesSourceNoPermission'), isTrue);
  });

  test('聊天室多选工具栏提供「收藏」并走批量收藏', () {
    final source = read('lib/screens/chat_room_screen.dart');
    expect(source.contains('chatActionFavorite'), isTrue,
        reason: '多选工具栏需要「收藏」入口');
    expect(source.contains('addFavorites('), isTrue,
        reason: '多选收藏必须调用批量接口 addFavorites');
    expect(source.contains('_favoriteSelected'), isTrue);
  });
}
