import 'package:anime_flow/http/requests/flow_request.dart';
import 'package:anime_flow/models/item/flow/background_image_item.dart';
import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_background_provider.g.dart';

/// 背景图列表。
@Riverpod(keepAlive: true)
Future<List<BackgroundImageItem>> backgroundImageList(Ref ref) async {
  return FlowRequest.getBackgroundListService();
}

/// 当前用户已选背景图 ID
@Riverpod(keepAlive: true)
int? currentUserBackgroundId(Ref ref) {
  final userAsync = ref.watch(currentUserInfoProvider);
  final user = userAsync.value;
  if (user == null || user.background == null) return null;

  final listAsync = ref.watch(backgroundImageListProvider);
  final list = listAsync.value;
  if (list == null) return null;

  final match = list.where((item) => item.image == user.background);
  return match.isNotEmpty ? match.first.id : null;
}
