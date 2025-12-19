import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/episode_comments_item.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({super.key});

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView>
    with AutomaticKeepAliveClientMixin {
  List<EpisodeComment>? comments;
  late EpisodesController episodesController;
  Worker? _episodeIdWorker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    episodesController = Get.find<EpisodesController>();
    _getComments();
    _episodeIdWorker = ever(episodesController.episodeId, (episodeId) {
      if (episodeId > 0) {
        setState(() {
          comments = null;
        });
        _getComments();
      }
    });
  }

  @override
  void dispose() {
    _episodeIdWorker?.dispose();
    super.dispose();
  }

  void _getComments() async {
    final episodeId = episodesController.episodeId.value;
    if (episodeId > 0) {
      try {
        final fetchedComments =
            await BgmRequest.episodeCommentsService(episodeId: episodeId);
        if (mounted) {
          setState(() {
            comments = fetchedComments;
          });
        }
      } catch (e) {
        Logger().e(e);
        if (mounted) {
          setState(() {
            comments = [];
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          comments = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildComments();
  }

  Widget _buildComments() {
    if (comments == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      final comments = this.comments!;
      return CustomScrollView(
        slivers: [
          // 标题行
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Text(
                      '吐槽',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      comments.isNotEmpty ? "评论数 ${comments.length}" : "评论数",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // 评论列表或空状态
          if (comments.isEmpty)
            SliverFillRemaining(
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
                      '暂无评论',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(left: 10, right: 10, bottom:
                MediaQuery.of(context).padding.bottom
              ),
              sliver: SliverList.builder(
                itemCount: comments.length,
                itemBuilder: (BuildContext context, int index) {
                  final comment = comments[index];
                  return _buildCommentItem(comment);
                },
              ),
            )
        ],
      );
    }
  }

  Widget _buildCommentItem(EpisodeComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主评论
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AnimationNetworkImage(
                  height: 48,
                  width: 48,
                  url: comment.user.avatar.large,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.user.nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              )
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

  Widget _buildReplies(List<Reply> replies) {
    return Container(
      margin: const EdgeInsets.only(left: 56), // 与头像对齐
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: replies.asMap().entries.map((entry) {
          final index = entry.key;
          final reply = entry.value;
          return Column(
            children: [
              _buildReplyItem(reply),
              if (index < replies.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReplyItem(Reply reply) {
    // 解析引用内容
    final content = reply.content;
    final hasQuote = content.contains('[quote]');
    
    String? quoteText;
    String replyText = content;
    
    if (hasQuote) {
      // 匹配 [quote][b]用户名[/b] 说: 内容[/quote]
      final quoteMatch = RegExp(r'\[quote\]\[b\](.*?)\[/b\].*?说:\s*(.*?)\[/quote\]', dotAll: true).firstMatch(content);
      if (quoteMatch != null) {
        final quotedUser = quoteMatch.group(1) ?? '';
        final quotedContent = quoteMatch.group(2) ?? '';
        quoteText = '$quotedUser: $quotedContent';
        // 移除引用部分，保留剩余内容
        replyText = content.replaceAll(RegExp(r'\[quote\].*?\[/quote\]\s*', dotAll: true), '').trim();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimationNetworkImage(
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
                    Text(
                      reply.user.nickname,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(reply.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                if (quoteText != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      quoteText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                if (replyText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    replyText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.month}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
