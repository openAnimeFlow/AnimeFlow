import 'dart:ui';

import 'package:anime_flow/shared/widgets/adaptive_app_bar.dart';
import 'package:anime_flow/features/settings/presentation/widgets/settings_page_builder.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/settings/presentation/providers/releases_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/core/network/core/network_exception.dart';
import 'package:anime_flow/shared/models/github_release.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatesPage extends ConsumerStatefulWidget {
  const UpdatesPage({super.key});

  @override
  ConsumerState<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends ConsumerState<UpdatesPage> {
  final ScrollController _scrollController = ScrollController();

  ReleasesState? get _data => ref.read(releasesProvider).asData?.value;

  bool get _hasMore => _data?.hasMore ?? false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    ref.invalidate(releasesProvider);
    try {
      await ref.read(releasesProvider.future);
    } catch (_) {
      // 错误由 Provider 状态显示，保留刷新控件的正常结束行为。
    }
  }

  Future<void> _loadMore() => ref.read(releasesProvider.notifier).loadMore();

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) {
      _loadMore();
    }
  }

  void _ensureScrollableOrLoadMore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scrollController.hasClients ||
          !_hasMore ||
          _data?.loadMoreError != null) {
        return;
      }
      if (_scrollController.position.maxScrollExtent <= 0) {
        _loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = ref.watch(releasesProvider);
    ref.listen(releasesProvider, (_, next) {
      if (next.asData?.value.isLoadingMore == false) {
        _ensureScrollableOrLoadMore();
      }
    });
    return SettingsPageBuilder(
      builder: (context, glassStyle) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: colors.surface,
          extendBodyBehindAppBar: glassStyle,
          appBar: AdaptiveAppBar(
            glassStyle: glassStyle,
            backgroundColor: colors.surface,
            title: Text(l10n.projectUpdates),
          ),
          body: Stack(children: [
            const Positioned.fill(child: _Background()),
            result.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _StatusView(
                title: l10n.updatesErrorTitle,
                message: _errorMessage(error, l10n),
                fallback: l10n.projectUpdatesLoadFailed,
                hint: l10n.updatesErrorHint,
                onRetry: _loadInitial,
              ),
              data: (data) {
                final releases = data.releases;
                final loadMoreError = data.loadMoreError;
                if (releases.isEmpty) {
                  return _StatusView(
                    title: l10n.updatesEmptyTitle,
                    hint: l10n.updatesEmptyHint,
                    onRetry: _loadInitial,
                  );
                }
                return RefreshIndicator(
                  edgeOffset: SettingsPageBuilder.topInsetOf(context),
                  onRefresh: _loadInitial,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16,
                        SettingsPageBuilder.topInsetOf(context) + 24, 16, 32),
                    itemCount: releases.length +
                        1 +
                        (data.isLoadingMore || loadMoreError != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) return const _Hero();
                      final releaseIndex = index - 1;
                      if (releaseIndex == releases.length) {
                        if (loadMoreError != null) {
                          return Center(
                              child: TextButton.icon(
                            onPressed: _loadMore,
                            icon: const Icon(Icons.refresh),
                            label: Text(_errorMessage(loadMoreError, l10n)),
                          ));
                        }
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final release = releases[releaseIndex];
                      return Center(
                          child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (releaseIndex == 1)
                              _HistoryHeading(hasMore: data.hasMore),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReleaseCard(
                                key: ValueKey(
                                    'release-$releaseIndex-${release.tagName}'),
                                release: release,
                                initiallyExpanded: releaseIndex == 0,
                              ),
                            ),
                          ],
                        ),
                      ));
                    },
                  ),
                );
              },
            ),
          ]),
        );
      },
    );
  }

  String _errorMessage(Object? error, AppLocalizations l10n) {
    if (error is NetworkException) {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }
    if (error is AnimeFlowApiException) {
      final message = error.message.trim();
      if (message.isNotEmpty) return message;
    }
    return l10n.projectUpdatesLoadFailed;
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    Widget glow(double size, double opacity) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              scheme.primary.withValues(alpha: opacity),
              scheme.primary.withValues(alpha: 0),
            ]),
          ),
        );
    return IgnorePointer(child: LayoutBuilder(builder: (context, constraints) {
      return Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(right: -100, top: 0, child: glow(330, dark ? .22 : .18)),
        Positioned(
            left: -160,
            top: constraints.maxHeight * .53,
            child: glow(320, dark ? .14 : .12)),
      ]);
    }));
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Center(
        child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
              spacing: 15,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.updatesHeroTitle,
                    style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.bold)),
                Text(l10n.updatesHeroSubtitle,
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 13)),
              ]),
        ),
      ),
    ));
  }
}

