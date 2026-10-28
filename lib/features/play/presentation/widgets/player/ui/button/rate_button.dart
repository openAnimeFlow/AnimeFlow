import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class RateButton extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  const RateButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.onMenuOpen,
    this.onMenuClose,
  });

  static const List<double> speeds = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
    3.0,
    4.0,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return MenuAnchor(
      onOpen: onMenuOpen,
      onClose: onMenuClose,
      menuChildren: speeds.map((speed) {
        final isSelected = value == speed;
        return MenuItemButton(
          onPressed: () => onChanged(speed),
          child: SizedBox(
            width: 112,
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected ? colorScheme.primary : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return TextButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Text(value == 1.0 ? l10n.playbackRate : '${value}x'),
        );
      },
    );
  }
}
