import 'package:anime_flow/models/item/bangumi/episode_comments_item.dart';
import 'package:anime_flow/pages/play/providers/episode_comments_provider.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/utils/format_time_util.dart';
import 'package:anime_flow/utils/systemUtil.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class CommentsView extends ConsumerStatefulWidget {
  const CommentsView({super.key});

  @override
  ConsumerState<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends ConsumerState<CommentsView>
    with AutomaticKeepAliveClientMixin {
  String _sortOrder = 'default';
  List<EpisodeComment>? _sortedComments;
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  void _updateSortedComments(List<EpisodeComment>? comments) {
    setState(() {
      if (comments == null) {
        _sortedComments = null;
      } else {
        _sortedComments = List<EpisodeComment>.from(comments);
        _applySort();
      }
    });
  }

  void _applySort() {
    if (_sortedComments == null) return;
    if (_sortOrder == 'newest') {
      _sortedComments!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _sortedComments!.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  void _sortComments() {
    setState(() {
      _applySort();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final commentsAsync = ref.watch(episodeCommentsProvider);
    ref.listen<AsyncValue<List<EpisodeComment>>>(
      episodeCommentsProvider,
      (previous, next) {
        _updateSortedComments(next.asData?.value);
      },
    );

    return Scaffold(
      body: buildComments(commentsAsync),
      floatingActionButton: commentsAsync.hasValue
          ? _CommentButton(scrollController: _scrollController)
          : null,
    );
  }

  Widget buildComments(AsyncValue<List<EpisodeComment>> commentsAsync) {
    if (commentsAsync.isLoading) {
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
    }

    if (commentsAsync.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              '评论加载失败',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(episodeCommentsProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final comments = _sortedComments ?? commentsAsync.value ?? const [];
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Text(
                  '吐槽',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  comments.isNotEmpty ? "评论数 ${comments.length}" : "评论数",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            sliver: SliverList.separated(
              itemCount: comments.length,
              itemBuilder: (BuildContext context, int index) {
                final comment = comments[index];
                return _buildCommentItem(comment);
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            ),
          )
      ],
    );
  }

  /*
   * 主评论
   */
  Widget _buildCommentItem(EpisodeComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                UserSpaceRoute(name: comment.user.username).push(context),
            child: AnimationNetworkImage(
              borderRadius: BorderRadius.circular(8),
              height: 48,
              width: 48,
              url: comment.user.avatar.large,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => UserSpaceRoute(name: comment.user.username)
                          .push(context),
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
                        fontWeight: FontWeight.bold,
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
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildReplies(comment.replies),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 回复列表
  Widget _buildReplies(List<Reply> replies) {
    return Column(
      children: replies.asMap().entries.map((entry) {
        final index = entry.key;
        final reply = entry.value;
        return Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    AnimationNetworkImage(
                      borderRadius: BorderRadius.circular(8),
                      height: 32,
                      width: 32,
                      url: reply.user.avatar.large,
                    ),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          FormatTimeUtil.formatTimestamp(reply.createdAt),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ))
                  ],
                ),
                if (reply.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  BBCodeWidget(
                    imagPreview: true,
                    borderRadius: BorderRadius.circular(8),
                    bbcode: reply.content,
                  )
                ],
              ],
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
    );
  }

  ///骨架屏
  Widget _skeleton(BuildContext context) {
    final isDark = SystemUtil.isDarkTheme(context);
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

class _CommentButton extends StatefulWidget {
  final ScrollController scrollController;

  const _CommentButton({required this.scrollController});

  @override
  State<_CommentButton> createState() => _CommentButtonState();
}

class _CommentButtonState extends State<_CommentButton> {
  static const double _hideLabelAfterPixels = 300;

  bool _hideLabel = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncLabelFromScroll());
  }

  @override
  void didUpdateWidget(_CommentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncLabelFromScroll());
    }
  }

  void _onScroll() {
    if (!mounted) return;
    if (!widget.scrollController.hasClients) {
      if (_hideLabel) setState(() => _hideLabel = false);
      return;
    }
    final hide =
        widget.scrollController.position.pixels > _hideLabelAfterPixels;
    if (hide != _hideLabel) {
      setState(() => _hideLabel = hide);
    }
  }

  void _syncLabelFromScroll() {
    if (!mounted) return;
    if (!widget.scrollController.hasClients) return;
    final hide =
        widget.scrollController.position.pixels > _hideLabelAfterPixels;
    if (hide != _hideLabel) {
      setState(() => _hideLabel = hide);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
    return FloatingActionButton.extended(
      onPressed: () {},
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.comment_outlined, size: 20),
          AnimatedCrossFade(
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            sizeCurve: Curves.easeInOut,
            duration: const Duration(milliseconds: 260),
            crossFadeState: _hideLabel
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox.shrink(),
            secondChild: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('评论', style: labelStyle),
            ),
          ),
        ],
      ),
    );
  }
}
