import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/character_comments_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CharacterCommentsView extends StatefulWidget {
  final int characterId;

  const CharacterCommentsView({super.key, required this.characterId});

  @override
  State<CharacterCommentsView> createState() => _CharacterCommentsViewState();
}

class _CharacterCommentsViewState extends State<CharacterCommentsView> {
  List<CharacterCommentItem>? comments;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getComments();
  }

  void _getComments() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });
    try {
      final result =
          await BgmRequest.characterCommentsService(widget.characterId);
      if (mounted) {
        setState(() {
          comments = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && comments == null) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (comments == null || comments!.isEmpty) {
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
        itemCount: comments!.length,
        itemBuilder: (context, index) {
          final comment = comments![index];
          return _buildCommentItem(comment);
        },
      ),
    );
  }

  Widget _buildCommentItem(CharacterCommentItem comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => Get.toNamed(RouteName.userSpace,
                      arguments: comment.user.username),
                  child: AnimationNetworkImage(
                    height: 48,
                    width: 48,
                    url: comment.user.avatar.large,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Get.toNamed(RouteName.userSpace,
                              arguments: comment.user.username),
                          child: Text(
                            comment.user.nickname,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          FormatTimeUtil.formatTimestamp(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    BBCodeWidget(
                      imagPreview: true,
                      borderRadius: BorderRadius.circular(8),
                      bbcode: comment.content,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 回复列表
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildReplies(comment.replies),
          ],
        ],
      ),
    );
  }

  Widget _buildReplies(List<CharacterCommentReply> replies) {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: replies.asMap().entries.map((entry) {
          final index = entry.key;
          final reply = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => Get.toNamed(RouteName.userSpace,
                          arguments: reply.user.username),
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
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Get.toNamed(RouteName.userSpace,
                                    arguments: reply.user.username),
                                child: Text(
                                  reply.user.nickname,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                FormatTimeUtil.formatTimestamp(reply.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          if (reply.content.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            BBCodeWidget(
                              borderRadius: BorderRadius.circular(8),
                              bbcode: reply.content,
                            )
                          ],
                        ],
                      ),
                    )
                  ],
                ),
              ),
              if (index < replies.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
