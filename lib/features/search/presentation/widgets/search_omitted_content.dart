import 'package:anime_flow/shared/models/bangumi/subject_item.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/shared/widgets/subject_card.dart';
import 'package:flutter/material.dart';

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
              AnimeInfoRoute.fromExtra(InfoRouteExtra(
                      id: searchData.id,
                      name: searchData.nameCN.isEmpty
                          ? searchData.name
                          : searchData.nameCN,
                      image: searchData.images.large))
                  .push(context);
            },
            child: SubjectCard(
              image: searchData.images.large,
              title: searchData.nameCN.isEmpty
                  ? searchData.name
                  : searchData.nameCN,
            )));
  }
}
