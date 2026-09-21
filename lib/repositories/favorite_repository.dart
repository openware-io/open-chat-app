import '../models/chat_message.dart';
import '../models/favorite_models.dart';

/// 消息收藏的业务边界：screen → provider/repository → api，不越层、不裸调网络。
abstract interface class FavoriteRepository {
  /// 收藏一条消息；[peerId]/[chatType] 为消息所属会话（用于跳转与后端归一化）。
  Future<void> addFavorite({
    required String msgId,
    required String peerId,
    required String chatType,
  });

  /// 批量收藏同一会话的多条消息：一次请求完成，服务端按消息 id 幂等去重。
  ///
  /// [peerId]/[chatType] 为该会话的会话标识（与单条收藏接口同一套取值）；
  /// [messageIds] 为同一会话内的消息 id 列表。
  Future<FavoriteBatchResult> addFavorites({
    required String peerId,
    required String chatType,
    required List<String> messageIds,
  });

  /// 取消收藏；[msgId] 为服务端消息 id（收藏在服务端按 (user, msgId) 唯一）。
  Future<void> removeFavorite(String msgId);

  /// 分页拉取收藏消息（复用 [ChatMessage.fromJson] 解析）。
  ///
  /// 收藏内容在列表响应里随记录一起返回（原消息缺失或已无权访问时仍返回收藏时保存的内容），
  /// 因此详情页可以直接用列表项渲染，无需再查原消息。
  ///
  /// 占位消息（原消息已撤回/删除、msgType 为空）会解析为 `msgType: recall` 的墓碑。
  Future<List<ChatMessage>> listFavorites({int page = 1, int pageSize = 20});

  /// 查询收藏对应的原消息是否仍可访问（后端 `GET /favorites/{msgId}/source`）。
  ///
  /// 仅在返回 AVAILABLE 时客户端才允许跳转原消息；查询本身失败一律返回
  /// [FavoriteSourceState.lookupUnavailable]（fail closed，绝不盲跳）。
  Future<FavoriteSource> lookupSource(String msgId);
}
