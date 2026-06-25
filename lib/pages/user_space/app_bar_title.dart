import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/widget/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BarTitleView extends StatelessWidget {
  final UserInfoItem? userInfo;
  final bool isPinned;

  const BarTitleView(
      {super.key, required this.userInfo, required this.isPinned});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 5),
            if (userInfo != null)
              Expanded(
                child: AnimatedOpacity(
                  opacity: isPinned ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: AnimationNetworkImage(
                            width: 30, height: 30, url: userInfo!.avatar.large),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userInfo!.nickname,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            if (userInfo!.sign.isNotEmpty)
                              Text(
                                userInfo!.sign,
                                style: const TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ));
  }
}
