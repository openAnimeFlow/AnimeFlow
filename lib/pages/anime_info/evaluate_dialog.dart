import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/enums/collect_type.dart';
import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EvaluateDialog extends StatefulWidget {
  final SubjectsInfoItem subjectsInfo;

  const EvaluateDialog({super.key, required this.subjectsInfo});

  @override
  State<EvaluateDialog> createState() => _EvaluateDialogState();
}

class _EvaluateDialogState extends State<EvaluateDialog> {
  late TextEditingController _commentController;
  int _selectedRate = 0; // 0-10分，0表示未评分
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 初始化已有数据
    final interest = widget.subjectsInfo.interest;
    if (interest != null) {
      _selectedRate = interest.rate;
      _commentController = TextEditingController(text: interest.comment);
    } else {
      _commentController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
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

      await UserRequest.updateCollectionService(
        widget.subjectsInfo.id,
        rate: rate,
        comment: comment.isNotEmpty ? comment : null,
      );

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

    return Dialog(
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
                      widget.subjectsInfo.nameCN.isNotEmpty
                          ? widget.subjectsInfo.nameCN
                          : widget.subjectsInfo.name,
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
                      // 评价输入框
                      _buildSectionTitle('评价'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: TextField(
                          controller: _commentController,
                          maxLines: null, // 设置为null以允许滚动
                          expands: true, // 允许TextField填充整个高度
                          textAlignVertical: TextAlignVertical.top, // 文本从顶部开始
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
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.titleMedium?.color,
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(10, (index) {
            final starValue = index + 1; // 每颗星1分，1-10星对应1-10分
            final isSelected = _selectedRate >= starValue;

            return GestureDetector(
              onTap: () {
                setState(() {
                  // 点击星星：如果已选中则取消，否则设置为整星
                  if (_selectedRate == starValue) {
                    _selectedRate = 0;
                  } else {
                    _selectedRate = starValue;
                  }
                });
              },
              child:  Icon(
                  isSelected
                      ? Icons.star_rate_rounded
                      : Icons.star_outline_rounded,
                  color: isSelected
                      ? Colors.amber
                      : Colors.grey[400],
                  size: 27,
                ),
            );
          }),
        ),
      ],
    );
  }
}
