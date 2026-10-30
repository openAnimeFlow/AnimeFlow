import 'dart:async';

import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/navigation/args/wallpaper_detail_args.dart';
import 'package:anime_flow/features/home/presentation/pages/wallpaper_detail_page.dart';
import 'package:material_ui/material_ui.dart';

/// 保持列表挂载，宽屏原位查看详情，窄屏使用完整详情路由。
class WallpaperBrowser extends StatefulWidget {
  const WallpaperBrowser({super.key, required this.listBuilder});

  final Widget Function(BuildContext, ValueChanged<WallpaperDetailArgs>)
      listBuilder;

  @override
  State<WallpaperBrowser> createState() => _WallpaperBrowserState();
}

class _WallpaperBrowserState extends State<WallpaperBrowser> {
  final _selection = ValueNotifier<WallpaperDetailArgs?>(null);
  bool _wide = false;
  bool _handoffScheduled = false;

  void _open(WallpaperDetailArgs args) {
    if (_wide) {
      _selection.value = args;
    } else {
      unawaited(appNavigatorOf(context).openWallpaper<void>(args));
    }
  }

  void _close() => _selection.value = null;

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          _wide = constraints.maxWidth >= 1000;
          return ValueListenableBuilder<WallpaperDetailArgs?>(
            valueListenable: _selection,
            child: widget.listBuilder(context, _open),
            builder: (context, selected, child) {
              if (!_wide && selected != null && !_handoffScheduled) {
                _handoffScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handoffScheduled = false;
                  if (!mounted || _wide || _selection.value != selected) return;
                  _close();
                  _open(selected);
                });
              }
              final showDetail = _wide && selected != null;
              final listWidth =
                  (constraints.maxWidth * 0.4).clamp(360.0, 600.0);
              // 列表始终位于 Row 的第一个槽位，打开/关闭详情不会重建其状态。
              return Row(children: [
                Expanded(child: child!),
                if (showDetail) const VerticalDivider(width: 1),
                SizedBox(
                  width: showDetail ? constraints.maxWidth - listWidth - 1 : 0,
                  child: showDetail
                      ? WallpaperDetailPage(
                          key: ValueKey((
                            selected.subject.subjectId,
                            selected.initialUrl
                          )),
                          args: selected,
                          onClose: _close,
                          onOpenRelated: _open,
                        )
                      : null,
                ),
              ]);
            },
          );
        },
      );
}
