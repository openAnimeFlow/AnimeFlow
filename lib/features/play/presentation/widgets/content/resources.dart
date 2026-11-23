import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/domain/play_source_selection.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:material_ui/material_ui.dart';

enum _SourceAction {
  openPageUrl(Icons.open_in_browser_rounded),
  copyPageUrl(Icons.content_copy_rounded);

  const _SourceAction(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
        _SourceAction.openPageUrl => l10n.openPlaybackPage,
        _SourceAction.copyPageUrl => l10n.copySourceLink,
      };
}

typedef _SourceDisplay = ({
  String title,
  Widget icon,
  String detail,
  String? pageUrl,
});

class VideoResourcesView extends StatelessWidget {
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

  _SourceDisplay? _describeSource(AppLocalizations l10n) => switch (source) {
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

  Widget _buildSourceActionMenu(
    BuildContext context,
    AppLocalizations l10n,
    String pageUrl,
  ) {
    final colors = Theme.of(context).colorScheme;
    return JellyMenu<_SourceAction>(
      tooltip: l10n.sourceActions,
      triggerColor: Colors.transparent,
      preferredVerticalDirection: VerticalDirection.down,
      trigger: SizedBox.square(
        dimension: 50,
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colors.onSurface,
          size: 30,
        ),
      ),
      menuBuilder: (context, select) {
        final style = TextButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          foregroundColor: colors.onSurface,
          padding: JellyMenu.itemPadding(context),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final action in _SourceAction.values)
                  TextButton(
                    style: style,
                    onPressed: () => select(action),
                    child: Row(
                      children: [
                        Icon(action.icon, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            action.label(l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      onSelected: (action) {
        switch (action) {
          case _SourceAction.openPageUrl:
            onOpenSourcePage(pageUrl);
          case _SourceAction.copyPageUrl:
            onCopySourcePage(pageUrl);
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
                      else if (isSearchCompleted)
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
                  onPressed: onSwitchSource,
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
                  _buildSourceActionMenu(context, l10n, pageUrl),
              ],
            )
          ],
        ),
      ),
    );
  }
}
