import 'package:anime_flow/features/user/data/repository/user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository_provider.g.dart';

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) => UserRepository.instance;
