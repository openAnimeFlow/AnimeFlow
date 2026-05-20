import 'package:anime_flow/constants/assets_path_constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ThanksPage extends StatelessWidget {
  const ThanksPage({super.key});

  // 鸣谢项目数据
  List<Map<String, dynamic>> get _thanksItems => [
    {
      'icon': const Icon(Icons.web),
      'title': 'WebView',
      'description': 'Kazumi项目提供的WebView技术支持',
      'url': 'https://github.com/Predidit/Kazumi/tree/main/lib/webview',
    },
    {
      'icon': const Icon(Icons.play_circle_outline_rounded),
      'title': 'media-kit',
      'description': '跨平台视频播放器，支持高质量视频播放',
      'url': 'https://github.com/media-kit/media-kit',
    },
    {
      'icon': const Icon(Icons.subtitles),
      'title': 'canvas_danmaku',
      'description': '弹幕插件，提供流畅的弹幕绘制',
      'url': 'https://pub.dev/packages/canvas_danmaku',
    },
    {
      'icon': const Icon(Icons.subtitles_outlined),
      'title': '弹弹Play',
      'description': '提供丰富的弹幕数据源',
      'url': 'https://www.dandanplay.com/',
    },
    {
      'icon': const Icon(Icons.live_tv_rounded),
      'title': 'Bangumi',
      'description': '提供番剧信息和用户数据同步服务',
      'url': 'https://bangumi.tv',
    },
    {
      'icon': const Icon(Icons.hd_outlined),
      'title': 'Anime4K',
      'description': '超分辨率技术，提升视频画质',
      'url': 'https://github.com/bloc97/Anime4K',
    },
    {
      'icon': const Icon(Icons.image_search_outlined),
      'title': 'trace.moe',
      'description': '提供的以图识别番功能',
      'url': 'https://trace.moe/',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('鸣谢'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600
              ? (constraints.maxWidth > 900 ? 3 : 2)
              : 1;
          final viewPadding = MediaQuery.of(context).viewPadding.left;
          return CustomScrollView(
            slivers: [
              // 顶部 logo 和标题
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Image.asset(
                        AssetsPathConstants.logo,
                        height: 200,
                        width: 200,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '特别鸣谢',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Icon(Icons.code_rounded)
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '感谢以下优秀的开源项目和技术支持，让 AnimeFlow 变得更好',
                          style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 鸣谢项目 Grid
              SliverPadding(
                padding: EdgeInsets.only(
                    left: viewPadding > 0 ? viewPadding : 10, right: 10),
                sliver: SliverGrid(
                  // 设置内边距
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    mainAxisExtent: 110,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = _thanksItems[index];
                      return _buildThanksCard(
                        context: context,
                        icon: item['icon'] as Widget,
                        title: item['title'] as String,
                        description: item['description'] as String,
                        url: item['url'] as String?,
                      );
                    },
                    childCount: _thanksItems.length,
                  ),
                ),
              ),

              // 底部间距
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThanksCard({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String description,
    String? url,
  }) {
    final hasUrl = url != null;
    final urlString = url;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: hasUrl
            ? () async {
          final uri = Uri.parse(urlString!);
          final messenger = ScaffoldMessenger.of(context);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('无法打开网页，你的设备可能不支持此功能'),
              ),
            );
          }
        }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: icon,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (hasUrl)
                          Icon(
                            Icons.open_in_new,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
