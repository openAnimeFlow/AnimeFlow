import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/utils/formatUtil.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
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
  int? _lastRequestedEpisodeId; // 记录上次请求的 episodeId，避免重复请求
  String _sortOrder = 'default';
  bool _isRequesting = false; // 标记是否正在请求中，防止并发请求

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    episodesController = Get.find<EpisodesController>();
    _getComments();
    _episodeIdWorker = ever(episodesController.episodeId, (episodeId) {
      // 只有当 episodeId 真的变化且大于 0 时才重新获取评论
      if (episodeId > 0 && episodeId != _lastRequestedEpisodeId) {
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

  // TODO 桌面端当缩放窗口时会频繁触发请求，应该将获取评论逻辑放CommentsView父组件中，通过传值获取数据(当tab索引==评论 || 评论内容内容 != null || EpisodeId放生变化)
  void _getComments() async {
    final episodeId = episodesController.episodeId.value;

    // 如果 episodeId 没有变化，直接返回，避免重复请求
    if (episodeId == _lastRequestedEpisodeId) {
      return;
    }

    // 如果正在请求中，直接返回，防止并发请求
    if (_isRequesting) {
      return;
    }

    if (episodeId > 0) {
      // 标记正在请求中
      _isRequesting = true;
      // 更新上次请求的 episodeId
      _lastRequestedEpisodeId = episodeId;

      try {
        final comments =
            await BgmRequest.episodeCommentsService(episodeId: episodeId);
        if (_sortOrder == 'newest') {
          comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
        // 再次检查 episodeId 是否仍然是当前值（防止请求期间 episodeId 变化）
        if (mounted && episodesController.episodeId.value == episodeId) {
          setState(() {
            this.comments = comments;
          });
        }
      } catch (e) {
        Logger().e(e);
        // 请求失败时也要检查 episodeId 是否仍然是当前值
        if (mounted && episodesController.episodeId.value == episodeId) {
          setState(() {
            comments = [];
          });
        }
      } finally {
        // 请求完成，重置标记
        _isRequesting = false;
      }
    } else {
      _lastRequestedEpisodeId = episodeId;
      if (mounted) {
        setState(() {
          comments = [];
        });
      }
    }
  }

  // 评论排序
  void _sortComments() {
    setState(() {
      if (_sortOrder == 'newest') {
        comments!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        comments!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
    });
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
                    ),
                    //排序
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort_rounded),
                      offset: const Offset(0, 40),
                      itemBuilder: (BuildContext context) {
                        return [
                          CheckedPopupMenuItem<String>(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            checked: _sortOrder == 'default',
                            value: 'default',
                            child: const Text('默认'),
                          ),
                          CheckedPopupMenuItem<String>(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            value: 'newest',
                            checked: _sortOrder == 'newest',
                            child: const Text('最新'),
                          ),
                        ];
                      },
                      onSelected: (value) {
                        setState(() {
                          _sortOrder = value;
                        });
                        _sortComments();
                      },
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
              padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  bottom: MediaQuery.of(context).padding.bottom),
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

  // 主评论
  Widget _buildCommentItem(EpisodeComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          FormatUtil.formatTimestamp(comment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    BBCodeWidget(
                      imagPreview:  true,
                      borderRadius: BorderRadius.circular(8),
                      bbcode: comment.content,
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
                    AnimationNetworkImage(
                      borderRadius: BorderRadius.circular(8),
                      height: 32,
                      width: 32,
                      url: reply.user.avatar.large,
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                FormatUtil.formatTimestamp(reply.createdAt),
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
