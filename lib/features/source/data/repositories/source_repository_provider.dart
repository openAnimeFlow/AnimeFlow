import 'package:anime_flow/features/source/data/repositories/source_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'source_repository_provider.g.dart';

@Riverpod(keepAlive: true)
SourceRepository sourceRepository(Ref ref) => SourceRepository.instance;
