import 'dart:async';
import 'dart:io';

import 'package:anime_flow/models/enums/video_controls_icon_type.dart';
import 'package:anime_flow/webview/webview_controller.dart';
import 'package:anime_flow/webview/webview_item.dart';
import 'package:anime_flow/controllers/video/data/data_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:anime_flow/controllers/video/video_ui_state_controller.dart';
import 'package:anime_flow/widget/video/ui/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoView extends StatefulWidget {

  const VideoView({super.key});

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late final player = Player();
  late final controller = VideoController(player);
  late VideoUiStateController videoUiStateController;
  late DataSourceController dataSourceController;
  final webviewItemController = Get.find<WebviewItemController>();
  final logger = Logger();

  StreamSubscription<bool>? _initSubscription;
  StreamSubscription<(String, int)>? _videoURLSubscription;
  StreamSubscription<bool>? _videoLoadingSubscription;
  StreamSubscription<String>? _logSubscription;

  // 解析状态跟踪
  bool _isParsing = false;
  bool _hasReceivedVideoUrl = false;
  Timer? _parseTimeoutTimer;

  @override
  void initState() {
    super.initState();
    Get.put(VideoStateController(player));
    dataSourceController = Get.find<DataSourceController>();
    videoUiStateController = Get.put(VideoUiStateController(player));
    // 初始化屏幕亮度
    videoUiStateController.initializeBrightness();

    // 初始化 WebView 并监听视频URL解析结果
    _initWebview();
  }

  Future<void> _initWebview() async {
    // 监听视频URL解析结果
    _videoURLSubscription =
        webviewItemController.onVideoURLParser.listen((result) async {
      final (url, offset) = result;
      logger.i('WebView解析到视频URL: $url, 偏移: $offset');

      // 标记已收到视频URL
      _hasReceivedVideoUrl = true;
      _parseTimeoutTimer?.cancel();

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

    // 监听视频加载状态
    _videoLoadingSubscription =
        webviewItemController.onVideoLoading.listen((loading) {
      _isParsing = loading;

      if (loading) {
        // 开始解析，重置状态并启动超时计时器
        _hasReceivedVideoUrl = false;
        _parseTimeoutTimer?.cancel();
        _parseTimeoutTimer = Timer(const Duration(seconds: 16), () {
          // 16秒超时（比WebView内部的15秒稍长，确保能收到日志）
          if (!_hasReceivedVideoUrl && _isParsing) {
            _parsingState(false, failureReason: '解析超时');
          }
        });
      } else {
        // 解析结束，取消超时计时器
        _parseTimeoutTimer?.cancel();

        // 如果解析结束但没有收到视频URL，说明解析失败
        if (!_hasReceivedVideoUrl && _isParsing) {
          _parsingState(false, failureReason: '未获取到有效的视频URL');
        } else {
          // 解析成功
          _parsingState(false);
        }
      }

      // 只在开始解析时调用，结束时的处理在上面已经完成
      if (loading) {
        _parsingState(true);
      }
    });

    // 监听日志消息（检测解析超时）
    _logSubscription = webviewItemController.onLog.listen((logMessage) {
      // 检测解析超时消息
      if (logMessage.contains('解析视频资源超时')) {
        _parsingState(false, failureReason: '解析超时：$logMessage');
      } else if (logMessage.contains('请切换到其他播放列表或视频源')) {
        logger.w('解析失败提示: $logMessage');
      }
    });
    // 如果webview尚未初始化，则初始化
    if (webviewItemController.webviewController == null) {
      _initSubscription =
          webviewItemController.onInitialized.listen((initialized) {
        if (initialized) {
          logger.i('WebView初始化完成');
        }
      });
      await webviewItemController.init();
    }
  }

  //解析状态
  void _parsingState(bool parsing, {String? failureReason}) {
    if (!mounted) return;

    if (parsing) {
      // 开始解析
      videoUiStateController.setParsingTitle('正在解析视频资源...');
      videoUiStateController
          .updateMainAxisAlignmentType(MainAxisAlignment.center);
      videoUiStateController
          .updateIndicatorType(VideoControlsIndicatorType.parsingIndicator);
      videoUiStateController.showIndicator();
    } else if (failureReason != null) {
      // 解析失败
      logger.e('视频解析失败: $failureReason');

      videoUiStateController.setParsingTitle('解析失败：$failureReason');

      // 显示错误提示
      Get.snackbar(
        '解析失败',
        failureReason,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );

      // 延迟隐藏指示器
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        videoUiStateController.hideIndicator();
        videoUiStateController
            .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
        videoUiStateController
            .updateMainAxisAlignmentType(MainAxisAlignment.start);
      });
    } else {
      // 解析成功
      videoUiStateController.setParsingTitle('视频资源解析成功');
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        videoUiStateController.hideIndicator();
        videoUiStateController
            .updateIndicatorType(VideoControlsIndicatorType.noIndicator);
        videoUiStateController
            .updateMainAxisAlignmentType(MainAxisAlignment.start);
      });
    }
  }

  @override
  void dispose() {
    _parseTimeoutTimer?.cancel();
    _initSubscription?.cancel();
    _videoURLSubscription?.cancel();
    _videoLoadingSubscription?.cancel();
    _logSubscription?.cancel();
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
          controls: (state) => const VideoUi(),
        ),
        /// webview_windows 的窗口必须嵌入到 Widget 树中才能被控制
        /// 通过 SizedBox 的 height 为 0 来隐藏它，但保持其在 Widget 树中(Kazumi)
        if (Platform.isWindows || Platform.isLinux)
          const Positioned(
            child: SizedBox(
              height: 0,
              child: WebviewItem(),
            ),
          ),
      ],
    );
  }
}
