import 'package:anime_flow/models/item/bangumi/episodes_item.dart';

/// 播放页剧集分页：合并页数据并判断是否还有更多。
class EpisodesPagination {
  EpisodesPagination._();

  static const int pageSize = 100;

  static EpisodesItem mergePages({
    required EpisodesItem cached,
    required EpisodesItem page,
  }) {
    return EpisodesItem(
      data: [...cached.data, ...page.data],
      total: page.total,
    );
  }

  static bool hasMore(EpisodesItem item) {
    return item.data.length < item.total;
  }
}
