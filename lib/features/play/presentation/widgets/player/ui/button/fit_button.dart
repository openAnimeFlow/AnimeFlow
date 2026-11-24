import 'package:material_ui/material_ui.dart';

class FitButton extends StatelessWidget {
  const FitButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: const Icon(
          Icons.aspect_ratio_outlined,
          size: 25,
          color: Colors.white70,
        ),
      ),
    );
  }
}
