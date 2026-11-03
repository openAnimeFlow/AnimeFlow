import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:material_ui/material_ui.dart';

class UpscaleButton extends StatelessWidget {
  static const labels = {
    UpscalePreset.off: '关闭',
    UpscalePreset.efficiency: '效率档',
    UpscalePreset.quality: '质量档',
  };

  final UpscalePreset value;
  final PlayerCapabilities capabilities;
  final ValueChanged<UpscalePreset> onChanged;
  final VoidCallback? onMenuOpen;
  final VoidCallback? onMenuClose;

  const UpscaleButton({
    super.key,
    required this.value,
    required this.capabilities,
    required this.onChanged,
    this.onMenuOpen,
    this.onMenuClose,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      onOpen: onMenuOpen,
      onClose: onMenuClose,
      menuChildren: List<MenuItemButton>.generate(
        labels.length,
        (int index) {
          final preset = UpscalePreset.values[index];
          final effectivePreset = capabilities.supportsUpscalePreset(value)
              ? value
              : UpscalePreset.off;
          final isSelected = effectivePreset == preset;

          return MenuItemButton(
            onPressed: capabilities.supportsUpscalePreset(preset)
                ? () => onChanged(preset)
                : null,
            child: Container(
              height: 48,
              constraints: const BoxConstraints(minWidth: 112),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  labels[preset]!,
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
              color:
                  value.isEnabled && capabilities.supportsUpscalePreset(value)
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
