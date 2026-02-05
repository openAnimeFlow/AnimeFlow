part of 'index.dart';

class _IntroView extends StatelessWidget {
  final UserInfoItem userInfo;
  const _IntroView({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverOverlapInjector(handle: handle),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (userInfo.bio != null && userInfo.bio!.isNotEmpty) ...[
                const Text(
                  '个人简介',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                BBCodeWidget(bbcode: userInfo.bio!),
                const SizedBox(height: 24),
              ],
              if (userInfo.location.isNotEmpty) ...[
                const Text(
                  '所在地',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(userInfo.location),
                const SizedBox(height: 24),
              ],
              if (userInfo.site.isNotEmpty) ...[
                const Text(
                  '网站',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(userInfo.site),
                const SizedBox(height: 24),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
