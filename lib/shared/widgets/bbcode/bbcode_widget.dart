import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/image_viewer_extra.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:anime_flow/shared/widgets/image_preview.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:antlr4/antlr4.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bbcode_base_listener.dart';
import 'bbcode_elements.dart';
import 'generated/BBCodeParser.dart';
import 'generated/BBCodeLexer.dart';

class BBCodeWidget extends StatefulWidget {
  const BBCodeWidget({
    super.key,
    required this.bbcode,
    this.textScaler = TextScaler.noScaling,
  });

  final String bbcode;
  final TextScaler textScaler;

  @override
  State<StatefulWidget> createState() => _BBCodeWidgetState();
}

class _BBCodeWidgetState extends State<BBCodeWidget> {
  bool _isVisible = false;

  Color? _parseColor(String hex) {
    if (hex.startsWith('#')) {
      hex = hex.replaceFirst('#', '');
      if (hex.length == 6) {
        hex = "FF$hex";
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    switch (hex) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'grey':
        return Colors.grey;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    BBCodeParser.checkVersion();
    final input = InputStream.fromString(widget.bbcode);
    final lexer = BBCodeLexer(input);
    final tokens = CommonTokenStream(lexer);
    final parser = BBCodeParser(tokens);
    final tree = parser.document();
    final bbcodeBaseListener = BBCodeBaseListener();
    ParseTreeWalker.DEFAULT.walk(bbcodeBaseListener, tree);
    bbCodeTag.clear();

    final imageUrls = bbcodeBaseListener.bbcode
        .whereType<BBCodeImg>()
        .map((e) => e.imageUrl)
        .toList();
    var imageIndex = 0;

    return Wrap(
      children: [
        RichText(
          textScaler: widget.textScaler,
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: bbcodeBaseListener.bbcode.map((e) {
              if (e is BBCodeText) {
                Color? textColor = (!_isVisible && e.masked)
                    ? Colors.transparent
                    : (e.link != null)
                    ? Colors.blue
                    : (e.quoted)
                    ? Theme.of(context).colorScheme.outline
                    : (e.color != null)
                    ? _parseColor(e.color!)
                    : null;
                return TextSpan(
                  text: e.text,
                  mouseCursor: (e.link != null || e.masked)
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.text,
                  recognizer: TapGestureRecognizer()
                    ..onTap = (e.link != null || e.masked)
                        ? () {
                      if ((!e.masked || _isVisible) && e.link != null) {
                        launchUrl(Uri.parse(e.link!));
                      } else if (e.masked) {
                        setState(() {
                          _isVisible = !_isVisible;
                        });
                      }
                    }
                        : null,
                  style: TextStyle(
                    fontWeight: (e.bold) ? FontWeight.bold : null,
                    fontStyle: (e.italic) ? FontStyle.italic : null,
                    decoration: TextDecoration.combine([
                      if (e.underline || e.link != null)
                        TextDecoration.underline,
                      if (e.strikeThrough) TextDecoration.lineThrough,
                    ]),
                    decorationColor: textColor,
                    fontSize: e.size.toDouble(),
                    color: textColor,
                    backgroundColor:
                    (!_isVisible && e.masked) ? const Color(0xFF555555) : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              } else if (e is BBCodeImg) {
                final currentIndex = imageIndex++;
                final heroTag =
                ImageViewer.heroTagFor(e.imageUrl, currentIndex);
                return WidgetSpan(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: GestureDetector(
                      onTap: () => ImagePreviewRoute.fromArgs(
                        ImageViewerRouteArgs(
                          imageUrls: imageUrls,
                          initialIndex: currentIndex,
                          heroTag: heroTag,
                        ),
                      ).push(context),
                      child: Hero(
                        tag: heroTag,
                        child: AnimationNetworkImage(
                          url: e.imageUrl,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                );
              } else if (e is BBCodeBgm) {
                String url;
                if (e.id == 11 || e.id == 23) {
                  url = 'https://bangumi.tv/img/smiles/bgm/${e.id}.gif';
                }
                if (e.id < 24) {
                  url = 'https://bangumi.tv/img/smiles/bgm/${e.id}.png';
                }
                if (e.id < 33) {
                  url = 'https://bangumi.tv/img/smiles/tv/0${e.id - 23}.gif';
                }
                url = 'https://bangumi.tv/img/smiles/tv/${e.id - 23}.gif';
                return WidgetSpan(
                  child: AnimationNetworkImage(
                     url: url,
                  ),
                );
              } else if (e is BBCodeMusume) {
                return WidgetSpan(
                  child: AnimationNetworkImage(
                    url: 'https://lain.bgm.tv/img/smiles/musume/musume_${e.id}.gif',
                    width: 50,
                    height: 50,
                  ),
                );
              } else if (e is BBCodeSticker) {
                return WidgetSpan(
                  child: AnimationNetworkImage(
                    url: 'https://bangumi.tv/img/smiles/${e.id}.gif',
                  ),
                );
              } else {
                return WidgetSpan(
                  child: Icon(
                    (e as Icon).icon,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  alignment: PlaceholderAlignment.top,
                );
              }
            }).toList(),
          ),
        ),
      ],
    );
  }
}
