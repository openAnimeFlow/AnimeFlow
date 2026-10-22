import 'package:anime_flow/core/network/api/flow_api.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_episode_response.dart';
import 'package:anime_flow/shared/models/player/danmaku/danmaku_search_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final danmakuSearchProvider = FutureProvider.autoDispose
    .family<DanmakuSearchResponse, String>(
        (ref, keyword) => FlowApi.searchDanmakuEpisodes(keyword));

final danmakuEpisodesProvider = FutureProvider.autoDispose
    .family<DanmakuEpisodeResponse, int>(
        (ref, id) => FlowApi.getDanDanEpisodesByDanDanBangumiID(id));
