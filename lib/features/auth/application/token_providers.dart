import 'package:anime_flow/core/auth/models/flow_token.dart';
import 'package:anime_flow/core/auth/repository/flow_token_storage.dart';
import 'package:anime_flow/core/auth/repository/token_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_providers.g.dart';

@Riverpod(keepAlive: true)
TokenRepository<FlowToken> flowTokenRepository(Ref ref) =>
    FlowTokenStorage.instance;
