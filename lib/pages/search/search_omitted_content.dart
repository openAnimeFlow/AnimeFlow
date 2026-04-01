import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
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
    final subjectBasicData = SubjectBasicData(
      id: searchData.id,
      name: searchData.nameCN ?? searchData.name,
      image: searchData.images.large,
    );
    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
            onTap: () {
              context.push(RouteName.animeInfo, extra: subjectBasicData);
            },
            child: SubjectCard(
              image: searchData.images.large,
              title: searchData.nameCN ?? searchData.name,
            )));
  }
}
