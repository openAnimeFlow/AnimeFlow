import 'package:flutter/material.dart';

class ShaderButton extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  const ShaderButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.onMenuOpen,
    this.onMenuClose,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['关闭', '效率档', '质量档'];

    return MenuAnchor(
      onOpen: onMenuOpen,
      onClose: onMenuClose,
      menuChildren: List<MenuItemButton>.generate(
        labels.length,
        (int index) {
          final type = index + 1;
          final isSelected = value == type;

          return MenuItemButton(
            onPressed: () {
              onChanged(type);
            },
            child: Container(
              height: 48,
              constraints: const BoxConstraints(minWidth: 112),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
        final themePrimary = Theme.of(context).colorScheme.primary;
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: value == 2 || value == 3
                  ? themePrimary.withValues(alpha: 0.5)
                  : null,
            ),
            child: Text(
              '4k',
              style: TextStyle(
                  color: themePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}
