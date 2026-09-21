// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_online_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subjectOnlineCount)
final subjectOnlineCountProvider = SubjectOnlineCountFamily._();

final class SubjectOnlineCountProvider extends $FunctionalProvider<
        AsyncValue<OnlineCount>, OnlineCount, Stream<OnlineCount>>
    with $FutureModifier<OnlineCount>, $StreamProvider<OnlineCount> {
  SubjectOnlineCountProvider._(
      {required SubjectOnlineCountFamily super.from,
      required int super.argument})
      : super(
          retry: null,
          name: r'subjectOnlineCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$subjectOnlineCountHash();

  @override
  String toString() {
    return r'subjectOnlineCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OnlineCount> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<OnlineCount> create(Ref ref) {
    final argument = this.argument as int;
    return subjectOnlineCount(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SubjectOnlineCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subjectOnlineCountHash() =>
    r'50b4d3d70763cdbaba78dd0d4e4411a786209d8b';

final class SubjectOnlineCountFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OnlineCount>, int> {
  SubjectOnlineCountFamily._()
      : super(
          retry: null,
          name: r'subjectOnlineCountProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SubjectOnlineCountProvider call(
    int subjectId,
  ) =>
      SubjectOnlineCountProvider._(argument: subjectId, from: this);

  @override
  String toString() => r'subjectOnlineCountProvider';
}
