// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchPageController)
final searchPageControllerProvider = SearchPageControllerProvider._();

final class SearchPageControllerProvider
    extends $NotifierProvider<SearchPageController, SearchPageState> {
  SearchPageControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchPageControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchPageControllerHash();

  @$internal
  @override
  SearchPageController create() => SearchPageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchPageState>(value),
    );
  }
}

String _$searchPageControllerHash() =>
    r'7d121e0a5045bfbb3c25041fb53729fd0f2aab8c';

abstract class _$SearchPageController extends $Notifier<SearchPageState> {
  SearchPageState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchPageState, SearchPageState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SearchPageState, SearchPageState>,
        SearchPageState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
