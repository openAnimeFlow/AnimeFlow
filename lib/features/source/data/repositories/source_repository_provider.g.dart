// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sourceRepository)
final sourceRepositoryProvider = SourceRepositoryProvider._();

final class SourceRepositoryProvider extends $FunctionalProvider<
    SourceRepository,
    SourceRepository,
    SourceRepository> with $Provider<SourceRepository> {
  SourceRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sourceRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sourceRepositoryHash();

  @$internal
  @override
  $ProviderElement<SourceRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SourceRepository create(Ref ref) {
    return sourceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SourceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SourceRepository>(value),
    );
  }
}

String _$sourceRepositoryHash() => r'ad2db5aec9a6182ef1cadd1e6ea3c515de427536';
