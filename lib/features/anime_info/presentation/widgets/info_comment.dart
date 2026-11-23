import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_args_provider.dart';
import 'package:anime_flow/features/anime_info/presentation/widgets/evaluate_form.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/shared/models/bangumi/subject_comments_item.dart';
import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([SubjectComments, AnimeInfo, animeInfoArgs])
class InfoCommentView extends ConsumerWidget {
  const InfoCommentView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final commentsAsync = ref.watch(subjectCommentsProvider);

    return commentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (viewState) {
        final subjectComments = viewState.comments;
        final isLoadingMore = viewState.isLoadingMore;
        final hasMore = viewState.hasMore;
        return _buildContent(
            context, ref, subjectComments, isLoadingMore, hasMore, l10n);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SubjectCommentItem subjectComments,
    bool isLoadingMore,
    bool hasMore,
    AppLocalizations l10n,
  ) {
    final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
    final canEvaluate = isLoggedIn &&
        ref.watch(animeInfoProvider.select((state) => state.hasValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.commentsTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${subjectComments.total}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const Spacer(),
            if (canEvaluate) _buildEvaluateButton(context, ref),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              subjectComments.data.length + (hasMore && isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == subjectComments.data.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final comment = subjectComments.data[index];
            return Column(
              children: [
                _buildCommentItem(context, comment: comment),
                if (index < subjectComments.data.length - 1)
                  const SizedBox(height: 8),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEvaluateButton(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return JellyMenu<SubjectsInfoItem?>(
      tooltip: '发表吐槽',
      triggerColor: Colors.transparent,
      barrierDismissible: false,
      avoidKeyboard: true,
      trigger: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '发表吐槽',
          style: TextStyle(color: colorScheme.primary),
        ),
      ),
      menuBuilder: (context, select) {
        final subjectsInfo = ref.read(animeInfoProvider).value;
        if (subjectsInfo == null) return const SizedBox.shrink();
        return InfoEvaluateForm(
          subjectsInfo: subjectsInfo,
          onSaved: select,
          onClose: () => select(null),
        );
      },
      onSelected: (updated) {
        if (updated == null ||
            !context.mounted ||
            ref.read(animeInfoArgsProvider).id != updated.id) {
          return;
        }
        ref.read(animeInfoProvider.notifier).setAnimeInfo(updated);
        ref.read(subjectCommentsProvider.notifier).refresh();
      },
    );
  }

  Widget _buildCommentItem(BuildContext context, {required DataItem comment}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color:
              theme.cardTheme.color ?? theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => appNavigatorOf(context)
                .openUserSpace<void>(name: comment.user.username),
            child: AnimationNetworkImage(
              borderRadius: BorderRadius.circular(10),
              url: comment.user.avatar.medium,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => appNavigatorOf(context)
                          .openUserSpace<void>(name: comment.user.username),
                      child: Text(
                        comment.user.nickname.isNotEmpty
                            ? comment.user.nickname
                            : comment.user.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      FormatTimeUtil.formatTime(comment.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                if (comment.rate > 0)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StarView(score: comment.rate.toDouble(), iconSize: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.rate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (comment.comment.isNotEmpty) ...[
                  Text(comment.comment),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
