// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(myController)
final myControllerProvider = MyControllerProvider._();

final class MyControllerProvider
    extends $FunctionalProvider<MyController, MyController, MyController>
    with $Provider<MyController> {
  MyControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'myControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myControllerHash();

  @$internal
  @override
  $ProviderElement<MyController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MyController create(Ref ref) {
    return myController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MyController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MyController>(value),
    );
  }
}

String _$myControllerHash() => r'03e81a2f643b85f574e79b5954553fa48eb0cef6';
