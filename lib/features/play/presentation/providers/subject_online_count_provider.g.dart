// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_online_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subjectOnlineCount)
final subjectOnlineCountProvider = SubjectOnlineCountProvider._();

final class SubjectOnlineCountProvider extends $FunctionalProvider<
        AsyncValue<OnlineCount>, OnlineCount, Stream<OnlineCount>>
    with $FutureModifier<OnlineCount>, $StreamProvider<OnlineCount> {
  SubjectOnlineCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'subjectOnlineCountProvider',
          isAutoDispose: true,
          dependencies: <ProviderOrFamily>[playExtraProvider],
          $allTransitiveDependencies: <ProviderOrFamily>[
            SubjectOnlineCountProvider.$allTransitiveDependencies0,
          ],
        );

  static final $allTransitiveDependencies0 = playExtraProvider;

  @override
  String debugGetCreateSourceHash() => _$subjectOnlineCountHash();

  @$internal
  @override
  $StreamProviderElement<OnlineCount> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<OnlineCount> create(Ref ref) {
    return subjectOnlineCount(ref);
  }
}

String _$subjectOnlineCountHash() =>
    r'01acef47c8d508fc90bcd8c56f026385044ad974';
