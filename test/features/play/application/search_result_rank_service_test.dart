import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/play/application/search_result_rank_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 模拟持有不可发送字段的调用方（原来的 `VideoSourceNotifier`）。
///
/// `LiggLogger` 内部的 `Logger` 持有 `Future`，一旦被捕获进 isolate 消息就会
/// 抛 `Illegal argument in isolate message: object is unsendable`。
class _NotifierLikeCaller {
  final LiggLogger logger = LiggLogger();

  Future<RankedCandidates> rank(List<String> names) {
    // 与方法内其它闭包一样捕获 this，使本方法的上下文包含 logger。
    void touchesThis() => logger.d('active');
    touchesThis();

    return SearchResultRankService.rankInIsolate(
      searchTerm: '葬送的芙莉莲',
      aliases: const [],
      names: names,
    );
  }
}

void main() {
  group('SearchResultRankService.rankInIsolate', () {
    test('返回按得分降序的下标，且与名称一一对应', () async {
      final result = await SearchResultRankService.rankInIsolate(
        searchTerm: '葬送的芙莉莲',
        aliases: const [],
        names: ['无关作品', '葬送的芙莉莲 第二季', '葬送的芙莉莲'],
      );

      expect(result.indices, hasLength(3));
      expect(result.indices.toSet(), {0, 1, 2});
      expect(result.matchRatios, hasLength(3));
      // 完全匹配的那条应排在最前。
      expect(result.indices.first, 2);
    });

    test('空候选返回空结果', () async {
      final result = await SearchResultRankService.rankInIsolate(
        searchTerm: '葬送的芙莉莲',
        aliases: const [],
        names: const [],
      );

      expect(result.indices, isEmpty);
      expect(result.matchRatios, isEmpty);
    });

    test('调用方持有不可发送字段时依然可以执行', () async {
      final caller = _NotifierLikeCaller();

      final result = await caller.rank(['葬送的芙莉莲', '别的动画']);

      expect(result.indices.first, 0);
    });
  });
}
