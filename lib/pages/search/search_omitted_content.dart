import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/subject_card.dart';
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
              AnimeInfoRoute(
                id: searchData.id,
                name: searchData.nameCN.isEmpty ? searchData.name : searchData.nameCN,
                image: searchData.images.large,
              ).push(context);
            },
            child: SubjectCard(
              image: searchData.images.large,
              title: searchData.nameCN.isEmpty ? searchData.name : searchData.nameCN,
            )));
  }
}
