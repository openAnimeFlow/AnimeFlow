import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:material_ui/material_ui.dart';

enum _SourceAction { openPageUrl, copyPageUrl }

class VideoResourcesView extends StatefulWidget {
  const VideoResourcesView({
    super.key,
    required this.isSearchCompleted,
    required this.webSiteTitle,
    required this.webSiteIcon,
    required this.resourceTitle,
    required this.lineName,
    required this.onSwitchSource,
    this.onOpenSourcePage,
    this.onCopySourcePage,
  });

  final bool isSearchCompleted;
  final String webSiteTitle;
  final String webSiteIcon;
  final String resourceTitle;
  final String lineName;
  final VoidCallback onSwitchSource;
  final VoidCallback? onOpenSourcePage;
  final VoidCallback? onCopySourcePage;

  @override
  State<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends State<VideoResourcesView> {
  bool _isSourceActionMenuOpen = false;

  Widget _buildSourceActionMenu({
    required AppLocalizations l10n,
  }) {
    final actions = [
      if (widget.onOpenSourcePage != null) _SourceAction.openPageUrl,
      if (widget.onCopySourcePage != null) _SourceAction.copyPageUrl,
    ];
    return DropDownMenu<_SourceAction>(
      items: actions,
      tooltip: l10n.sourceActions,
      buttonBorderRadius: BorderRadius.circular(25),
      disableSelected: false,
      onOpenedChanged: (isOpen) {
        if (!mounted || _isSourceActionMenuOpen == isOpen) {
          return;
        }
        setState(() {
          _isSourceActionMenuOpen = isOpen;
        });
      },
      offset: const Offset(0, 55),
      buttonBuilder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        return SizedBox.square(
          dimension: 50,
          child: Center(
            child: AnimatedRotation(
              turns: _isSourceActionMenuOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.onSurface,
                size: 30,
              ),
            ),
          ),
        );
      },
      itemBuilder: (context, action, _) {
        final (icon, label) = switch (action) {
          _SourceAction.openPageUrl => (
              Icons.open_in_browser_rounded,
              l10n.openPlaybackPage
            ),
          _SourceAction.copyPageUrl => (
              Icons.content_copy_rounded,
              l10n.copySourceLink
            ),
        };
        return SizedBox(
          width: 150,
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
            ],
          ),
        );
      },
      onSelected: (action) {
        switch (action) {
          case _SourceAction.openPageUrl:
            widget.onOpenSourcePage?.call();
          case _SourceAction.copyPageUrl:
            widget.onCopySourcePage?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resourceTitle = widget.resourceTitle.trim();
    final lineName = widget.lineName.trim();
    final displayLineName = lineName.isEmpty ? '' : lineName;
    final resourceDetail = [
      if (resourceTitle.isNotEmpty) resourceTitle,
      if (displayLineName.isNotEmpty) l10n.lineLabel(displayLineName),
    ].join(' - ');
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.videoSource,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (widget.isSearchCompleted ||
                          widget.webSiteTitle.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 5,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: AnimationNetworkImage(
                                    height: 25,
                                    width: 25,
                                    url: widget.webSiteIcon,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    widget.webSiteTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Text(l10n.autoSelectingResource),
                            const SizedBox(width: 5),
                            const SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator(),
                            )
                          ],
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.onSwitchSource,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: Text(l10n.switchSource),
                ),
              ],
            ),
            Row(
              children: [
                if (resourceDetail.isNotEmpty) ...[
                  Expanded(
                    child: Text(
                      resourceDetail,
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (widget.onOpenSourcePage != null ||
                    widget.onCopySourcePage != null)
                  _buildSourceActionMenu(
                    l10n: l10n,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
