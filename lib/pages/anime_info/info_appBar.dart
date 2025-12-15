import 'package:anime_flow/models/item/hot_item.dart';
import 'package:anime_flow/models/item/subjects_item.dart';
import 'package:anime_flow/widget/anime_detail/star.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class InfoAppbarView extends StatelessWidget {
  final bool isPinned;
  final Subject subject;
  final SubjectsItem subjectsItem;

  const InfoAppbarView({
    super.key,
    required this.subject,
    required this.subjectsItem,
    required this.isPinned,
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
                      url: subject.images.common),
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.nameCN ?? subject.name,
                      style: const TextStyle(fontSize: 15),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            data.rating.rank.toString(),
                            style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
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
