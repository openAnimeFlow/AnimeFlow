import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/shared/navigation/args/info_route_extra.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/shared/widgets/subject_card.dart';
import 'package:material_ui/material_ui.dart';

/// 简洁View（海报卡片）
class SearchOmittedContent extends StatelessWidget {
  final Subject searchData;

  const SearchOmittedContent({
    super.key,
    required this.searchData,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
            onTap: () {
              appNavigatorOf(context).openAnimeInfoFromExtra<void>(
                  context,
                  InfoRouteExtra(
                      id: searchData.id,
                      name: searchData.nameCN.isEmpty
                          ? searchData.name
                          : searchData.nameCN,
                      image: searchData.images.large));
            },
            child: SubjectCard(
              image: searchData.images.large,
              title: searchData.nameCN.isEmpty
                  ? searchData.name
                  : searchData.nameCN,
            )));
  }
}
