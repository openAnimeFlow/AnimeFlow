import 'package:anime_flow/models/item/subject_comments_item.dart';
import 'package:anime_flow/widget/anime_detail/star.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:flutter/material.dart';

class InfoCommentView extends StatelessWidget {
  final SubjectCommentItem? subjectCommentItem;

  const InfoCommentView({
    super.key,
    required this.subjectCommentItem,
  });

  @override
  Widget build(BuildContext context) {
    if (subjectCommentItem == null) {
      return const SizedBox.shrink();
    } else {
      final subjectComments = subjectCommentItem!;
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
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              )
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjectComments.data.length,
            itemBuilder: (context, index) {
              final comment = subjectComments.data[index];
              return Column(
                children: [
                  _CommentItem(comment: comment),
                  if (index < subjectComments.data.length - 1)
                    const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      );
    }
  }
}

/// 单个评论项
class _CommentItem extends StatelessWidget {
  final DataItem comment;

  const _CommentItem({required this.comment});

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).focusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(
        //   color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息行
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimationNetworkImage(
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
                        //用户昵称
                        Text(
                          comment.user.nickname.isNotEmpty
                              ? comment.user.nickname
                              : comment.user.username,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // 时间
                        if (comment.rate > 0)
                          Text(
                            _formatTime(comment.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                      ],
                    ),

                    if (comment.rate > 0) ...[
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
                    ] else
                      Text(
                        _formatTime(comment.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),

                    // 评论内容
                    if (comment.comment.isNotEmpty) ...[
                      Text(
                        comment.comment,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
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
