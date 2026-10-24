import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/video_source.dart';

final playbackVideoSourceProvider = Provider<IVideoSourceProvider>((ref) =>
    throw StateError(
        'Playback video resolver must be supplied by app composition'));

final videoSourceProviderFactoryProvider = Provider<VideoSourceProviderFactory>(
    (ref) => throw StateError(
        'Video resolver factory must be supplied by app composition'));
