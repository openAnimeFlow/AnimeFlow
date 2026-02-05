part of 'synopsis.dart';

class _CommentView extends StatefulWidget {
  final int subjectId;

  const _CommentView({
    super.key,
    required this.subjectId,
  });

  @override
  State<_CommentView> createState() => _CommentViewState();
}

class _CommentViewState extends State<_CommentView> {
  SubjectCommentItem? subjectCommentItem;
  int _commentOffset = 0;
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;

  @override
  void initState() {
    super.initState();
    _getSubjectComment();
  }

  /// 获取评论信息
  Future<void> _getSubjectComment({bool loadMore = false}) async {
    if (_isLoadingComments || (loadMore && !_hasMoreComments)) return;

    setState(() {
      _isLoadingComments = true;
    });

    final currentOffset = loadMore ? _commentOffset + 1 : 0;
    final result = await BgmRequest.getSubjectCommentsByIdService(
        subjectId: widget.subjectId, limit: 20, offset: currentOffset);

    if (mounted) {
      setState(() {
        if (loadMore && subjectCommentItem != null) {
          // 追加数据
          final newDataList = [
            ...subjectCommentItem!.data,
            ...result.data,
          ];
          subjectCommentItem = SubjectCommentItem(
            data: newDataList,
            total: result.total,
          );
        } else {
          // 首次加载，替换数据
          subjectCommentItem = result;
        }
        _commentOffset = currentOffset;
        _hasMoreComments = result.data.isNotEmpty &&
            (subjectCommentItem?.data.length ?? 0) < (result.total);
        _isLoadingComments = false;
      });
    }
  }

  /// 加载更多评论
  void loadMore() {
    _getSubjectComment(loadMore: true);
  }

  /// 检查是否应该加载更多（由外部滚动监听调用）
  void checkAndLoadMore(ScrollMetrics metrics) {
    if (metrics.pixels >= metrics.maxScrollExtent - 200 &&
        !_isLoadingComments &&
        _hasMoreComments) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loadMore();
      });
    }
  }

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
            itemCount: subjectComments.data.length +
                (_hasMoreComments && _isLoadingComments ? 1 : 0),
            itemBuilder: (context, index) {
              // 显示加载中指示器
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
                  _buildCommentItem(comment: comment),
                  if (index < subjectComments.data.length - 1)
                    const SizedBox(height: 8),
                ],
              );
            },
          ),
        ],
      );
    }
  }

  /// 单个评论项
  Widget _buildCommentItem({required DataItem comment}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Get.theme.disabledColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              InkWell(
                onTap: () => Get.toNamed(RouteName.userSpace,
                    arguments: comment.user.username),
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
                        //用户昵称
                         InkWell(
                            onTap: () => Get.toNamed(RouteName.userSpace,
                                arguments: comment.user.username),
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
                        // 时间
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
                    // 评论内容
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
