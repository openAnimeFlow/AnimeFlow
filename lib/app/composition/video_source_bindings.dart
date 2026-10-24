import 'dart:async';

import 'package:anime_flow/core/video_source/application/video_source_providers.dart';
import 'package:anime_flow/core/video_source/infrastructure/webview_video_source_service.dart';
import 'package:anime_flow/core/webview/video/video_webview_controller_factory.dart';

WebViewVideoSourceService _createResolver() => WebViewVideoSourceService(
    controllerFactory: VideoWebviewControllerFactory.getController);

// One resolver per app container survives navigation between playback pages.
// Download workers each receive a separate resolver and native controller.
final videoSourceOverrides = [
  playbackVideoSourceProvider.overrideWith((ref) {
    final resolver = _createResolver();
    ref.onDispose(() => unawaited(resolver.dispose()));
    return resolver;
  }),
  videoSourceProviderFactoryProvider.overrideWithValue(_createResolver),
];
