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
          child: SizedBox(
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Text(
                    option.label,
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
          tooltip: currentOption.label,
        );
      },
    );
  }
}

enum _FitOption {
  contain(BoxFit.contain, '自动填充'),
  cover(BoxFit.cover, '裁剪填充'),
  fill(BoxFit.fill, '拉伸填充');

  const _FitOption(this.fit, this.label);

  final BoxFit fit;
  final String label;
}
