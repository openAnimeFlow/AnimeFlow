// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FontRepoCdn)
final fontRepoCdnProvider = FontRepoCdnProvider._();

final class FontRepoCdnProvider extends $NotifierProvider<FontRepoCdn, bool> {
  FontRepoCdnProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'fontRepoCdnProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$fontRepoCdnHash();

  @$internal
  @override
  FontRepoCdn create() => FontRepoCdn();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$fontRepoCdnHash() => r'1c30e3e765b09079bfcaf74988f3a656f8d22107';

abstract class _$FontRepoCdn extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}

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

String _$fontHash() => r'f70d587f9cc59c1d0a2b45cc783974d33bd2900a';

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

@ProviderFor(DownloadedFontMetas)
final downloadedFontMetasProvider = DownloadedFontMetasProvider._();

final class DownloadedFontMetasProvider
    extends $NotifierProvider<DownloadedFontMetas, Map<String, FontItem>> {
  DownloadedFontMetasProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'downloadedFontMetasProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$downloadedFontMetasHash();

  @$internal
  @override
  DownloadedFontMetas create() => DownloadedFontMetas();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, FontItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, FontItem>>(value),
    );
  }
}

String _$downloadedFontMetasHash() =>
    r'f34a63f1a2920fbbf23674517a727b324609ff73';

abstract class _$DownloadedFontMetas extends $Notifier<Map<String, FontItem>> {
  Map<String, FontItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Map<String, FontItem>, Map<String, FontItem>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Map<String, FontItem>, Map<String, FontItem>>,
        Map<String, FontItem>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FontDownload)
final fontDownloadProvider = FontDownloadFamily._();

final class FontDownloadProvider
    extends $NotifierProvider<FontDownload, FontDownloadState> {
  FontDownloadProvider._(
      {required FontDownloadFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'fontDownloadProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$fontDownloadHash();

  @override
  String toString() {
    return r'fontDownloadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FontDownload create() => FontDownload();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FontDownloadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FontDownloadState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FontDownloadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fontDownloadHash() => r'1a9443728d00a28ee4d4ca70116321f5d5041fef';

final class FontDownloadFamily extends $Family
    with
        $ClassFamilyOverride<FontDownload, FontDownloadState, FontDownloadState,
            FontDownloadState, String> {
  FontDownloadFamily._()
      : super(
          retry: null,
          name: r'fontDownloadProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: false,
        );

  FontDownloadProvider call(
    String fontId,
  ) =>
      FontDownloadProvider._(argument: fontId, from: this);

  @override
  String toString() => r'fontDownloadProvider';
}

abstract class _$FontDownload extends $Notifier<FontDownloadState> {
  late final _$args = ref.$arg as String;
  String get fontId => _$args;

  FontDownloadState build(
    String fontId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FontDownloadState, FontDownloadState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<FontDownloadState, FontDownloadState>,
        FontDownloadState,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}

@ProviderFor(SelectedFont)
final selectedFontProvider = SelectedFontProvider._();

final class SelectedFontProvider
    extends $NotifierProvider<SelectedFont, String?> {
  SelectedFontProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedFontProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedFontHash();

  @$internal
  @override
  SelectedFont create() => SelectedFont();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedFontHash() => r'3ac8cfb0437ae1df60b501ba72478cfc53f097da';

abstract class _$SelectedFont extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String?, String?>, String?, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
