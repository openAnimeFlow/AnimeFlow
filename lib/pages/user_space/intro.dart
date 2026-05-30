import 'package:anime_flow/models/item/bangumi/user_info_item.dart';
import 'package:anime_flow/pages/user_space/provider/user_space_provider.dart';
import 'package:anime_flow/pages/user_space/statistics.dart';
import 'package:anime_flow/widget/bbcode/bbcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntroView extends ConsumerWidget {
  final UserInfoItem userInfo;

  const IntroView({super.key, required this.userInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    final statisticsAsync =
        ref.watch(userSpaceStatisticsProvider(userInfo.username));

    final bool hasBio = userInfo.bio != null && userInfo.bio!.isNotEmpty;
    final bool hasLocation = userInfo.location.isNotEmpty;
    final bool hasSite = userInfo.site.isNotEmpty;
    final bool hasProfileInfo = hasBio || hasLocation || hasSite;
    final bool hasStatistics =
        statisticsAsync.asData?.value.statistics.isNotEmpty ?? false;

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: handle),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              statisticsAsync.when(
                data: (data) {
                  if (data.statistics.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          const Text(
                            '统计',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          UserSpaceStatisticsSection(userPageItem: data)
                        ],
                      ) ,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (hasProfileInfo) ...[
                const SizedBox(height: 24),
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
                ],
              ] else if (!hasStatistics && !statisticsAsync.isLoading) ...[
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    '该用户很神秘',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}
