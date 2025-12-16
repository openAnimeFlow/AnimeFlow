import 'package:anime_flow/models/item/search_item.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///搜索内容
class SearchContentView extends StatelessWidget {
  final SearchData searchData;

  const SearchContentView({
    super.key,
    required this.searchData,
  });

  // 内容项固定高度
  static const double itemHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    bool isDark = Get.isDarkMode;
    final disabledColor = Get.theme.disabledColor;
    const textFontWeight = FontWeight.w600;

    return SizedBox(
      height: itemHeight,
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
                const Spacer(),
                Text(
                  searchData.info,
                  style:
                      const TextStyle(fontSize: 10, fontWeight: textFontWeight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5.5, vertical: 1),
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
                              blurRadius: 1,
                            )
                          ],
                        ),
                      ),
                    ),
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
      ),
    );
  }
}
