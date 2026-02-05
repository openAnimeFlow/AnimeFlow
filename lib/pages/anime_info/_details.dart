part of 'synopsis.dart';

///详情信息
class _DetailsView extends StatelessWidget {
  final String title;
  final double? textSize;
  final FontWeight? textFontWeight;
  final SubjectsInfoItem subject;

  const _DetailsView(
      {required this.subject,
      required this.title,
      this.textSize,
      this.textFontWeight});

  @override
  Widget build(BuildContext context) {
    final Color themeTextColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        _buildText(textData: subject.infobox, themeTextColor: themeTextColor)
      ],
    );
  }

  Widget _buildText(
      {required List<Infobox> textData, required Color themeTextColor}) {
    // 过滤掉空值的条目（包括values为空或所有v字段都为空字符串的情况）
    final filteredData = textData.where((item) {
      return item.values.isNotEmpty &&
          item.values.any((value) => value.v.isNotEmpty);
    }).toList();

    // 如果条目少于等于10条，直接显示
    if (filteredData.length <= 10) {
      return _buildTextList(filteredData, themeTextColor);
    }

    // 如果超过10条，使用可展开的视图
    return _ExpandableTextList(
      textData: filteredData,
      themeTextColor: themeTextColor,
      textSize: textSize,
      textFontWeight: textFontWeight,
    );
  }

  Widget _buildTextList(List<Infobox> textData, Color themeTextColor) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: textData.length,
        itemBuilder: (context, index) {
          final key = textData[index].key;
          final values = textData[index].values;

          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '$key:',
              style: TextStyle(fontSize: textSize, fontWeight: textFontWeight),
            ),
            Expanded(
                child: _buildValueContent(values, themeTextColor, textSize)),
          ]);
        });
  }
}

class _ExpandableTextList extends StatefulWidget {
  final List<Infobox> textData;
  final Color themeTextColor;
  final double? textSize;
  final FontWeight? textFontWeight;

  const _ExpandableTextList({
    required this.textData,
    required this.themeTextColor,
    required this.textSize,
    required this.textFontWeight,
  });

  @override
  State<_ExpandableTextList> createState() => _ExpandableTextListState();
}

class _ExpandableTextListState extends State<_ExpandableTextList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayItems =
        _isExpanded ? widget.textData : widget.textData.take(10).toList();
    final disabledColor = Theme.of(context).disabledColor;
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      children: [
        ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final key = displayItems.elementAt(index).key;
              final values = displayItems.elementAt(index).values;

              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$key:',
                      style: TextStyle(
                          fontSize: widget.textSize,
                          fontWeight: widget.textFontWeight),
                    ),
                    Expanded(
                        child: _buildValueContent(
                            values, widget.themeTextColor, widget.textSize)),
                  ]);
            }),
        if (widget.textData.length > 10)
          Align(
            alignment: Alignment.center,
            child: TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: _isExpanded
                    ? Icon(
                        Icons.expand_less_rounded,
                        size: 25,
                        color: disabledColor,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.expand_more_rounded,
                              size: 25, color: disabledColor),
                          Text(
                            '(${widget.textData.length - 10})',
                            style: TextStyle(color: disabledColor),
                          )
                        ],
                      )),
          ),
      ],
    );
  }
}

//检查是否为URL
bool _isUrl(String text) {
  final trimmedText = text.trim();
  // 更完善的URL匹配正则表达式
  return RegExp(
          r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)')
      .hasMatch(trimmedText);
}

// 构建链接文本
Widget _buildLinkText(String url, Color themeTextColor, double? textSize) {
  return InkWell(
    splashFactory: NoSplash.splashFactory,
    onTap: () async {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    },
    child: Text(' $url',
        style: TextStyle(
          fontSize: textSize,
          color: Colors.blue,
        )),
  );
}

// 构建值内容
Widget _buildValueContent(
    List<Values> values, Color themeTextColor, double? textSize) {
  if (values.length == 1) {
    final value = values.first.v;
    if (_isUrl(value)) {
      return _buildLinkText(value, themeTextColor, textSize);
    }
  }

  return Text(' ${values.map((v) => v.v).join(', ')}',
      style: TextStyle(
        fontSize: textSize,
        color: themeTextColor,
      ));
}
