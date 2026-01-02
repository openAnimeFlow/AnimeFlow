import 'package:anime_flow/models/item/bangumi/subjects_info_item.dart';
import 'package:flutter/material.dart';

/// 标签组件（支持展开/收起）
class TagView extends StatefulWidget {
  final String title;
  final double? fontSizeTitle;
  final FontWeight? fontWeightTitle;
  final List<Tags> tags;
  final FontWeight? fontWeight;
  final FontWeight? numbersWeight;
  final double? numbersSize;
  final double? fontSize;
  final int maxVisibleCount;

  const TagView({
    super.key,
    this.fontWeight = FontWeight.w400,
    required this.tags,
    this.numbersWeight,
    this.numbersSize,
    this.fontSize,
    required this.title,
    this.fontSizeTitle,
    this.fontWeightTitle,
    this.maxVisibleCount = 11,
  });

  @override
  State<TagView> createState() => _TagViewState();
}

class _TagViewState extends State<TagView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.tags.length > widget.maxVisibleCount;
    final visibleTags = _isExpanded
        ? widget.tags
        : widget.tags.take(widget.maxVisibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: widget.fontSizeTitle,
            fontWeight: widget.fontWeightTitle,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...visibleTags.map((tag) => _buildTag(tag)),
            // 展开/收起按钮
            if (hasMore)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded
                              ? '收起'
                              : '+${widget.tags.length - widget.maxVisibleCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(Tags tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: widget.fontWeight,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${tag.count}',
            style: TextStyle(
              fontSize: widget.numbersSize,
              fontWeight: widget.numbersWeight,
            ),
          ),
        ],
      ),
    );
  }
}