class _HistoryHeading extends StatelessWidget {
  const _HistoryHeading({required this.hasMore});

  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
        child: Row(children: [
          Expanded(
              child: Text(l10n.updatesHistory,
                  style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.bold))),
          if (hasMore)
            Text(l10n.updatesScrollHint,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
        ]));
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard(
      {super.key, required this.release, required this.initiallyExpanded});

  final GithubRelease release;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final dark = colors.brightness == Brightness.dark;
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: [
        BoxShadow(
            color: colors.shadow.withValues(alpha: dark ? .12 : .06),
            blurRadius: 24,
            offset: const Offset(0, 8))
      ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color:
                  colors.surfaceContainer.withValues(alpha: dark ? .78 : .70),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: .45)),
            ),
            child: ExpansionTile(
              initiallyExpanded: initiallyExpanded,
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape:
                  const RoundedRectangleBorder(side: BorderSide.none),
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              iconColor: colors.primary,
              collapsedIconColor: colors.onSurfaceVariant,
              title: Row(children: [
                if (initiallyExpanded)
                  Container(
                      width: 4,
                      height: 38,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(2))),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Text(
                                release.name.isNotEmpty
                                    ? release.name
                                    : release.tagName,
                                style: TextStyle(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: initiallyExpanded ? 19 : 15)),
                            if (initiallyExpanded)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(l10n.updatesLatest,
                                      style: TextStyle(
                                          color: colors.onPrimaryContainer,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold))),
                          ]),
                      const SizedBox(height: 5),
                      Text(_formatCreatedAt(release.createdAt),
                          style: TextStyle(
                              color: colors.onSurfaceVariant, fontSize: 12)),
                    ])),
              ]),
              children: [
                Divider(color: colors.outlineVariant, height: 1),
                const SizedBox(height: 20),
                MarkdownBody(
                  data:
                      release.body.isEmpty ? l10n.updatesNoNotes : release.body,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                        color: colors.onSurface, height: 1.5, fontSize: 13),
                    h1: TextStyle(
                        color: colors.onSurface, fontWeight: FontWeight.bold),
                    h2: TextStyle(
                        color: colors.onSurface, fontWeight: FontWeight.bold),
                    h3: TextStyle(
                        color: colors.primary, fontWeight: FontWeight.bold),
                    listBullet: TextStyle(color: colors.onSurface),
                    code: TextStyle(
                        color: colors.onSurfaceVariant,
                        backgroundColor: colors.surfaceContainerHighest),
                    a: TextStyle(color: colors.primary),
                  ),
                  onTapLink: (text, href, title) async {
                    if (href == null) return;
                    final uri = Uri.tryParse(href);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                if (release.htmlUrl.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: colors.outlineVariant, height: 1),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          final uri = Uri.tryParse(release.htmlUrl);
                          if (uri != null) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.open_in_new, size: 17),
                        label: Text(l10n.updatesViewGithub),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCreatedAt(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView(
      {required this.title,
      required this.hint,
      required this.onRetry,
      this.message,
      this.fallback});

  final String title, hint;
  final String? message, fallback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detail = message != null && message != fallback ? message! : hint;
    return Padding(
      padding: EdgeInsets.only(top: SettingsPageBuilder.topInsetOf(context)),
      child: Center(
          child: SingleChildScrollView(
              child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(detail,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context).updatesReload)),
        ]),
      ))),
    );
  }
}
