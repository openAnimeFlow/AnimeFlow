import 'package:anime_flow/shared/models/bangumi/subject_comments_item.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/core/utils/format_time_util.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/star.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class InfoCommentView extends StatelessWidget {
  const InfoCommentView({
    super.key,
    required this.comments,
    required this.isLoadingMore,
  });

  final List<DataItem> comments;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == comments.length) {
          return const InfoCommentSkeleton();
        }

        final comment = comments[index];
        return Column(
          children: [
            _buildCommentItem(context, comment: comment),
            if (index < comments.length - 1 || isLoadingMore)
              const SizedBox(height: 8),
          ],
        );
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
              gaplessResize: true,
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

class InfoCommentSkeleton extends StatelessWidget {
  const InfoCommentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    final baseColor = colors.surfaceContainerHighest;
    final highlightColor = Color.lerp(
      baseColor,
      isDark ? colors.onSurface : colors.surface,
      isDark ? 0.08 : 0.65,
    )!;
    final lineDecoration = BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(4),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        enabled: !MediaQuery.disableAnimationsOf(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.3,
                    child: Container(height: 14, decoration: lineDecoration),
                  ),
                  Container(height: 12, decoration: lineDecoration),
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Container(height: 12, decoration: lineDecoration),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
