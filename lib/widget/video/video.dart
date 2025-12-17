import 'dart:async';

import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/widget/video/controls/index_controls.dart';
import 'package:anime_flow/controllers/video/data/data_source_controller.dart';
import 'package:anime_flow/controllers/video/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoView extends StatefulWidget {
  final SubjectBasicData subjectBasicData;

  const VideoView({super.key, required this.subjectBasicData});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late final player = Player();
  late final controller = VideoController(player);
  late VideoSourceController videoSourceController;
  late VideoUiStateController videoUiStateController;
  late DataSourceController dataSourceController;
  final webviewItemController = Get.find<WebviewItemController>();
  final logger = Logger();

  StreamSubscription<bool>? _initSubscription;
  StreamSubscription<(String, int)>? _videoURLSubscription;

  @override
  void initState() {
    super.initState();
    Get.put(VideoStateController(player));
    videoSourceController = Get.find<VideoSourceController>();
    dataSourceController = Get.find<DataSourceController>();
    videoUiStateController = Get.put(VideoUiStateController(player));

    // 监听通过旧方式设置的videoUrl（保留兼容）
    dataSourceController.videoUrl.listen((url) {
      if (url.isNotEmpty) {
        player.open(Media(url));
      }
    });

    // 初始化 WebView 并监听视频URL解析结果
    _initWebview();
  }

  Future<void> _initWebview() async {
    // 监听视频URL解析结果
    _videoURLSubscription = webviewItemController.onVideoURLParser.listen((result) {
      final (url, offset) = result;
      logger.i('WebView解析到视频URL: $url, 偏移: $offset');
      
      // 播放解析出的视频
      if (url.isNotEmpty) {
        player.open(Media(url));
        // 如果有偏移量，跳转到指定位置
        if (offset > 0) {
          Future.delayed(const Duration(milliseconds: 500), () {
            player.seek(Duration(seconds: offset));
          });
        }
      }
    });

    // 如果webview尚未初始化，则初始化
    if (webviewItemController.webviewController == null) {
      _initSubscription = webviewItemController.onInitialized.listen((initialized) {
        if (initialized) {
          logger.i('WebView初始化完成');
        }
      });
      await webviewItemController.init();
    }
  }

  @override
  void dispose() {
    _initSubscription?.cancel();
    _videoURLSubscription?.cancel();
    Get.delete<VideoUiStateController>();
    Get.delete<VideoStateController>();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Video(
          controller: controller,
          controls: (state) => VideoControlsUiView(
            player,
             subjectBasicData: widget.subjectBasicData,
          ),
        ),
      ],
    );
  }
}
