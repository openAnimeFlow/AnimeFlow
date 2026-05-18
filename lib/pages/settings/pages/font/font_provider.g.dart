// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Font)
final fontProvider = FontProvider._();

final class FontProvider extends $AsyncNotifierProvider<Font, List<FontItem>> {
  FontProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'fontProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$fontHash();

  @$internal
  @override
  Font create() => Font();
}

String _$fontHash() => r'6dee13154c65009f66f133a031ae9edcc8adec8f';

abstract class _$Font extends $AsyncNotifier<List<FontItem>> {
  FutureOr<List<FontItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<FontItem>>, List<FontItem>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<FontItem>>, List<FontItem>>,
        AsyncValue<List<FontItem>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
