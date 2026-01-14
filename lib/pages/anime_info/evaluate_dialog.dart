import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/stores/anime_info_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EvaluateDialog extends StatefulWidget {

  const EvaluateDialog({super.key});

  @override
  State<EvaluateDialog> createState() => _EvaluateDialogState();
}

class _EvaluateDialogState extends State<EvaluateDialog> {
  late TextEditingController _commentController;
  late TextEditingController _tagsController;
  late AnimeInfoStore animeInfoStore;
  int _selectedRate = 0; // 0-10分，0表示未评分
  bool _isSubmitting = false;
  final Set<String> _selectedTags = {}; // 选中的标签集合

  @override
  void initState() {
    super.initState();
    animeInfoStore = Get.find<AnimeInfoStore>();
    // 初始化已有数据
    final interest = animeInfoStore.animeInfo.value!.interest;
    if (interest != null) {
      _selectedRate = interest.rate;
      _commentController = TextEditingController(text: interest.comment);
    } else {
      _commentController = TextEditingController();
    }
    _tagsController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final comment = _commentController.text.trim();
      final rate = _selectedRate > 0 ? _selectedRate : null;
      final tags = _selectedTags.isNotEmpty ? _selectedTags.toList() : null;

      final currentAnimeInfo = animeInfoStore.animeInfo.value!;
      if (currentAnimeInfo.interest != null) {
        if (rate != null) {
          currentAnimeInfo.interest!.rate = rate;
        }
        if (comment.isNotEmpty) {
          currentAnimeInfo.interest!.comment = comment;
        }
        if (tags != null) {
          currentAnimeInfo.interest!.tags = tags;
        }
      }
      
      await UserRequest.updateCollectionService(
        currentAnimeInfo.id,
        rate: rate,
        tags: tags,
        comment: comment.isNotEmpty ? comment : null,
      );

      animeInfoStore.animeInfo.refresh();

      if (mounted) {
        Get.back();
        Get.snackbar('评价成功', '评价已保存', maxWidth: 500);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('评价失败', e.toString(), maxWidth: 500);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final animeInfo = animeInfoStore.animeInfo.value!;
    return  Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      animeInfo.nameCN.isNotEmpty
                          ? animeInfo.nameCN
                          : animeInfo.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // 评价内容
              Container(
                constraints:
                    const BoxConstraints(maxWidth: 500, maxHeight: 600),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 评分选择
                      _buildStarRating(primaryColor),
                      const SizedBox(height: 12),
                      // 标签输入框
                      TextField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          hintText: "选择标签或手动输入...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      if (animeInfo.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(height: 80, child: _buildTags),
                      ],
                      const SizedBox(height: 12),
                      // 评价输入框
                      SizedBox(
                        height: 100,
                        child: TextField(
                          controller: _commentController,
                          maxLines: null,
                          // 设置为null以允许滚动
                          expands: true,
                          // 允许TextField填充整个高度
                          textAlignVertical: TextAlignVertical.top,
                          // 文本从顶部开始
                          decoration: InputDecoration(
                            hintText: "写下你的评价...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.dividerColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 提交按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitEvaluation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  '保存评价',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(Color primaryColor) {
    return Column(
      children: [
        // 显示当前评分
        if (_selectedRate > 0)
          Text(
            '$_selectedRate分',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            '未评分',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1; // 第几颗星（1-5）
            final halfStarValue = starIndex * 2 - 1; // 半星分数：1, 3, 5, 7, 9
            final fullStarValue = starIndex * 2; // 满星分数：2, 4, 6, 8, 10

            // 判断当前星星的状态
            final isFullStar = _selectedRate >= fullStarValue;
            final isHalfStar =
                _selectedRate >= halfStarValue && _selectedRate < fullStarValue;

            return GestureDetector(
              onTap: () {
                setState(() {
                  // 点击逻辑：未选中 -> 半星 -> 满星 -> 未选中
                  if (isFullStar) {
                    // 如果当前是满星，点击后回到前一颗星的满星状态，或者取消
                    if (starIndex > 1) {
                      _selectedRate = (starIndex - 1) * 2; // 前一颗星的满星分数
                    } else {
                      _selectedRate = 0; // 如果是第一颗星，则取消
                    }
                  } else if (isHalfStar) {
                    // 如果当前是半星，点击后变为满星
                    _selectedRate = fullStarValue;
                  } else {
                    // 如果当前是空星，点击后变为半星
                    _selectedRate = halfStarValue;
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isFullStar
                      ? Icons.star_rate_rounded
                      : isHalfStar
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded,
                  color: isFullStar || isHalfStar
                      ? Colors.amber
                      : Colors.grey[400],
                  size: 35,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget get _buildTags {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final animeInfo = animeInfoStore.animeInfo.value!;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 5,
          runSpacing: 5,
          children: animeInfo.tags.map(
            (tag) {
              final isSelected = _selectedTags.contains(tag.name);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      // 取消选中
                      _selectedTags.remove(tag.name);
                      // 从输入框移除标签
                      final currentText = _tagsController.text;
                      final tagText = tag.name;
                      final updatedText = currentText
                          .split(' ')
                          .where((t) => t.trim().isNotEmpty && t != tagText)
                          .join(' ')
                          .trim();
                      _tagsController.text = updatedText;
                    } else {
                      // 选中标签
                      _selectedTags.add(tag.name);
                      // 添加到输入框
                      final currentText = _tagsController.text.trim();
                      if (currentText.isEmpty) {
                        _tagsController.text = tag.name;
                      } else {
                        _tagsController.text = '$currentText $tag.name';
                      }
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: tag.name,
                      children: [TextSpan(text: ' ${tag.count}')],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? primaryColor : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
