// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A null season requests the current season, shared by the home and calendar pages.

@ProviderFor(calendar)
final calendarProvider = CalendarFamily._();

/// A null season requests the current season, shared by the home and calendar pages.

final class CalendarProvider extends $FunctionalProvider<
        AsyncValue<CalendarWithTags>,
        CalendarWithTags,
        Stream<CalendarWithTags>>
    with $FutureModifier<CalendarWithTags>, $StreamProvider<CalendarWithTags> {
  /// A null season requests the current season, shared by the home and calendar pages.
  CalendarProvider._(
      {required CalendarFamily super.from,
      required CalendarSeason? super.argument})
      : super(
          retry: null,
          name: r'calendarProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$calendarHash();

  @override
  String toString() {
    return r'calendarProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<CalendarWithTags> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<CalendarWithTags> create(Ref ref) {
    final argument = this.argument as CalendarSeason?;
    return calendar(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CalendarProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarHash() => r'a483fc7f2e6a55baa45b3a17f28787b800c1366b';

/// A null season requests the current season, shared by the home and calendar pages.

final class CalendarFamily extends $Family
    with $FunctionalFamilyOverride<Stream<CalendarWithTags>, CalendarSeason?> {
  CalendarFamily._()
      : super(
          retry: null,
          name: r'calendarProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// A null season requests the current season, shared by the home and calendar pages.

  CalendarProvider call(
    CalendarSeason? season,
  ) =>
      CalendarProvider._(argument: season, from: this);

  @override
  String toString() => r'calendarProvider';
}
