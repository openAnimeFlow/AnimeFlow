import 'package:animation_network_image/animation_network_image.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:anime_flow/widget/ranking.dart';
import 'package:anime_flow/widget/star.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart'
    show SubjectBasicData;

class InfoAppbarView extends StatelessWidget {
  final bool isPinned;
  final SubjectBasicData subjectBasicData;
  final SubjectsItem subjectsItem;

  const InfoAppbarView({
    super.key,
    required this.subjectsItem,
    required this.isPinned,
    required this.subjectBasicData,
  });

  @override
  Widget build(BuildContext context) {
    final data = subjectsItem;
    return Row(
      children: [
        IconButton(
          padding: const EdgeInsets.all(0),
          iconSize: 25,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Get.back();
          },
        ),
        AnimatedOpacity(
            opacity: isPinned ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: AnimationNetworkImage(
                      width: 26,
                      height: 36,
                      fit: BoxFit.cover,
                      url: subjectBasicData.image),
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectBasicData.name,
                      style: const TextStyle(fontSize: 15),
                    ),
                    Row(
                      children: [
                        RankingView(ranking: data.rating.rank),
                        StarView(score: data.rating.score),
                        const SizedBox(width: 5),
                        Text(data.rating.score.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold))
                      ],
                    )
                  ],
                )
              ],
            )),
      ],
    );
  }
}
