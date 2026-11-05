import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/network/core/flow_response.dart';
import 'package:material_ui/material_ui.dart';

/// 在已加载的剧集旁展示分页错误，重试时保留当前选集和已有列表。
class EpisodeLoadMoreError extends StatelessWidget {
  const EpisodeLoadMoreError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            resolveAnimeFlowErrorMessage(error,
                fallback: l10n.episodeLoadFailed),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
