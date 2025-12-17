import 'package:flutter/material.dart';

/// 可展开文本组件
class ExpandableText extends StatefulWidget {
  final double? fontSizeTitle;
  final FontWeight? fontWeightTitle;
  final String title;
  final String text;
  final int maxLines;
  final FontWeight? fontWeight;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 10,
    this.fontWeight = FontWeight.w600,
    required this.title,
    this.fontSizeTitle,
    this.fontWeightTitle,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            widget.title,
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: widget.fontSizeTitle,
                fontWeight: widget.fontWeightTitle),
          ),
          const SizedBox(height: 5),
          LayoutBuilder(
            builder: (context, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(
                    text: widget.text,
                    style: TextStyle(fontWeight: widget.fontWeight)),
                maxLines: widget.maxLines,
                textDirection: TextDirection.ltr,
              );
              textPainter.layout(maxWidth: constraints.maxWidth);

              final showExpandButton = textPainter.didExceedMaxLines;

              if (_isExpanded) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        child: Text(
                          widget.text,
                          style: TextStyle(fontWeight: widget.fontWeight),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        icon: const Icon(Icons.expand_less_rounded, size: 30),
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = true;
                        });
                      },
                      child: Text(
                        widget.text,
                        style: TextStyle(fontWeight: widget.fontWeight),
                        maxLines: widget.maxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (showExpandButton)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withValues(alpha: 0),
                              Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withValues(alpha: 0.8),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _isExpanded = true;
                              });
                            },
                            icon:
                                const Icon(Icons.expand_more_rounded, size: 30),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        ]));
  }
}
