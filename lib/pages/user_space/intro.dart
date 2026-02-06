part of 'index.dart';

class _IntroView extends StatelessWidget {
  final UserInfoItem userInfo;
  const _IntroView({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context) {
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    
    final bool hasBio = userInfo.bio != null && userInfo.bio!.isNotEmpty;
    final bool hasLocation = userInfo.location.isNotEmpty;
    final bool hasSite = userInfo.site.isNotEmpty;
    final bool isEmpty = !hasBio && !hasLocation && !hasSite;

    return CustomScrollView(
      slivers: <Widget>[
        SliverOverlapInjector(handle: handle),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      '该用户很神秘',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                if (hasBio) ...[
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
                if (hasLocation) ...[
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
                if (hasSite) ...[
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
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
