part of 'index.dart';

class AppBarTitleView extends StatelessWidget {
  final UserInfoItem userInfo;
  final bool isPinned;

  const AppBarTitleView(
      {super.key, required this.userInfo, required this.isPinned});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              child: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: AnimatedOpacity(
                opacity: isPinned ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: AnimationNetworkImage(
                          width: 30, height: 30, url: userInfo.avatar.large),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      userInfo.nickname,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ));
  }
}
