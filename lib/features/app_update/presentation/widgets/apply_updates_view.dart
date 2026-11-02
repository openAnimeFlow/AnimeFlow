import 'dart:math' as math;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:anime_flow/features/app_update/application/app_info_provider.dart';
import 'package:anime_flow/shared/models/download_info.dart';
import 'package:anime_flow/shared/models/version_download_state.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApplyUpdatesView extends StatefulWidget {
  final List<DownloadInfo> download;
  final String body;
  final Future<void> Function(DownloadInfo download) onStartDownload;
  final VoidCallback onCancelDownload;
  final bool supportsDownloadRoutes;

  const ApplyUpdatesView({
    super.key,
    required this.onStartDownload,
    required this.onCancelDownload,
    required this.download,
    required this.body,
    this.supportsDownloadRoutes = true,
  });

  @override
  State<ApplyUpdatesView> createState() => _ApplyUpdatesViewState();
}

class _ApplyUpdatesViewState extends State<ApplyUpdatesView> {
  int _selectedIndex = 0;
  UpdateDownloadRoute _route = UpdateDownloadRoute.github;
  bool _downloadRouteMenuOpen = false;
  bool _startingDownload = false;
  bool _showDownloadRouteHint = false;
  bool _animateDownloadRouteHint = false;
  bool _scrollingToDownloadRoute = false;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToDownloadProgress = false;

  Future<void> _promptDownloadRoute() async {
    setState(() {
      _showDownloadRouteHint = true;
      _scrollingToDownloadRoute = true;
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        setState(() => _animateDownloadRouteHint = true);
      }
    } finally {
      if (mounted) setState(() => _scrollingToDownloadRoute = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(
      builder: (context, ref, _) {
        final download = ref.watch(
          appInfoProvider.select((s) => s.download),
        );
        final isDownloading = download.isDownloading || _startingDownload;
        if (download.isDownloading && !_hasScrolledToDownloadProgress) {
          _hasScrolledToDownloadProgress = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollController.hasClients) return;
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          });
        } else if (!download.isDownloading) {
          _hasScrolledToDownloadProgress = false;
        }
        return AlertDialog(
          title: Text(l10n.updateAvailable),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: widget.body,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                            h1: TextStyle(color: colorScheme.onSurface),
                            h2: TextStyle(color: colorScheme.onSurface),
                            h3: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            h4: TextStyle(color: colorScheme.onSurface),
                            h5: TextStyle(color: colorScheme.onSurface),
                            h6: TextStyle(color: colorScheme.onSurface),
                            listBullet: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                            code: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: colorScheme.onSurfaceVariant,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!isDownloading &&
                            widget.supportsDownloadRoutes &&
                            _showDownloadRouteHint)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: _animateDownloadRouteHint ? 1 : 0,
                              ),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, progress, child) =>
                                  Transform.translate(
                                offset: Offset(
                                  math.sin(progress * math.pi * 6) *
                                      (1 - progress) *
                                      8,
                                  0,
                                ),
                                child: child,
                              ),
                              child: Text(
                                l10n.updateDownloadRouteHint,
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ),
                          ),
                        if (!isDownloading && widget.supportsDownloadRoutes)
                          Wrap(
                            spacing: 16,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(l10n.updateDownloadRoute),
                              DropDownMenu<UpdateDownloadRoute>(
                                items: UpdateDownloadRoute.values,
                                selectedItem: _route,
                                tooltip: l10n.updateDownloadRoute,
                                onOpenedChanged: (isOpen) {
                                  if (mounted) {
                                    setState(
                                        () => _downloadRouteMenuOpen = isOpen);
                                  }
                                },
                                onSelected: (route) =>
                                    setState(() => _route = route),
                                buttonBuilder: (context, route) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_routeLabel(route!),
                                          style: TextStyle(
                                              color: colorScheme.primary)),
                                      AnimatedRotation(
                                        turns: _downloadRouteMenuOpen ? 0.5 : 0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: Icon(Icons.arrow_drop_down,
                                            color: colorScheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context, route, selected) => Row(
                                  children: [
                                    SizedBox(
                                        width: 28,
                                        child: selected
                                            ? Icon(Icons.check,
                                                size: 18,
                                                color: colorScheme.primary)
                                            : null),
                                    Text(_routeLabel(route)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        if (!isDownloading)
                          _DownloadUrlSection(
                            downloadList: widget.download,
                            selectedIndex: _selectedIndex,
                            onSelected: (index) =>
                                setState(() => _selectedIndex = index),
                          ),
                        if (isDownloading)
                          _DownloadProgressSection(download: download),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    AppSettings.setAutoUpdate(false);
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.disableAutoUpdate),
                ),
                Column(
                  children: [
                    TextButton(
                      onPressed: isDownloading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.updateLater),
                    ),
                    if (isDownloading)
                      TextButton(
                        onPressed: widget.onCancelDownload,
                        child: Text(l10n.cancelDownload),
                      )
                    else
                      TextButton(
                        onPressed: () async {
                          if (_startingDownload || _scrollingToDownloadRoute) {
                            return;
                          }
                          if (widget.supportsDownloadRoutes &&
                              !_showDownloadRouteHint) {
                            await _promptDownloadRoute();
                            return;
                          }
                          setState(() => _startingDownload = true);
                          try {
                            await widget.onStartDownload(
                              widget.download[_selectedIndex].withRoute(_route),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _startingDownload = false);
                            }
                          }
                        },
                        child: Text(widget.supportsDownloadRoutes &&
                                _showDownloadRouteHint
                            ? l10n.startUpdateDownload
                            : l10n.updateNow),
                      ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _routeLabel(UpdateDownloadRoute route) => switch (route) {
        UpdateDownloadRoute.ghProxy => 'gh-proxy.org',
        UpdateDownloadRoute.github => 'GitHub',
      };
}

class _DownloadProgressSection extends StatelessWidget {
  const _DownloadProgressSection({required this.download});

  final VersionDownloadState download;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            AppLocalizations.of(context).updateDownloadHint,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).downloading,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '${(download.progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: download.progress,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        if (download.totalBytes > 0)
          Text(
            '${Utils.formatBytes(download.receivedBytes)} / ${Utils.formatBytes(download.totalBytes)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _DownloadUrlSection extends StatelessWidget {
  const _DownloadUrlSection({
    required this.downloadList,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DownloadInfo> downloadList;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (downloadList.length > 1)
          Text(
            AppLocalizations.of(context).selectDownloadSource,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (downloadList.length > 1) const SizedBox(height: 8),
        ...List.generate(downloadList.length, (index) {
          final data = downloadList[index];
          final isSelected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelected(index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  if (downloadList.length > 1) ...[
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.fileName,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          Utils.formatBytes(data.size),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
