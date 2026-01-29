import 'package:anime_flow/widget/ranking.dart';
import 'package:flutter/material.dart';
import 'animation_network_image/animation_network_image.dart';

class SubjectCard extends StatelessWidget {
  final String image;
  final String title;
  final int? rating;
  final bool isCoverAnimation;
  final BorderRadiusGeometry borderRadius;

  const SubjectCard({
    super.key,
    required this.image,
    required this.title,
    this.rating,
    this.isCoverAnimation = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(15.0)),
  });

  double _getFontSizeByScreen(double screenWidth) {
    if (screenWidth < 360) {
      return 12;
    } else if (screenWidth < 480) {
      return 14;
    } else if (screenWidth < 720) {
      return 15;
    } else {
      return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = _getFontSizeByScreen(screenWidth);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0,
            child: isCoverAnimation
                ? Hero(
                    tag: 'subject_image$image',
                    child: AnimationNetworkImage(
                      borderRadius: borderRadius,
                      url: image,
                      fit: BoxFit.cover,
                      useExternalHero: true,
                    ),
                  )
                : AnimationNetworkImage(
                    borderRadius: borderRadius,
                    url: image,
                    fit: BoxFit.cover,
                    useExternalHero: true,
                  ),
          ),
          if (title.isNotEmpty)
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
                      Colors.black87,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (rating != null && rating! > 0)
            Positioned(
              top: 0,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: RankingView(ranking: rating!),
              ),
            ),
        ],
      ),
    );
  }
}
