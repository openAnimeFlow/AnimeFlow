import 'package:anime_flow/core/settings/app_settings.dart';
import 'package:material_ui/material_ui.dart';

class SettingsPageBuilder extends StatefulWidget {
  const SettingsPageBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool glassStyle) builder;

  static double topInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SettingsTopInset>()?.height ??
      0;

  @override
  State<SettingsPageBuilder> createState() => _SettingsPageBuilderState();
}

class _SettingsPageBuilderState extends State<SettingsPageBuilder> {
  late final _style = AppSettings.watchGlassNavigationStyle();

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
        stream: _style,
        initialData: AppSettings.glassNavigationStyle,
        builder: (context, snapshot) {
          final glassStyle = snapshot.data ?? false;
          return _SettingsTopInset(
            height: glassStyle
                ? MediaQuery.paddingOf(context).top + kToolbarHeight
                : 0,
            child: Builder(
              builder: (context) => widget.builder(context, glassStyle),
            ),
          );
        },
      );
}

class _SettingsTopInset extends InheritedWidget {
  const _SettingsTopInset({required this.height, required super.child});
  final double height;

  @override
  bool updateShouldNotify(_SettingsTopInset oldWidget) =>
      height != oldWidget.height;
}
