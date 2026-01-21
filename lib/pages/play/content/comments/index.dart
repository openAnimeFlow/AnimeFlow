import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/utils/formatUtil.dart';
import 'package:anime_flow/utils/utils.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CommentsView extends StatefulWidget {
  final List<EpisodeComment>? comments;

  const CommentsView({super.key, this.comments});

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView>
    with AutomaticKeepAliveClientMixin {
  String _sortOrder = 'default';
  List<EpisodeComment>? _sortedComments; // 排序后的评论列表

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _updateSortedComments();
  }

  @override
  void didUpdateWidget(CommentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当传入的 comments 变化时，更新排序后的列表
    if (oldWidget.comments != widget.comments) {
      _updateSortedComments();
    }
  }

  // 更新排序后的评论列表
  void _updateSortedComments() {
    if (widget.comments == null) {
      _sortedComments = null;
    } else {
      _sortedComments = List<EpisodeComment>.from(widget.comments!);
      _applySort();
    }
  }

  // 应用排序
  void _applySort() {
    if (_sortedComments == null) return;
    if (_sortOrder == 'newest') {
      _sortedComments!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _sortedComments!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  // 评论排序
  void _sortComments() {
    setState(() {
      _applySort();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // 评论列表
        Expanded(child: _buildComments()),
        //评论输入框
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildCommentInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: TextField(
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: '发送评论施工中...',
          hintStyle: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: isDark
              ? Colors.grey[800]?.withValues(alpha: 0.6)
              : Colors.grey[200]?.withValues(alpha: 0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildComments() {
    if (widget.comments == null) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: List.generate(
              5,
              (index) {
                return Column(
                  children: [
                    _skeleton(context),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        ),
      );
    } else {
      final comments = _sortedComments ?? widget.comments!;
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
                      imagPreview: true,
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

  ///骨架屏
  Widget _skeleton(BuildContext context) {
    final isDark = Utils.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[400]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[300]! : Colors.grey[100]!;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;
    return Row(
      children: [
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 25,
                  width: 100,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 20,
                  width: 200,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
