import 'package:anime_flow/features/auth/data/models/flow_token.dart';
import 'package:anime_flow/features/auth/data/models/token_item.dart';
import 'package:anime_flow/features/auth/data/repository/bangumi_token.dart';
import 'package:anime_flow/features/auth/data/repository/flow_token_storage.dart';
import 'package:anime_flow/features/auth/data/repository/token_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_providers.g.dart';

@Riverpod(keepAlive: true)
TokenRepository<TokenItem> tokenRepository(Ref ref) => BangumiToken.instance;

@Riverpod(keepAlive: true)
TokenRepository<FlowToken> flowTokenRepository(Ref ref) =>
    FlowTokenStorage.instance;
