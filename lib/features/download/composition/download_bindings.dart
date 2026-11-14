import 'package:anime_flow/features/download/data/repositories/download_repository.dart';
import 'package:anime_flow/features/download/presentation/providers/download_provider.dart';

final downloadFeatureOverrides = [
  downloadRepositoryProvider.overrideWith((ref) => DownloadRepository()),
];
