// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(My)
final myProvider = MyProvider._();

final class MyProvider extends $NotifierProvider<My, MyState> {
  MyProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'myProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myHash();

  @$internal
  @override
  My create() => My();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MyState>(value),
    );
  }
}

String _$myHash() => r'769f6db584ee4f55678fe4a8f250d5c26ed5ee52';

abstract class _$My extends $Notifier<MyState> {
  MyState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MyState, MyState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<MyState, MyState>, MyState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
