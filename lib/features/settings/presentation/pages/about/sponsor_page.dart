import 'package:anime_flow/core/constants/assets_path_constants.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SponsorLinks {
  const SponsorLinks._();

  /// 爱发电
  static const String afdian = 'https://afdian.com/a/liggmax';

  /// 支付宝
  static const String alipay = '';

  /// 微信赞赏
  static const String wechat = '';

  /// GitHub Sponsors
  static const String github = '';
}

/// 赞助方式卡片左侧图标区域的尺寸。
const double _sponsorIconBoxSize = 54;

class _SponsorMethod {
  const _SponsorMethod({
    required this.icon,
    required this.title,
    required this.description,
    required this.url,
    required this.iconBackground,
    required this.iconForeground,
  });

  final Widget icon;

  /// 图标容器背景色，一般使用渠道品牌色。
  final Color iconBackground;

  /// 图标前景色。
  final Color iconForeground;

  final String title;

  final String description;

  final String url;

  bool get hasUrl => url.trim().isNotEmpty;
}

class SponsorPage extends StatelessWidget {
  const SponsorPage({super.key});

  List<_SponsorMethod> _methods(
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return [
      _SponsorMethod(
        icon: const SizedBox(
          width: _sponsorIconBoxSize,
          height: _sponsorIconBoxSize,
          child: Image(
            image: AssetImage(AssetsPathConstants.afdianLogo),
            fit: BoxFit.cover,
          ),
        ),
        iconBackground: const Color(0xFF946CE6),
        iconForeground: Colors.white,
        title: l10n.sponsorAfdian,
        description: l10n.sponsorAfdianDescription,
        url: SponsorLinks.afdian,
      ),
      _SponsorMethod(
        icon: SvgPicture.asset(
          AssetsPathConstants.alipayLogo,
          width: 30,
          height: 30,
        ),
        iconBackground: const Color(0xFF1677FF),
        iconForeground: Colors.white,
        title: l10n.sponsorAlipay,
        description: l10n.sponsorAlipayDescription,
        url: SponsorLinks.alipay,
      ),
      _SponsorMethod(
        icon: SvgPicture.asset(
          AssetsPathConstants.weixinLogo,
          width: 30,
          height: 30,
        ),
        iconBackground: const Color(0xFF07C160),
        iconForeground: Colors.white,
        title: l10n.sponsorWechat,
        description: l10n.sponsorWechatDescription,
        url: SponsorLinks.wechat,
      ),
      _SponsorMethod(
        icon: SvgPicture.asset(
          AssetsPathConstants.gitHubLogo,
          width: 35,
          height: 35,
        ),
        iconBackground: colorScheme.onSurface,
        iconForeground: colorScheme.surface,
        title: l10n.sponsorGithub,
        description: l10n.sponsorGithubDescription,
        url: SponsorLinks.github,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final methods = _methods(l10n, colorScheme);
    final paddingOf = MediaQuery.paddingOf(context);
    final topPadding = paddingOf.top + kToolbarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.sponsor),
        backgroundColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const maxContentWidth = 1500.0;
          const horizontalMargin = 10.0;
          final availableWidth = constraints.maxWidth - horizontalMargin * 2;
          final contentWidth =
              availableWidth.clamp(0.0, maxContentWidth).toDouble();
          final crossAxisCount =
              contentWidth > 600 ? (contentWidth > 900 ? 3 : 2) : 1;
          // 内容居中并限制最大宽度，但滚动条仍贴在窗口右侧。
          final horizontalPadding = horizontalMargin +
              (availableWidth > maxContentWidth
                  ? (availableWidth - maxContentWidth) / 2
                  : 0.0);
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 360,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [0, 0.68, 1],
                      ).createShader(bounds),
                      child: SvgPicture.asset(
                        AssetsPathConstants.ambientWaveBackground,
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          colorScheme.primary.withValues(alpha: 0.42),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        // 顶部 logo 与文案
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                EdgeInsets.only(top: topPadding, bottom: 8),
                            child: Column(
                              children: [
                                Image.asset(
                                  AssetsPathConstants.logo,
                                  height: 180,
                                  width: 180,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      l10n.sponsorHeroTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.favorite,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Text(
                                    l10n.sponsorHeroDescription,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.6,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        // 资金用途
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                            child: _SectionTitle(
                              title: l10n.sponsorReasonsTitle,
                              icon: Icons.lightbulb_outline,
                              colorScheme: colorScheme,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 2),
                            child: _DescriptionCard(
                              description: l10n.sponsorReasonsDescription,
                              colorScheme: colorScheme,
                            ),
                          ),
                        ),

                        // 赞助方式
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 20, 6, 4),
                            child: _SectionTitle(
                              title: l10n.sponsorMethodsTitle,
                              icon: Icons.volunteer_activism_outlined,
                              colorScheme: colorScheme,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              mainAxisExtent: 116,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _SponsorMethodCard(
                                  method: methods[index],
                                  colorScheme: colorScheme,
                                );
                              },
                              childCount: methods.length,
                            ),
                          ),
                        ),

                        // 结语
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(2, 20, 2, 8),
                            child: Card(
                              elevation: 0,
                              color: colorScheme.primaryContainer
                                  .withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  children: [
                                    Text(
                                      l10n.sponsorFooterTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.sponsorFooterDescription,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.6,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 底部间距
                        SliverToBoxAdapter(
                          child: SizedBox(height: 24.0 + paddingOf.bottom),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.colorScheme,
  });

  final String title;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// 用一张卡片描述全部资金用途。
class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({
    required this.description,
    required this.colorScheme,
  });

  final String description;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.7,
              ),
        ),
      ),
    );
  }
}

class _SponsorMethodCard extends StatelessWidget {
  const _SponsorMethodCard({
    required this.method,
    required this.colorScheme,
  });

  final _SponsorMethod method;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasUrl = method.hasUrl;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _onTap(context, l10n),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: _sponsorIconBoxSize,
                height: _sponsorIconBoxSize,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: method.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(
                      color: method.iconForeground,
                      size: 26,
                    ),
                    child: DefaultSvgTheme(
                      theme: SvgTheme(
                        currentColor: method.iconForeground,
                      ),
                      child: method.icon,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            method.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                          ),
                        ),
                        Icon(
                          hasUrl
                              ? Icons.open_in_new
                              : Icons.lock_clock_outlined,
                          size: 18,
                          color: hasUrl
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Future<void> _onTap(BuildContext context, AppLocalizations l10n) async {
    if (!method.hasUrl) {
      NotificationToast.show(l10n.sponsorUnavailable);
      return;
    }
    final uri = Uri.tryParse(method.url.trim());
    if (uri == null) {
      NotificationToast.show(l10n.sponsorUnavailable);
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      NotificationToast.show(
        l10n.deviceUnsupportedWeb,
        title: l10n.unableOpenWeb,
      );
    }
  }
}
