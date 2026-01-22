import 'package:flutter/material.dart';
import 'animation_network_image/animation_network_image.dart';

class SubjectCard extends StatelessWidget {
  final String image;
  final String title;

  const SubjectCard(
      {super.key,
      required this.image,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0,
            child: Hero(
              tag: 'subject_image$image',
              child: AnimationNetworkImage(
                url: image,
                fit: BoxFit.cover,
                useExternalHero: true,
              ),
            ),
          ),
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
                title,
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
    );
  }
}
