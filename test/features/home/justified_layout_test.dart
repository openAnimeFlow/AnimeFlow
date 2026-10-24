import 'dart:math';

import 'package:anime_flow/features/home/presentation/widgets/wallpapers/justified_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone rows have at least two images and merge an odd tail', () {
    for (final width in [296.0, 336.0, 406.0, 516.0]) {
      for (var count = 2; count <= 31; count++) {
        final ratios = List.generate(count, (i) => i.isEven ? 16 / 9 : 2 / 3);
        final rows = justifyImageRows(ratios,
            availableWidth: width,
            targetHeight: 180,
            minItemWidth: 120,
            minItemsPerRow: 2,
            maxItemsPerRow: 2);
        var cursor = 0;
        for (final row in rows) {
          expect(row.startIndex, cursor);
          expect(row.widths.length, greaterThanOrEqualTo(2));
          expect(row.widths.length, lessThanOrEqualTo(3));
          if (row.widths.length == 3) expect(row, same(rows.last));
          for (var i = 0; i < row.widths.length; i++) {
            expect(row.widths[i], greaterThan(0));
            expect(row.widths[i] / row.imageHeight,
                closeTo(ratios[cursor + i], 0.000001));
          }
          final occupied = row.widths.fold(0.0, (a, b) => a + b) +
              12 * (row.widths.length - 1);
          expect(occupied, lessThanOrEqualTo(width + 0.000001));
          cursor += row.widths.length;
        }
        expect(cursor, count);
      }
    }
  });

  test('borrows an image for a short tail when the preceding row has room', () {
    final rows = justifyImageRows(List.filled(4, 1),
        availableWidth: 336,
        targetHeight: 100,
        minItemsPerRow: 2,
        maxItemsPerRow: 3);
    expect(rows.map((row) => row.widths.length), [2, 2]);
  });

  test('phone rows keep portraits readable beside landscape images', () {
    for (final width in [296.0, 336.0, 366.0, 406.0, 516.0]) {
      final ratios = [
        2 / 3,
        2 / 3,
        16 / 9,
        2 / 3,
        16 / 9,
        2 / 3,
        2 / 3,
        16 / 9
      ];
      final rows = justifyImageRows(ratios,
          availableWidth: width,
          targetHeight: 180,
          minItemWidth: 120,
          maxItemsPerRow: 2);
      var nextIndex = 0;
      for (final row in rows) {
        expect(row.startIndex, nextIndex);
        expect(row.widths.length, lessThanOrEqualTo(2));
        for (var i = 0; i < row.widths.length; i++) {
          expect(row.widths[i], greaterThanOrEqualTo(120 - 0.000001));
          expect(row.widths[i] / row.imageHeight,
              closeTo(ratios[row.startIndex + i], 0.000001));
        }
        final occupied = row.widths.fold(0.0, (a, b) => a + b) +
            12 * (row.widths.length - 1);
        if (row != rows.last) expect(occupied, closeTo(width, 0.000001));
        expect(occupied, lessThanOrEqualTo(width + 0.000001));
        nextIndex += row.widths.length;
      }
      expect(nextIndex, ratios.length);
    }
  });

  test('minimum width applies to decoded ratios and the last portrait', () {
    final rows = justifyImageRows([0.45, 1.95, 0.52],
        availableWidth: 336,
        targetHeight: 180,
        minItemWidth: 120,
        maxItemsPerRow: 2);
    expect(
        rows
            .expand((row) => row.widths)
            .every((width) => width >= 120 - 0.000001),
        isTrue);
    final narrow = justifyImageRows([2 / 3],
            availableWidth: 100,
            targetHeight: 180,
            minItemWidth: 120,
            maxItemsPerRow: 2)
        .single;
    expect(narrow.widths.single, closeTo(100, 0.000001));
  });

  test(
      'mixed landscape and portrait images fill complete rows without cropping',
      () {
    final ratios = List.generate(40, (i) => i.isEven ? 16 / 9 : 2 / 3);
    for (final width in [120.0, 320.0, 600.0, 1200.0, 1800.0]) {
      final rows =
          justifyImageRows(ratios, availableWidth: width, targetHeight: 220);
      var cursor = 0;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        expect(row.startIndex, cursor);
        expect(row.imageHeight, greaterThan(0));
        final occupied = row.widths.fold(0.0, (a, b) => a + b) +
            12 * (row.widths.length - 1);
        expect(occupied, lessThanOrEqualTo(width + 0.000001));
        if (i < rows.length - 1) expect(occupied, closeTo(width, 0.000001));
        for (var j = 0; j < row.widths.length; j++) {
          expect(row.widths[j] / row.imageHeight,
              closeTo(ratios[cursor + j], 0.000001));
        }
        cursor += row.widths.length;
      }
      expect(cursor, ratios.length);
    }
  });

  test('short last row stays at target height instead of becoming oversized',
      () {
    final row =
        justifyImageRows([2 / 3], availableWidth: 1200, targetHeight: 220)
            .single;
    expect(row.imageHeight, 220);
    expect(row.widths.single, closeTo(220 * 2 / 3, 0.000001));
  });

  test('real decoded ratios replace estimates without losing order', () {
    final initial = justifyImageRows([16 / 9, 2 / 3, 16 / 9, 2 / 3],
        availableWidth: 800, targetHeight: 220);
    final measured = justifyImageRows([1, 0.8, 2.4, 0.7],
        availableWidth: 800, targetHeight: 220);
    expect(initial.first.widths.first, isNot(measured.first.widths.first));
    expect(measured.first.widths.first / measured.first.imageHeight,
        closeTo(1, 0.000001));
    expect(measured.expand((row) => row.widths).length, 4);
  });

  test('handles random dimensions, invalid estimates and empty viewports', () {
    expect(
        justifyImageRows([], availableWidth: 800, targetHeight: 220), isEmpty);
    expect(
        justifyImageRows([1], availableWidth: 0, targetHeight: 220), isEmpty);
    final random = Random(42);
    for (var sample = 0; sample < 100; sample++) {
      final width = 30.0 + random.nextDouble() * 2000;
      final ratios = List.generate(100, (_) => 0.1 + random.nextDouble() * 5);
      ratios.addAll([double.nan, 0, -1]);
      final rows =
          justifyImageRows(ratios, availableWidth: width, targetHeight: 220);
      expect(rows.expand((row) => row.widths).length, ratios.length);
      for (final row in rows) {
        expect(row.imageHeight.isFinite, isTrue);
        expect(row.imageHeight, greaterThan(0));
        expect(
            row.widths.every((value) => value.isFinite && value > 0), isTrue);
        final occupied = row.widths.fold(0.0, (a, b) => a + b) +
            12 * (row.widths.length - 1);
        expect(occupied, lessThanOrEqualTo(width + 0.000001));
      }
    }
  });
}
