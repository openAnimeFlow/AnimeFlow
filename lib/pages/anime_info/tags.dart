import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:flutter/material.dart';

///标签组件
class TagView extends StatelessWidget {
  final String title;
  final double? fontSizeTitle;
  final FontWeight? fontWeightTitle;
  final List<Tags> tags;
  final FontWeight? fontWeight;
  final FontWeight? numbersWeight;
  final double? numbersSize;
  final double? fontSize;

  const TagView({
    super.key,
    this.fontWeight = FontWeight.w400,
    required this.tags,
    this.numbersWeight,
    this.numbersSize,
    this.fontSize,
    required this.title, this.fontSizeTitle, this.fontWeightTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: fontSizeTitle, fontWeight: fontWeightTitle)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                            fontWeight: fontWeight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tag.count}',
                          style: TextStyle(
                              fontSize: numbersSize, fontWeight: numbersWeight),
                        )
                      ],
                    ),
                  ))
              .toList(),
        )
      ],
    );
  }
}
