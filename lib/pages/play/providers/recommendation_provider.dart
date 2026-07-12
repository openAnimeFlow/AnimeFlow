import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/network/api/flow_api.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recommendation_provider.g.dart';

@Riverpod(keepAlive: true, dependencies: [playExtra])
Future<SubjectItem> recommendation(Ref ref) {
  final subjectId = ref.watch(playExtraProvider).playExtra.subjectId;
  return FlowApi.getBangumiRecommendationService(subjectId);
}
