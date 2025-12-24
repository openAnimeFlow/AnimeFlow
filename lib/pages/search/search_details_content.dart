import 'package:anime_flow/models/item/bangumi/search_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///详情View
class SearchDetailsContentView extends StatelessWidget {
  final SearchData searchData;
  final double itemHeight;

  const SearchDetailsContentView({
    super.key,
    required this.searchData,
    required this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    final subjectBasicData = SubjectBasicData(
      id: searchData.id,
      name: searchData.nameCN ?? searchData.name,
      image: searchData.images.large,
    );

    final disabledColor = Get.theme.disabledColor;
    const textFontWeight = FontWeight.w600;

    return SizedBox(
        height: itemHeight,
        child: InkWell(
            onTap: () {
              Get.toNamed(RouteName.animeInfo, arguments: subjectBasicData);
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: itemHeight,
                    width: 110,
                    child: AnimationNetworkImage(
                      url: searchData.images.large,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        searchData.nameCN ?? searchData.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        searchData.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: textFontWeight,
                          color: disabledColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        searchData.info,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: textFontWeight),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          RankingView(
                              ranking: searchData.rating.total,
                              fontWeight: textFontWeight,
                              fontSize: 8),
                          StarView(score: searchData.rating.score),
                          Text(
                            searchData.rating.score.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: textFontWeight,
                              color: disabledColor,
                            ),
                          ),
                          Text(
                            '(${searchData.rating.total}人评分)',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: textFontWeight,
                              color: disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )));
  }
}
