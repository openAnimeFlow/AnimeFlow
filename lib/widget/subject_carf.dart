import 'package:anime_flow/models/item/bangumi/subject_item.dart';
import 'package:anime_flow/models/item/subject_basic_data_item.dart';
import 'package:anime_flow/routes/index.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import 'animation_network_image/animation_network_image.dart';

class SubjectCarfView extends StatelessWidget {
  final Subject subject;
  const SubjectCarfView({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final subjectBasicData = SubjectBasicData(
      id: subject.id,
      name: subject.nameCN ?? subject.name,
      image: subject.images.large,
    );
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(RouteName.animeInfo, arguments: subjectBasicData);
        },
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Stack(
          children: [
            Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                right: 0,
                child: AnimationNetworkImage(
                  url: subject.images.large,
                  fit: BoxFit.cover,
                )),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black38,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  subject.nameCN ?? subject.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
