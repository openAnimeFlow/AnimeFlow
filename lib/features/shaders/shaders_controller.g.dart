// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shaders_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shadersDirectory)
final shadersDirectoryProvider = ShadersDirectoryProvider._();

final class ShadersDirectoryProvider extends $FunctionalProvider<
        AsyncValue<Directory>, Directory, FutureOr<Directory>>
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  ShadersDirectoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'shadersDirectoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$shadersDirectoryHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return shadersDirectory(ref);
  }
}

String _$shadersDirectoryHash() => r'a91017d76e9e4d7ede40e0d4a430770bf6513085';
