import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/features/characters/data/repositories/character_repository.dart';
import 'package:anime_flow/shared/models/bangumi/character_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/character_detail_item.dart';
import 'package:anime_flow/shared/models/bangumi/character_subjects_item.dart';
import 'package:anime_flow/features/character_info/presentation/providers/character_info_args_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_info_provider.g.dart';

CancelToken _requestCancelToken(Ref ref) {
  final token = CancelToken();
  ref.onDispose(() => token.cancel());
  return token;
}

@Riverpod(dependencies: [characterInfoArgs])
class CharacterInfoDetail extends _$CharacterInfoDetail {
  @override
  Future<CharacterDetailItem> build() async {
    final characterId =
        ref.watch(characterInfoArgsProvider.select((e) => e.characterId));
    return ref.watch(characterRepositoryProvider.notifier).getDetail(
        characterId,
        cancelToken: _requestCancelToken(ref),
        forceRefresh: !ref.isFirstBuild);
  }
}

@Riverpod(dependencies: [characterInfoArgs])
class CharacterWorks extends _$CharacterWorks {
  @override
  Future<CharacterCastsItem> build() async {
    final characterId =
        ref.watch(characterInfoArgsProvider.select((e) => e.characterId));
    return ref.watch(characterRepositoryProvider.notifier).getWorks(
          characterId,
          limit: 20,
          offset: 0,
          cancelToken: _requestCancelToken(ref),
          forceRefresh: !ref.isFirstBuild,
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
