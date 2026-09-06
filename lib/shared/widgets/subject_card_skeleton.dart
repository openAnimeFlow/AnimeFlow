import 'package:anime_flow/core/utils/system_util.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SubjectCardSkeleton extends StatelessWidget {
  const SubjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = SystemUtil.isDarkTheme(context);
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final containerColor = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Theme.of(context).colorScheme.surface;

    return Stack(
      children: [
        Positioned.fill(
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
