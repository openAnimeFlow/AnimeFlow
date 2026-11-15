import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/domain/player/player_capabilities.dart';
import 'package:anime_flow/features/play/domain/player/upscale_preset.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';

const _upscaleLabels = {
  UpscalePreset.off: '关闭',
  UpscalePreset.efficiency: '效率档',
  UpscalePreset.quality: '质量档',
};

List<MenuItemButton> buildUpscaleMenuItems(
  BuildContext context, {
  required UpscalePreset value,
  required PlayerCapabilities capabilities,
  required Future<void> Function(UpscalePreset) onChanged,
  Widget Function(String label, bool isSelected)? buildLabel,
}) {
  final selected =
      capabilities.supportsUpscalePreset(value) ? value : UpscalePreset.off;
  final l10n = AppLocalizations.of(context);

  Future<void> select(UpscalePreset preset) async {
    try {
      await onChanged(preset);
    } catch (error) {
      if (!context.mounted) return;
      NotificationToast.show(
        error is UnsupportedError
            ? error.message ?? error.toString()
            : error.toString(),
        title: l10n.tip,
      );
    }
  }

  return UpscalePreset.values.map((preset) {
    final isSelected = selected == preset;
    final label = _upscaleLabels[preset]!;
    return MenuItemButton(
      onPressed: capabilities.supportsUpscalePreset(preset)
          ? () => select(preset)
          : null,
      trailingIcon:
          buildLabel == null && isSelected ? const Icon(Icons.check) : null,
      child: buildLabel?.call(label, isSelected) ?? Text(label),
    );
  }).toList();
}

class UpscaleButton extends StatelessWidget {
  final UpscalePreset value;
  final PlayerCapabilities capabilities;
  final Future<void> Function(UpscalePreset) onChanged;
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
      menuChildren: buildUpscaleMenuItems(
        context,
        value: value,
        capabilities: capabilities,
        onChanged: onChanged,
        buildLabel: (label, isSelected) => Container(
          height: 48,
          constraints: const BoxConstraints(minWidth: 112),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
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
