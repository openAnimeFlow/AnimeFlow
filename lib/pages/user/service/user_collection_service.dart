import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/bangumi/user_collections_item.dart';

/// 用户收藏列表业务：分页拉取与合并。
class UserCollectionService {
  static const pageSize = 20;

  Future<UserCollectionsItem> fetchPage({
    required int type,
    required int offset,
  }) {
    return FlowRequest.myCollectionsService(
      type: type,
      limit: pageSize,
      offset: offset,
    );
  }

  UserCollectionsItem mergeLoadMore({
    required UserCollectionsItem cached,
    required UserCollectionsItem page,
  }) {
    return UserCollectionsItem(
      data: [...cached.data, ...page.data],
      total: page.total,
    );
  }

  bool hasMoreAfterFetch({
    required UserCollectionsItem page,
    required int loadedCount,
  }) {
    return page.data.length == pageSize && loadedCount < page.total;
  }
}
