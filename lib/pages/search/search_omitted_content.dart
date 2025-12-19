import 'package:anime_flow/models/item/search_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

/// 简洁View（海报卡片）
class SearchOmittedContent extends StatelessWidget {
  final SearchData searchData;

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
            Get.toNamed("/anime_detail", arguments: subjectBasicData);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimationNetworkImage(
                  url: searchData.images.large,
                  fit: BoxFit.cover,
                ),
              ),
              // 底部渐变标题
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    searchData.nameCN ?? searchData.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
