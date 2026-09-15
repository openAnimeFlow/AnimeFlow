import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class NoMoreIndicator extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const NoMoreIndicator({
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          const Expanded(child: _HorizontalRuleIcons()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l10n.noMore,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const Expanded(child: _HorizontalRuleIcons()),
        ],
      ),
    );
  }
}

class _HorizontalRuleIcons extends StatelessWidget {
  const _HorizontalRuleIcons();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const iconSize = 24.0;
        const spacing = 4.0;
        const iconWidth = iconSize + spacing;
        final iconCount = (constraints.maxWidth / iconWidth).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            iconCount > 0 ? iconCount : 1,
            (index) => Padding(
              padding: EdgeInsets.only(
                right: index < iconCount - 1 ? spacing : 0,
              ),
              child: Icon(
                Icons.horizontal_rule_rounded,
                size: iconSize,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
