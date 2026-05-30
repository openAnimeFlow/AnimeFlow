import 'package:anime_flow/crawler/itme/bgm_user_page_item.dart';
import 'package:flutter/material.dart';

class UserSpaceStatisticsSection extends StatelessWidget {
  final BgmUserPageItem userPageItem;

  const UserSpaceStatisticsSection(
      {super.key,  required this.userPageItem});

  BoxDecoration _cardDecoration(int index) {
    switch (index) {
      case 0:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.15, 0.48, 0.73],
            colors: [
              const Color(0xFFFF6B9D).withValues(alpha: 0.8),
              const Color(0xFFFF6B9D).withValues(alpha: 0.9),
              const Color(0xFFFF6B9D),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        );
      case 1:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.15, 0.48, 0.73],
            colors: [
              const Color(0xFF70B941).withValues(alpha: 0.8),
              const Color(0xFF70B941).withValues(alpha: 0.9),
              const Color(0xFF70B941),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF70B941).withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        );
      case 2:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.15, 0.48, 0.73],
            colors: [
              const Color(0xFF4FC3F7).withValues(alpha: 0.7),
              const Color(0xFF4FC3F7).withValues(alpha: 0.8),
              const Color(0xFF4FC3F7),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        );
      case 3:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.15, 0.48, 0.73],
            colors: [
              const Color(0xFFFF9800).withValues(alpha: 0.8),
              const Color(0xFFFF9800).withValues(alpha: 0.9),
              const Color(0xFFFF9800),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9800).withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        );
      case 4:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.15, 0.48, 0.73],
            colors: [
              const Color(0xFF9C27B0).withValues(alpha: 0.7),
              const Color(0xFF9C27B0).withValues(alpha: 0.8),
              const Color(0xFF9C27B0),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        );
      default:
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.15, 0.48, 0.73],
            colors: [
              const Color(0xFF1976D2).withValues(alpha: 0.7),
              const Color(0xFF1976D2).withValues(alpha: 0.8),
              const Color(0xFF1976D2),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1976D2).withValues(alpha: 0.5),
              offset: const Offset(0, 2),
              blurRadius: 5,
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: userPageItem.statistics.length.clamp(0, 6),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              alignment: Alignment.centerLeft,
              decoration: _cardDecoration(index),
              child: _cardContent(index, context, userPageItem),
            );
          },
        ),
    );
  }

  Widget _cardContent(
      int index,
      BuildContext context,
      BgmUserPageItem userPageItem,
      ) {
    double fontSize({bool isTitle = false}) {
      final width = MediaQuery.sizeOf(context).width;
      if (width < 500) {
        return isTitle ? 13 : 10;
      } else if (width < 800) {
        return isTitle ? 18 : 14;
      } else if (width < 1000) {
        return isTitle ? 19 : 15;
      } else {
        return isTitle ? 22 : 16;
      }
    }

    final titleStyle = TextStyle(
      fontSize: fontSize(isTitle: true),
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final contentStyle = TextStyle(
      fontSize: fontSize(),
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    if (index >= userPageItem.statistics.length) {
      return const SizedBox.shrink();
    }

    final userItem = userPageItem.statistics[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(userItem.value, style: titleStyle),
        Text(userItem.name, style: contentStyle),
      ],
    );
  }
}
