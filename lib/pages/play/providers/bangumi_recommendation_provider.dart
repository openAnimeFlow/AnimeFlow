import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/network/api/flow_api.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bangumi_recommendation_provider.g.dart';

@Riverpod(dependencies: [playExtra])
Future<SubjectItem> bangumiRecommendation(Ref ref) {
  final subjectId = ref.watch(playExtraProvider).playExtra.subjectId;
  return FlowApi.getBangumiRecommendationService(subjectId);
}
