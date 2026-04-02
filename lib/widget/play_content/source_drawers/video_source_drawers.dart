import 'dart:async';
import 'dart:convert';
import 'package:anime_flow/crawler/itme/anti_crawler_config.dart';
import 'package:anime_flow/models/item/play/video/episode_resources_item.dart';
import 'package:anime_flow/models/item/play/video/resources_item.dart';
import 'package:anime_flow/providers/captcha/captcha_provider.dart';
import 'package:anime_flow/stores/play_subject_state.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/constants/play_layout_constant.dart';
import 'package:anime_flow/stores/episodes_state.dart';
import 'package:anime_flow/controllers/video/source/video_source_controller.dart';
import 'package:anime_flow/controllers/video/video_state_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class VideoSourceDrawers extends ConsumerStatefulWidget {
  final Function(String url)? onVideoUrlSelected;

  final bool isBottomSheet;

  const VideoSourceDrawers({
    super.key,
    this.onVideoUrlSelected,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<VideoSourceDrawers> createState() => _VideoSourceDrawersState();
}

class _VideoSourceDrawersState extends ConsumerState<VideoSourceDrawers> {
  late VideoStateController videoStateController;
  late EpisodesState episodesController;
  late PlaySubjectState subjectState;
  late String keyword;
  final logger = Logger();
  bool isShowEpisodes = false;
  final searchController = TextEditingController();
  final manualSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    subjectState = Get.find<PlaySubjectState>();
    videoStateController = Get.find<VideoStateController>();
    episodesController = Get.find<EpisodesState>();
    final keyword = subjectState.subject.value.name;
    this.keyword = keyword;
    searchController.text = keyword;
    manualSearchController.text = keyword;
  }

  @override
  void dispose() {
    searchController.dispose();
    manualSearchController.dispose();
    super.dispose();
  }

  void setShowEpisodes() {
    setState(() {
      isShowEpisodes = !isShowEpisodes;
    });
  }

  void setSelectedWebsite(int index) {
    ref.read(videoSourceController.notifier).setSelectedWebsiteIndex(index);
    setState(() {
      isShowEpisodes = false;
    });
  }

  void _performSearch() {
    String searchQuery = searchController.text;
    if (searchQuery.isNotEmpty) {
      ref.read(videoSourceController.notifier).setSelectedWebsiteIndex(0);
      setState(() {
        isShowEpisodes = false;
      });
      ref.read(videoSourceController.notifier).initResources(searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBottomSheet) {
      return _buildBottomSheetContent(context);
    }
    return _buildSideDrawerContent(context);
  }

  /// 底部抽屉内容
  Widget _buildBottomSheetContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动指示器
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _manualSearch(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                final dataSource =
                    ref.watch(videoSourceController).videoResources;
                if (dataSource.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildWebsiteSelector(dataSource: dataSource);
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final src = ref.watch(videoSourceController);
                  final dataSource = src.videoResources;
                  if (dataSource.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final currentIndex = src.selectedWebsiteIndex;
                  final validIndex =
                      currentIndex >= dataSource.length ? 0 : currentIndex;

                  if (validIndex != currentIndex) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ref
                            .read(videoSourceController.notifier)
                            .setSelectedWebsiteIndex(validIndex);
                      }
                    });
                  }
                  return _buildVideoSource(dataSource: dataSource);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 侧边抽屉内容
  Widget _buildSideDrawerContent(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: PlayLayoutConstant.playContentWidth,
        height: MediaQuery.of(context).size.height,
        child: Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top, left: 16, right: 16),
          color: Theme.of(context).cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _manualSearch(),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final dataSource =
                      ref.watch(videoSourceController).videoResources;
                  if (dataSource.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _buildWebsiteSelector(dataSource: dataSource);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final src = ref.watch(videoSourceController);
                    final dataSource = src.videoResources;
                    if (dataSource.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final currentIndex = src.selectedWebsiteIndex;
                    final validIndex =
                        currentIndex >= dataSource.length ? 0 : currentIndex;

                    if (validIndex != currentIndex) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ref
                              .read(videoSourceController.notifier)
                              .setSelectedWebsiteIndex(validIndex);
                        }
                      });
                    }
                    return _buildVideoSource(dataSource: dataSource);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 标题行
  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          '数据源',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
            decoration: TextDecoration.none,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _manualSearch() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Text(
            '手动搜索',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
              child: Material(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '手动搜索资源',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              onSubmitted: (value) {
                _performSearch();
              },
            ),
          ))
        ],
      ),
    );
  }

  // 数据源选择器
  Widget _buildWebsiteSelector({required List<ResourcesItem> dataSource}) {
    final selectedIndex =
        ref.watch(videoSourceController.select((s) => s.selectedWebsiteIndex));
    return SizedBox(
        height: 40,
        child: Row(
          children: [
            Icon(
              Icons.public,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.horizontal,
                    itemCount: dataSource.length,
                    itemBuilder: (context, index) {
                      final data = dataSource[index];
                      final isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setSelectedWebsite(index);
                          if (data.episodeResources.isEmpty) {
                            manualSearchController.text = keyword;
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: AnimationNetworkImage(
                                    width: 24,
                                    height: 24,
                                    url: data.websiteIcon),
                              ),
                              if (data.isLoading) ...[
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ] else if (data.needsCaptcha) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                              ] else if (data.errorMessage != null) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.error_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ] else if (data.episodeResources.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    })),
          ],
        ));
  }

  Widget _buildVideoSource({required List<ResourcesItem> dataSource}) {
    final selectedIndex =
        ref.watch(videoSourceController.select((s) => s.selectedWebsiteIndex));
    if (selectedIndex >= dataSource.length) {
      return const SizedBox.shrink();
    }

    final selectedResource = dataSource[selectedIndex];
    final episodeResources = selectedResource.episodeResources;

    if (selectedResource.needsCaptcha) {
      return _buildCaptchaRequired(selectedResource);
    }

    if (episodeResources.isEmpty) {
      return Material(
        child: Center(
          child: Column(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('未找到播放源',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: manualSearchController,
                decoration: const InputDecoration(
                  hintText: '手动搜索资源',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              ElevatedButton(
                  onPressed: () => ref
                      .read(videoSourceController.notifier)
                      .retryResources(selectedResource.websiteName,
                          keyword: manualSearchController.text),
                  child: const Text('重新搜索'))
            ],
          ),
        ),
      );
    }
    return Material(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: episodeResources.length,
        itemBuilder: (context, index) {
          final resourceItem = episodeResources[index];
          final isLastItem = index == episodeResources.length - 1;

          final epIndex = episodesController.episodeIndex.value;
          Episode? currentEpisode;
          for (final ep in resourceItem.episodes) {
            if (ep.episodeSort == epIndex) {
              currentEpisode = ep;
              break;
            }
          }

          final excludedEpisodesCount = episodeResources
              .expand((item) =>
                  item.episodes.where((ep) => ep.episodeSort != epIndex))
              .length;

          if (currentEpisode == null) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              _buildSource(
                currentEpisode,
                resourceItem,
                baseUrl: selectedResource.baseUrl,
                websiteName: selectedResource.websiteName,
                websiteIcon: selectedResource.websiteIcon,
              ),
              if (isLastItem) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '显示已被排除的资源($excludedEpisodesCount)',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isShowEpisodes,
                        onChanged: (value) {
                          setShowEpisodes();
                        },
                      ),
                    ],
                  ),
                ),
                if (isShowEpisodes)
                  ...episodeResources.expand((item) {
                    final excludedEpisodes = item.episodes
                        .where(
                          (ep) => ep.episodeSort != epIndex,
                        )
                        .toList();
                    return excludedEpisodes.map(
                      (excludedEpisode) => _buildSource(
                        excludedEpisode,
                        item,
                        baseUrl: selectedResource.baseUrl,
                        websiteName: selectedResource.websiteName,
                        websiteIcon: selectedResource.websiteIcon,
                      ),
                    );
                  }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCaptchaRequired(ResourcesItem resource) {
    return CaptchaView(
      key: ValueKey(resource.websiteName),
      resource: resource,
      searchKeyword: ref.watch(videoSourceController.select((s) => s.keyword)),
      onRetryResources: (name) => ref
          .read(videoSourceController.notifier)
          .retryResources(name, keyword: subjectState.subject.value.name),
    );
  }

  Widget _buildSource(Episode episode, EpisodeResourcesItem item,
      {required String websiteName,
      required String websiteIcon,
      required String baseUrl}) {
    final pageUrl = ref.watch(videoSourceController.select((s) => s.videoUrl));
    final isSelected = baseUrl + episode.like == pageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                width: 2.5,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
      ),
      child: Card.filled(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
            onTap: () async {
              try {
                Get.back();
                final episodePageUrl = baseUrl + episode.like;
                ref.read(videoSourceController.notifier).setWebSite(
                      title: websiteName,
                      iconUrl: websiteIcon,
                      videoUrl: episodePageUrl,
                      isManual: true,
                    );
                widget.onVideoUrlSelected?.call(episodePageUrl);
              } catch (e) {
                logger.e('获取视频源失败', error: e);
                Get.snackbar(
                  '错误',
                  '获取视频源失败: $e',
                  duration: const Duration(seconds: 3),
                  maxWidth: 300,
                  backgroundColor: Colors.red.shade100,
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            text: item.subjectsTitle,
                            children: [
                              TextSpan(
                                text:
                                    ' 第${episode.episodeSort.toString().padLeft(2, '0')}集',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '线路:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.lineNames,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Icon(Icons.link, size: 20, color: Colors.grey),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            )),
      ),
    );
  }
}

/// 验证ui
class CaptchaView extends StatefulWidget {
  const CaptchaView({
    super.key,
    required this.resource,
    required this.searchKeyword,
    required this.onRetryResources,
  });

  final ResourcesItem resource;
  final String searchKeyword;
  final Future<void> Function(String websiteName) onRetryResources;

  @override
  State<CaptchaView> createState() => _CaptchaViewState();
}

class _CaptchaViewState extends State<CaptchaView> {
  CaptchaProvider? _provider;
  Timer? _verifyTimer;
  StreamSubscription? _imageSub;
  final _codeController = TextEditingController();
  String? _imageData;
  bool _sessionActive = false;
  bool _isSubmitting = false;
  bool _isAutoVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    _disposeSession();
    super.dispose();
  }

  void _disposeSession() {
    _imageSub?.cancel();
    _imageSub = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
    _provider?.dispose();
    _provider = null;
    _sessionActive = false;
    _isSubmitting = false;
    _isAutoVerifying = false;
    _imageData = null;
  }

  String _searchPageUrl() {
    return widget.resource.searchUrl
        .replaceFirst('{keyword}', widget.searchKeyword);
  }

  void _startVerification() {
    final config = widget.resource.antiCrawlerConfig;
    if (config == null) return;

    _disposeSession();
    _provider = CaptchaProvider();
    final name = widget.resource.websiteName;
    final url = _searchPageUrl();

    if (config.captchaType == CaptchaType.autoClickButton) {
      setState(() {
        _sessionActive = true;
        _isAutoVerifying = true;
      });
      _provider!.loadForButtonClick(
        url: url,
        buttonXpath: config.captchaButton,
        pluginName: name,
        onVerified: () => _onVerified(name),
      );
    } else {
      setState(() {
        _sessionActive = true;
        _imageData = null;
        _isSubmitting = false;
      });

      _imageSub = _provider!.onCaptchaImageUrl.listen((imageUrl) {
        if (imageUrl != null && mounted) {
          setState(() {
            _imageData = imageUrl;
            if (_isSubmitting) {
              _isSubmitting = false;
              _codeController.clear();
              _verifyTimer?.cancel();
              _verifyTimer = null;
            }
          });
        }
      });

      _provider!.loadForCaptcha(
        url,
        config.captchaImage,
        inputXpath: config.captchaInput,
      );
    }
  }

  void _onVerified(String websiteName) {
    if (!mounted) return;
    _disposeSession();
    setState(() {});
    Get.snackbar('验证成功', '正在重新检索，请稍候…',
        snackPosition: SnackPosition.BOTTOM, maxWidth: 300);
    Future<void>.delayed(const Duration(seconds: 2), () {
      widget.onRetryResources(websiteName);
    });
  }

  Future<void> _submit() async {
    final config = widget.resource.antiCrawlerConfig;
    if (config == null || _isSubmitting) return;
    if (_codeController.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入验证码',
          snackPosition: SnackPosition.BOTTOM, maxWidth: 300);
      return;
    }
    setState(() => _isSubmitting = true);
    final name = widget.resource.websiteName;

    await _provider?.submitCaptcha(
      captchaCode: _codeController.text.trim(),
      inputXpath: config.captchaInput,
      buttonXpath: config.captchaButton,
      pluginName: name,
      onVerified: () => _onVerified(name),
    );

    if (_sessionActive && mounted) {
      _verifyTimer?.cancel();
      _verifyTimer = Timer(const Duration(seconds: 8), () async {
        if (!_sessionActive || !mounted) return;
        setState(() {
          _isSubmitting = false;
          _codeController.clear();
        });
        Get.snackbar('提示', '验证码可能有误，请重新输入',
            snackPosition: SnackPosition.BOTTOM, maxWidth: 300);
        await _reloadCaptchaImage();
      });
    }
  }

  /// 重新拉取验证码图
  Future<void> _reloadCaptchaImage() async {
    final config = widget.resource.antiCrawlerConfig;
    final p = _provider;
    if (config == null || p == null || !_sessionActive || _isAutoVerifying) {
      return;
    }
    _verifyTimer?.cancel();
    _verifyTimer = null;
    if (!mounted) return;
    setState(() {
      _imageData = null;
      _isSubmitting = false;
    });
    await p.reloadCaptchaImage(config.captchaImage,
        inputXpath: config.captchaInput);
  }

  void _cancel() {
    final name = widget.resource.websiteName;
    final provider = _provider;
    _provider = null;
    _imageSub?.cancel();
    _imageSub = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
    setState(() {
      _sessionActive = false;
      _isSubmitting = false;
      _isAutoVerifying = false;
      _imageData = null;
      _codeController.clear();
    });
    provider?.saveAndUnload(name).then((_) {
      provider.dispose();
      widget.onRetryResources(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;

    if (!_sessionActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text('${r.websiteName} 需要验证码验证',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _startVerification,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: const Text('进行验证'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => widget.onRetryResources(r.websiteName),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重试'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isAutoVerifying) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${r.websiteName} 正在自动完成验证，请稍候',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _cancel,
              child: Text('取消',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline)),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: View.of(context).viewInsets.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 36, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text('${r.websiteName} 验证码验证',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 16),
                if (_imageData == null) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('正在加载验证码图片...'),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: (_isSubmitting || _imageData == null)
                          ? null
                          : () {
                              _codeController.clear();
                              _reloadCaptchaImage();
                            },
                      child: Image.memory(
                        width: double.infinity,
                        base64Decode(_imageData!.split(',').last),
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, _) => const Text('图片解码失败'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    child: TextField(
                      controller: _codeController,
                      autofocus: true,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: '请输入验证码',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: _isSubmitting ? null : (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancel,
                        child: Text('取消',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.outline)),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: (_imageData == null || _isSubmitting)
                            ? null
                            : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('提交'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
