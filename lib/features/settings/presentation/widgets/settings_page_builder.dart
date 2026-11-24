import 'package:anime_flow/shared/widgets/top_gradient_mask.dart';
import 'package:material_ui/material_ui.dart';

class SettingsPageBuilder extends StatelessWidget {
  const SettingsPageBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  static double topInsetOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SettingsTopInset>()?.height ??
      0;

  @override
  Widget build(BuildContext context) => _SettingsTopInset(
        height: MediaQuery.paddingOf(context).top + kToolbarHeight,
        child: Builder(builder: builder),
      );
}

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.maskColor,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Color? maskColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        title: title,
        leading: leading,
        actions: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
        toolbarHeight: preferredSize.height,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: IgnorePointer(
          child: SizedBox.expand(
            child: TopGradientMask(color: maskColor),
          ),
        ),
      );
}

class _SettingsTopInset extends InheritedWidget {
  const _SettingsTopInset({required this.height, required super.child});
  final double height;

  @override
  bool updateShouldNotify(_SettingsTopInset oldWidget) =>
      height != oldWidget.height;
}
