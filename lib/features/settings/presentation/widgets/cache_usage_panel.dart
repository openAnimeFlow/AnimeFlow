import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/cache/cache_usage_service.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

const _colors = [
  Color(0xFF55A9ED),
  Color(0xFF3485E4),
  Color(0xFF9B7BE8),
  Color(0xFFFF9549),
  Color(0xFF50B86B),
  Color(0xFFE2689A),
  Color(0xFF27B6B1),
];

String cacheCategoryLabel(CacheCategory category, AppLocalizations l10n) =>
    switch (category) {
      CacheCategory.images => l10n.imageCacheLabel,
      CacheCategory.animeInfo => l10n.animeInfoCacheLabel,
      CacheCategory.characters => l10n.charactersTitle,
      CacheCategory.subjectMetadata =>
        '${l10n.producersTitle} / ${l10n.relatedTitle}',
      CacheCategory.subjectComments => l10n.commentsTitle,
      CacheCategory.popularAnime => l10n.popularAnimeTitle,
      CacheCategory.calendar => l10n.todayBroadcast,
    };

/// 图表按已选缓存重新分配扇区，选择变化时平滑收缩或扩展。
class CacheUsagePanel extends StatelessWidget {
  const CacheUsagePanel(
      {super.key,
      required this.usage,
      required this.selected,
      required this.onSelectionChanged,
      required this.onClear,
      this.loading = false,
      this.refreshToken,
      this.busy = false,
      this.clearing = false});

  final CacheUsage usage;
  final Set<CacheCategory> selected;
  final ValueChanged<Set<CacheCategory>> onSelectionChanged;
  final VoidCallback onClear;
  final bool loading;
  final Object? refreshToken;
  final bool busy;
  final bool clearing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedBytes =
        selected.fold<int>(0, (sum, key) => sum + (usage.sizes[key] ?? 0));
    final allowHorizontal = MediaQuery.textScalerOf(context).scale(14) < 23;
    final ring = RepaintBoundary(
        child: CacheRingChart(
            usage: usage,
            selected: selected,
            loading: loading,
            refreshToken: refreshToken));
    final caption = Text(
        '${l10n.cacheUsageTitle} · ${Utils.formatBytes(usage.totalBytes)}',
        textAlign: TextAlign.center,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));
    final legend = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
                onPressed: busy
                    ? null
                    : () => onSelectionChanged(
                        selected.length == CacheCategory.values.length
                            ? {}
                            : CacheCategory.values.toSet()),
                child: Text(selected.length == CacheCategory.values.length
                    ? l10n.cacheDeselectAll
                    : l10n.cacheSelectAll))),
        for (final category in CacheCategory.values)
          _categoryRow(context, category, l10n, selectedBytes),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('clear-selected-cache'),
              onPressed: busy || selectedBytes == 0 ? null : onClear,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 12)),
              child: Text(
                  clearing
                      ? l10n.imageCacheClearing
                      : '${l10n.clearSelectedCache}  ${Utils.formatBytes(selectedBytes)}',
                  textAlign: TextAlign.center),
            )),
      ],
    );
    // Resize only the layout wrappers; keep the chart and controls mounted.
    return LayoutBuilder(builder: (context, constraints) {
      final horizontal = constraints.maxWidth >= 760 && allowHorizontal;
      return Flex(
        key: const ValueKey('cache-layout'),
        direction: horizontal ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: horizontal ? 1 : 0,
            fit: FlexFit.tight,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox.square(
                dimension:
                    horizontal ? 300 : math.min(260, constraints.maxWidth),
                child: ring,
              ),
              const SizedBox(height: 12),
              caption,
            ]),
          ),
          SizedBox(width: horizontal ? 28 : 0, height: horizontal ? 0 : 24),
          Flexible(flex: horizontal ? 1 : 0, fit: FlexFit.tight, child: legend),
        ],
      );
    });
  }

  Widget _categoryRow(BuildContext context, CacheCategory category,
      AppLocalizations l10n, int selectedBytes) {
    final bytes = usage.sizes[category] ?? 0;
    final percent = selectedBytes == 0 ? 0.0 : bytes / selectedBytes * 100;
    final percentText =
        percent > 0 && percent < 1 ? '<1%' : '${percent.toStringAsFixed(0)}%';
    final color = _colors[category.index];
    final checked = selected.contains(category);
    void toggle() {
      final next = {...selected};
      checked ? next.remove(category) : next.add(category);
      onSelectionChanged(next);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: busy ? null : toggle,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Checkbox(
              key: ValueKey('cache-${category.name}'),
              value: checked,
              onChanged: busy ? null : (_) => toggle(),
              shape: const CircleBorder(),
              activeColor: color,
              checkColor: Colors.white,
              side: BorderSide(color: color, width: 2),
              semanticLabel:
                  '${cacheCategoryLabel(category, l10n)} ${Utils.formatBytes(bytes)}',
            ),
            Expanded(
                child: Text.rich(TextSpan(children: [
              TextSpan(text: cacheCategoryLabel(category, l10n)),
              if (checked)
                TextSpan(
                    text: '  $percentText',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]))),
            const SizedBox(width: 8),
            Text(Utils.formatBytes(bytes),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? color
                        : Color.lerp(color, Colors.black, 0.25),
                    fontWeight: FontWeight.w600)),
          ])),
    );
  }
}

