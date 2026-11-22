import 'package:anime_flow/core/settings/rules_mirror.dart';
import 'package:anime_flow/shared/widgets/drop_down_menu.dart';
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
    final primary = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      ignoring: !enabled,
      child: DropDownMenu<RulesMirror>(
        items: RulesMirror.values,
        selectedItem: selectedMirror,
        tooltip: tooltip,
        onSelected: onSelected,
        buttonBuilder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_label(selectedMirror), style: TextStyle(color: primary)),
              Icon(Icons.arrow_drop_down, color: primary),
            ],
          ),
        ),
        itemBuilder: (context, mirror, selected) => Row(
          children: [
            SizedBox(
              width: 28,
              child:
                  selected ? Icon(Icons.check, size: 18, color: primary) : null,
            ),
            Text(_label(mirror)),
          ],
        ),
      ),
    );
  }
}
