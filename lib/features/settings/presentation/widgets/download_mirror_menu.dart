import 'package:anime_flow/core/settings/rules_mirror.dart';
import 'package:anime_flow/shared/widgets/jelly_menu.dart';
import 'package:material_ui/material_ui.dart';

class DownloadMirrorMenu extends StatelessWidget {
  const DownloadMirrorMenu({
    super.key,
    required this.selectedMirror,
    required this.tooltip,
    required this.onSelected,
    this.enabled = true,
  });

  final RulesMirror selectedMirror;
  final String tooltip;
  final ValueChanged<RulesMirror> onSelected;
  final bool enabled;

  static String _label(RulesMirror mirror) => switch (mirror) {
        RulesMirror.ghProxy => 'gh-proxy.org',
        RulesMirror.jsDelivr => 'jsDelivr',
        RulesMirror.direct => 'GitHub',
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return JellyMenu<RulesMirror>(
      tooltip: tooltip,
      enabled: enabled,
      triggerResizeDuration: const Duration(milliseconds: 220),
      triggerResizeAlignment: AlignmentDirectional.centerEnd,
      triggerBuilder: (context, open) => TextButton(
        onPressed: open,
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _label(selectedMirror),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      menuBuilder: (context, select) => SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final mirror in RulesMirror.values)
                MenuItemButton(
                  trailingIcon: mirror == selectedMirror
                      ? Icon(Icons.check, size: 18, color: colors.primary)
                      : null,
                  onPressed: !enabled || mirror == selectedMirror
                      ? null
                      : () => select(mirror),
                  child: Text(_label(mirror)),
                ),
            ],
          ),
        ),
      ),
      onSelected: onSelected,
    );
  }
}