class CacheRingChart extends StatefulWidget {
  const CacheRingChart(
      {super.key,
      required this.usage,
      required this.selected,
      this.loading = false,
      this.refreshToken});
  final CacheUsage usage;
  final Set<CacheCategory> selected;
  final bool loading;
  final Object? refreshToken;

  @override
  State<CacheRingChart> createState() => _CacheRingChartState();
}

class _CacheRingChartState extends State<CacheRingChart> {
  int? _activeIndex;

  void _activate(int? index) {
    if (_activeIndex != index) setState(() => _activeIndex = index);
  }

  @override
  void didUpdateWidget(CacheRingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final active = _activeIndex;
    if (widget.loading ||
        widget.refreshToken != oldWidget.refreshToken ||
        (active != null &&
            (!widget.selected.contains(CacheCategory.values[active]) ||
                (widget.usage.sizes[CacheCategory.values[active]] ?? 0) <=
                    0))) {
      _activeIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = [
      for (final key in CacheCategory.values)
        !widget.loading && widget.selected.contains(key)
            ? (widget.usage.sizes[key] ?? 0).toDouble()
            : 0.0
    ];
    final target = _ChartValues(sizes, sizes.any((size) => size > 0) ? 1 : 0);
    return TweenAnimationBuilder<_ChartValues>(
      // Replay after each measurement, even when the measured size is unchanged.
      // Resizing and selection changes preserve the current animation state.
      key: ValueKey((widget.refreshToken, widget.loading)),
      tween: _ChartTween(
          begin: _ChartValues(List.filled(CacheCategory.values.length, 0), 0),
          end: target),
      duration: widget.loading || MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      builder: (context, values, _) => TweenAnimationBuilder<_ChartValues>(
        tween: _ChartTween(
            begin: _ChartValues(List.filled(CacheCategory.values.length, 0), 0),
            end: _ChartValues([
              for (var i = 0; i < CacheCategory.values.length; i++)
                i == _activeIndex ? 1 : 0,
            ], 0)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, emphasis, _) => LayoutBuilder(
          builder: (context, constraints) {
            final painter = _RingPainter(
                values,
                Theme.of(context).colorScheme.surfaceContainerHighest,
                Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
                emphasis.sizes);
            int? categoryAt(Offset position) => widget.loading
                ? null
                : painter.categoryAt(position, constraints.biggest);
            return MouseRegion(
              cursor: _activeIndex == null
                  ? MouseCursor.defer
                  : SystemMouseCursors.click,
              onEnter: (event) => _activate(categoryAt(event.localPosition)),
              onHover: (event) => _activate(categoryAt(event.localPosition)),
              onExit: (_) => _activate(null),
              child: TapRegion(
                onTapOutside: (_) => _activate(null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final index = categoryAt(details.localPosition);
                    _activate(details.kind != PointerDeviceKind.mouse &&
                            index == _activeIndex
                        ? null
                        : index);
                  },
                  child: CustomPaint(
                    painter: painter,
                    child: Center(
                      child: FractionallySizedBox(
                          widthFactor: 0.52,
                          child: _centerContent(context, values)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _centerContent(BuildContext context, _ChartValues values) {
    final l10n = AppLocalizations.of(context);
    final total = values.sizes.fold<double>(0, (sum, size) => sum + size);
    final active = _activeIndex;
    final bytes = active == null ? total : values.sizes[active];
    final formatted =
        Utils.formatBytes(bytes.round(), fractionDigits: 0).split(' ');
    final label = active == null
        ? l10n.cacheSelectedSize
        : cacheCategoryLabel(CacheCategory.values[active], l10n);
    final percent = total > 0 ? bytes / total * 100 : 0.0;
    final percentText =
        percent > 0 && percent < 1 ? '<1%' : '${percent.toStringAsFixed(0)}%';
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: active != null,
      label: widget.loading ? l10n.imageCacheCalculating : label,
      value: widget.loading
          ? null
          : '${formatted.join(' ')}${active == null ? '' : ' · $percentText'}',
      child: ExcludeSemantics(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.loading) ...[
            const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: 12),
            Text(l10n.imageCacheCalculating,
                textAlign: TextAlign.center, style: textTheme.bodySmall),
          ] else ...[
            if (active != null) ...[
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge),
              const SizedBox(height: 6),
            ],
            FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                    TextSpan(text: '${formatted.first} ', children: [
                      TextSpan(
                          text: formatted.last, style: textTheme.titleMedium),
                    ]),
                    maxLines: 1,
                    softWrap: false,
                    style: textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w500))),
            const SizedBox(height: 6),
            Text(active == null ? label : percentText,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ]),
      ),
    );
  }
}

class _ChartValues {
  const _ChartValues(this.sizes, this.presence);
  final List<double> sizes;
  final double presence;

  @override
  bool operator ==(Object other) =>
      other is _ChartValues &&
      presence == other.presence &&
      listEquals(sizes, other.sizes);

  @override
  int get hashCode => Object.hash(presence, Object.hashAll(sizes));
}

class _ChartTween extends Tween<_ChartValues> {
  _ChartTween({required super.begin, required super.end});
  @override
  _ChartValues lerp(double t) => _ChartValues([
        for (var i = 0; i < end!.sizes.length; i++)
          begin!.sizes[i] + (end!.sizes[i] - begin!.sizes[i]) * t
      ], begin!.presence + (end!.presence - begin!.presence) * t);
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.values, this.trackColor, this.labelStyle, this.emphasis);
  final _ChartValues values;
  final Color trackColor;
  final TextStyle labelStyle;
  final List<double> emphasis;

  int? categoryAt(Offset position, Size size) {
    for (final segment in _segments(size)) {
      if (segment.path.contains(position)) return segment.index;
    }
    return null;
  }

  Iterable<
      ({
        int index,
        double fraction,
        double angle,
        double radius,
        double scale,
        Path path
      })> _segments(Size size) sync* {
    final total = values.sizes.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0 || size.isEmpty) return;
    final center = size.center(Offset.zero);
    var start = -math.pi / 2;
    for (var i = 0; i < values.sizes.length; i++) {
      if (values.sizes[i] <= 0) continue;
      final fraction = values.sizes[i] / total;
      final sweep = fraction * math.pi * 2 * values.presence;
      final gap = math.min(0.025, sweep * 0.18) *
          ((1 - fraction) / 0.05).clamp(0.0, 1.0);
      if (sweep > 0) {
        final scale = 1 + 0.045 * emphasis[i];
        // Grow outward while keeping the inner edge under the pointer stable.
        final growth = size.shortestSide * 0.021 * emphasis[i];
        final radius = size.shortestSide * 0.40 + growth / 2;
        final thickness = size.shortestSide * 0.145 + growth;
        yield (
          index: i,
          fraction: fraction,
          angle: start + sweep / 2,
          radius: radius,
          scale: scale,
          path: _roundedSegment(
              center, radius, thickness, start + gap / 2, sweep - gap)
        );
      }
      start += sweep;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.40;
    final thickness = size.shortestSide * 0.145;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    final total = values.sizes.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) {
      canvas.drawCircle(center, radius, paint..color = trackColor);
      return;
    }
    paint.style = PaintingStyle.fill;
    for (final segment in _segments(size)) {
      canvas.drawPath(segment.path, paint..color = _colors[segment.index]);
      if (segment.fraction >= 0.075 && values.presence > 0.7) {
        final label = TextPainter(
            text: TextSpan(
                text: '${(segment.fraction * 100).round()}%',
                style: labelStyle.copyWith(
                    color: Colors.white,
                    fontSize: size.shortestSide * 0.045 * segment.scale,
                    fontWeight: FontWeight.w600)),
            textDirection: TextDirection.ltr)
          ..layout();
        final angle = segment.angle;
        final position =
            center + Offset(math.cos(angle), math.sin(angle)) * segment.radius;
        label.paint(
            canvas, position - Offset(label.width / 2, label.height / 2));
      }
    }
  }

  Path _roundedSegment(Offset center, double radius, double thickness,
      double start, double sweep) {
    final outer = radius + thickness / 2;
    final inner = radius - thickness / 2;
    if (sweep >= math.pi * 2 - 0.000001) {
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: center, radius: outer))
        ..addOval(Rect.fromCircle(center: center, radius: inner));
    }
    // Scale corners down for tiny slices so every category keeps its own space.
    final corner = math.min(thickness * 0.18, inner * sweep / 4);
    final outerInset = corner / outer;
    final innerInset = corner / inner;
    final end = start + sweep;
    Offset point(double r, double angle) =>
        center + Offset(math.cos(angle), math.sin(angle)) * r;
    final outerEnd = point(outer, end);
    final endEdge = point(outer - corner, end);
    final innerEdge = point(inner + corner, end);
    final innerEnd = point(inner, end);
    final innerArcEnd = point(inner, end - innerInset);
    final innerStart = point(inner, start);
    final startEdge = point(inner + corner, start);
    final outerEdge = point(outer - corner, start);
    final outerStart = point(outer, start);
    final outerArcStart = point(outer, start + outerInset);
    return Path()
      ..arcTo(Rect.fromCircle(center: center, radius: outer),
          start + outerInset, sweep - 2 * outerInset, true)
      ..quadraticBezierTo(outerEnd.dx, outerEnd.dy, endEdge.dx, endEdge.dy)
      ..lineTo(innerEdge.dx, innerEdge.dy)
      ..quadraticBezierTo(
          innerEnd.dx, innerEnd.dy, innerArcEnd.dx, innerArcEnd.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: inner), end - innerInset,
          -(sweep - 2 * innerInset), false)
      ..quadraticBezierTo(
          innerStart.dx, innerStart.dy, startEdge.dx, startEdge.dy)
      ..lineTo(outerEdge.dx, outerEdge.dy)
      ..quadraticBezierTo(
          outerStart.dx, outerStart.dy, outerArcStart.dx, outerArcStart.dy)
      ..close();
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      values != oldDelegate.values ||
      trackColor != oldDelegate.trackColor ||
      labelStyle != oldDelegate.labelStyle ||
      !listEquals(emphasis, oldDelegate.emphasis);
}
