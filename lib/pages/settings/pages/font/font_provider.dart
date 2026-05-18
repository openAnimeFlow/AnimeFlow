import 'package:anime_flow/http/requests/github_request.dart';
import 'package:anime_flow/models/item/font_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_provider.g.dart';

@riverpod
class Font extends _$Font {
  @override
  Future<List<FontItem>> build() async {
    return getFontList();
  }

  /// 获取字体列表
  Future<List<FontItem>> getFontList({bool useCdn = true}) async {
    return GithubRequest.getRepoFonts(useCdn: useCdn);
  }

  Future<void> reload({bool useCdn = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => getFontList(useCdn: useCdn));
  }

  Future<List<int>> downloadFont(String fontUrl, {bool useCdn = true}) async {
    return await GithubRequest.downloadFont(fontUrl, useCdn: useCdn);
  }
}
