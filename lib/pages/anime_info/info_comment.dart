import 'package:anime_flow/models/item/bangumi/subject_comments_item.dart';
import 'package:anime_flow/pages/anime_info/anime_info_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InfoCommentView extends ConsumerWidget {
  final int subjectId;

  const InfoCommentView({
    super.key,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentState = ref.watch(
      animeInfoProvider(subjectId).select((asyncValue) {
        final state = asyncValue.asData?.value;
        if (state == null) return null;
        return (
          subjectComments: state.subjectComments,
          isLoadingComments: state.isLoadingComments,
          hasMoreComments: state.hasMoreComments,
        );
      }),
    );

    final subjectComments = commentState?.subjectComments;
    if (subjectComments == null) {
      return const SizedBox.shrink();
    }

    final isLoadingComments = commentState!.isLoadingComments;
    final hasMoreComments = commentState.hasMoreComments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              '吐槽',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${subjectComments.total}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            )
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjectComments.data.length +
              (hasMoreComments && isLoadingComments ? 1 : 0),
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

  Widget _buildCommentItem(BuildContext context, {required DataItem comment}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () =>
                    UserSpaceRoute(name: comment.user.username).push(context),
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
                          onTap: () => UserSpaceRoute(name: comment.user.username)
                              .push(context),
                          child: Text(
                            comment.user.nickname.isNotEmpty
                                ? comment.user.nickname
                                : comment.user.username,
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
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    if (comment.rate > 0)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          StarView(
                              score: comment.rate.toDouble(), iconSize: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${comment.rate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
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
        ],
      ),
    );
  }
}
