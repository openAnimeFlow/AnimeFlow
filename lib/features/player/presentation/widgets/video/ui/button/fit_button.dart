import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class FitButton extends StatelessWidget {
  final BoxFit value;
  final ValueChanged<BoxFit> onChanged;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  const FitButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.onMenuOpen,
    this.onMenuClose,
  });

  static const List<_FitOption> _options = _FitOption.values;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final currentOption = _options.firstWhere(
      (o) => o.fit == value,
      orElse: () => _options.first,
    );

    return MenuAnchor(
      onOpen: () => onMenuOpen?.call(),
      onClose: () => onMenuClose?.call(),
      menuChildren: _options.map((option) {
        final isSelected = value == option.fit;
        return MenuItemButton(
          onPressed: () => onChanged(option.fit),
          child: Row(
            spacing: 10,
            children: [
              Expanded(
                child: Text(
                  option.label(l10n),
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
        );
      }).toList(),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          padding: const EdgeInsets.all(0),
          icon: const Icon(
            Icons.aspect_ratio_outlined,
            size: 25,
            color: Colors.white70,
          ),
          tooltip: currentOption.label(l10n),
        );
      },
    );
  }
}

enum _FitOption {
  contain(BoxFit.contain),
  cover(BoxFit.cover),
  fill(BoxFit.fill);

  const _FitOption(this.fit);

  final BoxFit fit;

  String label(AppLocalizations l10n) => switch (this) {
        _FitOption.contain => l10n.fitAuto,
        _FitOption.cover => l10n.fitCrop,
        _FitOption.fill => l10n.fitStretch,
      };
}
