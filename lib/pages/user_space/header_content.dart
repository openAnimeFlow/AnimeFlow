part of 'index.dart';

class HeaderContent extends StatelessWidget {
  final UserInfoItem userInfo;

  const HeaderContent({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final sign = userInfo.sign;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.4,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.9, 1],
                        ).createShader(bounds);
                      },
                      child: AnimationNetworkImage(
                        url: userInfo.avatar.large,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: AnimationNetworkImage(
                    url: userInfo.avatar.large,
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Text.rich(TextSpan(
                text: userInfo.nickname != ''
                    ? userInfo.nickname
                    : userInfo.username,
                children: [
                  TextSpan(
                      text: '@${userInfo.id}',
                      style: TextStyle(
                          fontSize: 16, color: Theme.of(context).disabledColor))
                ],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )),
              if (sign.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    sign,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).disabledColor,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              Text(
                '${FormatTimeUtil.formatDateTimeFull(userInfo.joinedAt)}加入',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).disabledColor,
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
