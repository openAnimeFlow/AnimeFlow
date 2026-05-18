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

String _$fontHash() => r'd5d0fb413d651b87f3c3544b4dafe6d63d7ab4d6';

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
