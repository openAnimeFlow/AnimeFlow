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
    final data = result.asData?.value;
    final releases = data?.releases ?? const <GithubRelease>[];
    final isLoading = result.isLoading;
    final error = result.error;
    final isLoadingMore = data?.isLoadingMore ?? false;
    final loadMoreError = data?.loadMoreError;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.projectUpdates)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorView(
                  message: _errorMessage(error, l10n),
                  onRetry: _loadInitial,
                )
              : releases.isEmpty
                  ? _ErrorView(
                      message: l10n.noData,
                      onRetry: _loadInitial,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInitial,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: releases.length +
                            (isLoadingMore || loadMoreError != null ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 5),
                        itemBuilder: (context, index) {
                          if (index == releases.length) {
                            if (loadMoreError != null) {
                              return Center(
                                child: TextButton.icon(
                                  onPressed: _loadMore,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    _errorMessage(loadMoreError, l10n),
                                  ),
                                ),
                              );
                            }
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return _ReleaseCard(
                            release: releases[index],
                            initiallyExpanded: index == 0,
                          );
                        },
                      ),
                    ),
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

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.release,
    required this.initiallyExpanded,
  });

  final GithubRelease release;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide.none,
        ),
        initiallyExpanded: initiallyExpanded,
        title: Text(
          release.name.isNotEmpty ? release.name : release.tagName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatCreatedAt(release.createdAt)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          MarkdownBody(
            data: release.body.isEmpty ? '暂无更新说明' : release.body,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: colorScheme.onSurface, height: 1.45),
              h1: TextStyle(color: colorScheme.onSurface),
              h2: TextStyle(color: colorScheme.onSurface),
              h3: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              listBullet: TextStyle(color: colorScheme.onSurface),
              code: TextStyle(
                color: colorScheme.onSurfaceVariant,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            onTapLink: (text, href, title) async {
              if (href == null) return;
              final uri = Uri.tryParse(href);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          if (release.htmlUrl.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(release.htmlUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('GitHub'),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCreatedAt(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
