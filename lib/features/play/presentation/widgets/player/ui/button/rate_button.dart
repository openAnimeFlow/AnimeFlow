import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class RateButton extends StatelessWidget {
  const RateButton({
    super.key,
    required this.value,
    required this.onPressed,
  });

  final double value;
  final VoidCallback? onPressed;

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
    final l10n = AppLocalizations.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(value == 1.0 ? l10n.playbackRate : '${value}x'),
    );
  }
}
