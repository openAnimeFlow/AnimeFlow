// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shaders_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 将 assets 中的 GLSL 拷贝到应用支持目录，供播放器超分使用。

@ProviderFor(shadersDirectory)
final shadersDirectoryProvider = ShadersDirectoryProvider._();

/// 将 assets 中的 GLSL 拷贝到应用支持目录，供播放器超分使用。

final class ShadersDirectoryProvider extends $FunctionalProvider<
        AsyncValue<Directory>, Directory, FutureOr<Directory>>
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// 将 assets 中的 GLSL 拷贝到应用支持目录，供播放器超分使用。
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

String _$shadersDirectoryHash() => r'd690e3524ac52f4913ceebe0fa982d3c431ea942';
