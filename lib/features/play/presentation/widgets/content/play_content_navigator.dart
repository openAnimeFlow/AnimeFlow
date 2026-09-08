import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/anime_info_view.dart';
import 'package:anime_flow/features/play/presentation/providers/play_content_actions.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/introduce_view.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns only the introduction/detail stack; links to other subjects and
/// characters remain application routes above the player.
class PlayContentNavigator extends ConsumerStatefulWidget {
  const PlayContentNavigator({super.key, required this.isActive});
  final bool isActive;

  @override
  ConsumerState<PlayContentNavigator> createState() =>
      _PlayContentNavigatorState();
}

class _PlayContentNavigatorState extends ConsumerState<PlayContentNavigator>
    with AutomaticKeepAliveClientMixin {
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _showDetails = false;
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _play(Future<void> Function(PlayContentActions) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(ref.read(playContentActionsProvider));
      if (mounted) setState(() => _showDetails = false);
    } catch (error) {
      if (mounted) {
        NotificationToast.show(error.toString(),
            title: AppLocalizations.of(context).error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NavigatorPopHandler<void>(
      enabled: widget.isActive,
      onPopWithResult: (_) {
        if (widget.isActive && _showDetails) {
          _navigatorKey.currentState?.pop();
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onDidRemovePage: (page) {
          if (page.key == const ValueKey('details') && _showDetails) {
            setState(() => _showDetails = false);
          }
        },
        pages: [
          MaterialPage<void>(
            key: const ValueKey('introduction'),
            child: IntroduceView(
              onShowDetails: () => setState(() => _showDetails = true),
            ),
          ),
          if (_showDetails)
            MaterialPage<void>(
              key: const ValueKey('details'),
              child: AbsorbPointer(
                absorbing: _busy,
                child: AnimeInfoView(
                  onPlay: () => _play((actions) => actions.resume()),
                  onPlayEpisode: (id) =>
                      _play((actions) => actions.selectEpisode(id)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
