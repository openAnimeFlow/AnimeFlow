import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
              context.push(RouteName.animeInfo);
            },
            child: SubjectCard(
              image: searchData.images.large,
              title: searchData.nameCN ?? searchData.name,
            )));
  }
}
