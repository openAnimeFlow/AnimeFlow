import 'package:anime_flow/models/item/search_item.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///搜索内容
class ContentView extends StatelessWidget {
  final SearchData searchData;

  const ContentView({
    super.key,
    required this.searchData,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Get.isDarkMode;
    final disabledColor = Get.theme.disabledColor;
    const textFontWeight = FontWeight.w600;
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: AnimationNetworkImage(
                  url: searchData.images.large,
                  fit: BoxFit.cover,
                ),
              )),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    searchData.nameCN ?? searchData.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    searchData.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
                ]),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: isDark ? disabledColor : Colors.amber[400],
                      ),
                      child: Text(
                        searchData.rating.total.toString(),
                        style: const TextStyle(
                            fontSize: 8,
                            fontWeight: textFontWeight,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: Colors.black,
                                  offset: Offset(0.5, 0.5),
                                  blurRadius: 1)
                            ]
                        ),
                      ),
                    ),
                    StarView(
                      score: searchData.rating.score,
                    ),
                    Text(searchData.rating.score.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: textFontWeight,
                            color: disabledColor)),
                    Text(
                      '(${searchData.rating.total})人评论',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: textFontWeight,
                          color: disabledColor),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
