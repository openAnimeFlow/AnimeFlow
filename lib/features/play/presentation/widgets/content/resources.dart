import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/domain/play_source_selection.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
import 'package:material_ui/material_ui.dart';

enum _SourceAction { openPageUrl, copyPageUrl }

typedef _SourceDisplay = ({
  String title,
  Widget icon,
  String detail,
  String? pageUrl,
});

class VideoResourcesView extends StatefulWidget {
  const VideoResourcesView({
    super.key,
    required this.isSearchCompleted,
    required this.source,
    required this.onSwitchSource,
    required this.onOpenSourcePage,
    required this.onCopySourcePage,
  });

  final bool isSearchCompleted;
  final PlaySourceSelection? source;
  final VoidCallback onSwitchSource;
  final ValueChanged<String> onOpenSourcePage;
  final ValueChanged<String> onCopySourcePage;

  @override
  State<VideoResourcesView> createState() => _VideoResourcesViewState();
}

class _VideoResourcesViewState extends State<VideoResourcesView> {
  bool _isSourceActionMenuOpen = false;

  _SourceDisplay? _describeSource(AppLocalizations l10n) =>
      switch (widget.source) {
        LocalVideoFile(:final name) => (
            title: l10n.localVideoSource,
            icon: const Icon(Icons.video_file_outlined, size: 25),
            detail: name.trim(),
            pageUrl: null,
          ),
        OnlineEpisodeSource(:final selection) => (
            title: selection.websiteName,
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: AnimationNetworkImage(
                height: 25,
                width: 25,
                url: selection.websiteIcon,
              ),
            ),
            detail: [
              if (selection.resourceTitle.trim().isNotEmpty)
                selection.resourceTitle.trim(),
              if (selection.lineName.trim().isNotEmpty)
                l10n.lineLabel(selection.lineName.trim()),
            ].join(' - '),
            pageUrl: selection.videoUrl.trim().isEmpty
                ? null
                : selection.videoUrl.trim(),
          ),
        null => null,
      };

  Widget _buildSourceActionMenu({
    required AppLocalizations l10n,
    required String pageUrl,
  }) {
    return DropDownMenu<_SourceAction>(
      items: _SourceAction.values,
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
            widget.onOpenSourcePage(pageUrl);
          case _SourceAction.copyPageUrl:
            widget.onCopySourcePage(pageUrl);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final display = _describeSource(l10n);
    final resourceDetail = display?.detail ?? '';
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
                      if (display != null)
                        Row(
                          children: [
                            display.icon,
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                display.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (widget.isSearchCompleted)
                        Text(l10n.noPlayableSourceForEpisode)
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
                if (display?.pageUrl case final String pageUrl)
                  _buildSourceActionMenu(
                    l10n: l10n,
                    pageUrl: pageUrl,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
