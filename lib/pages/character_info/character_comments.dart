import 'package:anime_flow/models/item/bangumi/character_comments_item.dart';
import 'package:anime_flow/pages/character_info/provider/character_info_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CharacterCommentsView extends StatelessWidget {
  const CharacterCommentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final commentsAsync = ref.watch(characterCommentsProvider);

        return commentsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SliverFillRemaining(
            child: Center(child: Text('加载吐槽失败')),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无吐槽',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return KeyedSubtree(
                    key: ValueKey(comment.id),
                    child: _buildCommentItem(context, comment),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    CharacterCommentItem comment,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                UserSpaceRoute(name: comment.user.username).push(context),
            child: AnimationNetworkImage(
              borderRadius: BorderRadius.circular(8),
              height: 48,
              width: 48,
              url: comment.user.avatar.large,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () =>
                      UserSpaceRoute(name: comment.user.username).push(context),
                  child: Text(
                    comment.user.nickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  FormatTimeUtil.formatTimestamp(comment.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                BBCodeWidget(
                  imagPreview: true,
                  borderRadius: BorderRadius.circular(8),
                  bbcode: comment.content,
                ),
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReplies(context, comment.replies),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplies(
    BuildContext context,
    List<CharacterCommentReply> replies,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: replies.asMap().entries.map((entry) {
        final index = entry.key;
        final reply = entry.value;
        return Column(
          key: ValueKey(reply.id),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () =>
                      UserSpaceRoute(name: reply.user.username).push(context),
                  child: AnimationNetworkImage(
                    borderRadius: BorderRadius.circular(8),
                    height: 32,
                    width: 32,
                    url: reply.user.avatar.large,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => UserSpaceRoute(name: reply.user.username)
                            .push(context),
                        child: Text(
                          reply.user.nickname,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        FormatTimeUtil.formatTimestamp(reply.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (reply.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              BBCodeWidget(
                imagPreview: true,
                borderRadius: BorderRadius.circular(8),
                bbcode: reply.content,
              ),
            ],
            if (index < replies.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
          ],
        );
      }).toList(),
    );
  }
}
