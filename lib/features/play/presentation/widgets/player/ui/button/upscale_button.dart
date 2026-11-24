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
  void Function(VoidCallback)? onActivate,
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
    void apply() => select(preset);
    return MenuItemButton(
      closeOnActivate: onActivate == null,
      onPressed: capabilities.supportsUpscalePreset(preset)
          ? onActivate == null
              ? apply
              : () => onActivate(apply)
          : null,
      trailingIcon:
          buildLabel == null && isSelected ? const Icon(Icons.check) : null,
      child: buildLabel?.call(label, isSelected) ?? Text(label),
    );
  }).toList();
}

class UpscaleButton extends StatelessWidget {
  const UpscaleButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      child: const Text('4k'),
    );
  }
}
