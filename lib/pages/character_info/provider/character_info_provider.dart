import 'package:anime_flow/network/api/flow_api.dart';
import 'package:anime_flow/models/item/bangumi/character_comments_item.dart';
import 'package:anime_flow/models/item/bangumi/character_detail_item.dart';
import 'package:anime_flow/models/item/bangumi/character_subjects_item.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_info_provider.g.dart';

@Riverpod(dependencies: [characterInfoArgs])
class CharacterInfoDetail extends _$CharacterInfoDetail {
  @override
  Future<CharacterDetailItem> build() async {
    final characterId =
        ref.watch(characterInfoArgsProvider.select((e) => e.characterId));
    return FlowApi.characterInfoService(characterId);
  }
}

@Riverpod(dependencies: [characterInfoArgs])
class CharacterWorks extends _$CharacterWorks {
  @override
  Future<CharacterCastsItem> build() async {
    final characterId =
        ref.watch(characterInfoArgsProvider.select((e) => e.characterId));
    return FlowApi.characterWorksService(
      characterId,
      limit: 20,
      offset: 0,
    );
  }
}

@Riverpod(dependencies: [characterInfoArgs])
class CharacterComments extends _$CharacterComments {
  @override
  Future<List<CharacterCommentItem>> build() async {
    final characterId =
        ref.watch(characterInfoArgsProvider.select((e) => e.characterId));
    return FlowApi.characterCommentsService(characterId);
  }
}
