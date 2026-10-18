import 'dart:convert';

import 'package:anime_flow/core/cache/json_response_cache.dart';
import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/core/settings/storage.dart';
import 'package:anime_flow/shared/models/bangumi/actor_item.dart';
import 'package:anime_flow/shared/models/bangumi/character_detail_item.dart';
import 'package:anime_flow/shared/models/bangumi/character_subjects_item.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_repository.g.dart';

/// 角色公开资料
@Riverpod(keepAlive: true)
class CharacterRepository extends _$CharacterRepository {
  @override
  void build() {}

  Future<CharactersItem> getCharacters(
    int subjectId, {
    required int limit,
    required int offset,
    int? type,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) =>
      JsonResponseCache.get(
        Storage.characterDataCache,
        jsonEncode(['subjectCharacters', subjectId, limit, offset, type]),
        load: () => FlowApi.charactersService(subjectId,
            limit: limit, offset: offset, type: type, cancelToken: cancelToken),
        fromJson: CharactersItem.fromJson,
        toJson: (item) => item.toJson(),
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

  Future<CharacterDetailItem> getDetail(
    int characterId, {
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) =>
      JsonResponseCache.get(
        Storage.characterDataCache,
        jsonEncode(['detail', characterId]),
        load: () =>
            FlowApi.characterInfoService(characterId, cancelToken: cancelToken),
        fromJson: CharacterDetailItem.fromJson,
        toJson: (item) => item.toJson(),
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );

  Future<CharacterCastsItem> getWorks(
    int characterId, {
    required int limit,
    required int offset,
    int subjectType = 2,
    CancelToken? cancelToken,
    bool forceRefresh = false,
  }) =>
      JsonResponseCache.get(
        Storage.characterDataCache,
        jsonEncode(['works', characterId, limit, offset, subjectType]),
        load: () => FlowApi.characterWorksService(characterId,
            limit: limit,
            offset: offset,
            subjectType: subjectType,
            cancelToken: cancelToken),
        fromJson: CharacterCastsItem.fromJson,
        toJson: (item) => item.toJson(),
        cancelToken: cancelToken,
        forceRefresh: forceRefresh,
      );
}
