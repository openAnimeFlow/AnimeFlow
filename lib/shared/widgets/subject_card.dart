import 'package:anime_flow/shared/widgets/ranking.dart';
import 'package:material_ui/material_ui.dart';
import 'animation_network_image.dart';

class SubjectCard extends StatelessWidget {
  final String image;
  final String title;
  final int? rating;

  /// 封面共享元素动画的 Hero tag。
  ///
  /// 同一路由子树内必须唯一（例如同一张图片在同一页面出现多次会冲突）。
  /// 为 `null` 时不使用 Hero，避免 tag 重复导致的断言崩溃。
  final Object? heroTag;
  final bool isCoverAnimation;
  final BorderRadiusGeometry borderRadius;

  const SubjectCard({
    super.key,
    required this.image,
    required this.title,
    this.heroTag,
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

    final Widget cover = AnimationNetworkImage(
      borderRadius: borderRadius,
      url: image,
      fit: BoxFit.cover,
    );
    // 仅当提供了 tag 时才使用 Hero。Hero 要求同一路由子树内 tag 唯一，
    // 缺省 tag 或重复图片都会触发 "multiple heroes share the same tag" 断言。
    final Widget coverWithOptionalHero = isCoverAnimation && heroTag != null
        ? Hero(tag: heroTag!, child: cover)
        : cover;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            bottom: 0,
            right: 0,
            child: coverWithOptionalHero,
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
