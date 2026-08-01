import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/constants/layout_constant.dart';
import 'package:anime_flow/features/user_space/presentation/providers/user_space_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_flow/features/user_space/presentation/widgets/app_bar_title.dart';
import 'package:anime_flow/features/user_space/presentation/widgets/collect.dart';
import 'package:anime_flow/features/user_space/presentation/widgets/header_content.dart';
import 'package:anime_flow/features/user_space/presentation/widgets/intro.dart';

class UserSpacePage extends StatefulWidget {
  final String username;

  const UserSpacePage({super.key, required this.username});

  @override
  State<UserSpacePage> createState() => _UserSpacePageState();
}

class _UserSpacePageState extends State<UserSpacePage>
    with SingleTickerProviderStateMixin {
  final double contentHeight = 200.0;
  late TabController tabController;
  bool isPinned = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = [l10n.introduction, l10n.collection, l10n.timeline];
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification is ScrollUpdateNotification) {
            final bool isPinned = notification.metrics.pixels >= contentHeight;
            if (this.isPinned != isPinned) {
              setState(() {
                this.isPinned = isPinned;
              });
            }
          }
          return false;
        },
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              Consumer(
                builder: (context, ref, _) {
                  final userInfoAsync =
                      ref.watch(userSpaceProvider(widget.username));
                  final showTabs = userInfoAsync.hasValue;
                  final tabBarHeight = showTabs ? kTextTabBarHeight : 0.0;
                  final userInfo = userInfoAsync.asData?.value;

                  return SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                    sliver: SliverAppBar(
                      automaticallyImplyLeading: false,
                      titleSpacing: 0,
                      title:
                          BarTitleView(userInfo: userInfo, isPinned: isPinned),
                      pinned: true,
                      floating: false,
                      snap: false,
                      elevation: isPinned ? 4.0 : 0.0,
                      forceElevated: isPinned,
                      expandedHeight: contentHeight +
                          statusBarHeight +
                          kToolbarHeight +
                          tabBarHeight,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: Padding(
                          padding: EdgeInsets.only(bottom: tabBarHeight),
                          child: userInfoAsync.when(
                            data: (info) => HeaderContent(userInfo: info),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      bottom: showTabs
                          ? TabBar(
                              controller: tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              dividerHeight: 0,
                              tabs:
                                  tabs.map((name) => Tab(text: name)).toList(),
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor:
                                  Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ];
          },
          body: Builder(builder: buildBody),
        ),
      ),
    );
  }

  Widget wrapBodyMaxWidth(Widget child, {required double maxWidth}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  Widget buildOverlapBody(
    BuildContext context, {
    required Widget child,
  }) {
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: handle),
        SliverFillRemaining(child: child),
      ],
    );
  }

  Widget buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Consumer(
      builder: (context, ref, _) {
        final userInfoAsync = ref.watch(userSpaceProvider(widget.username));

        return userInfoAsync.when(
          loading: () => wrapBodyMaxWidth(
              buildOverlapBody(
                context,
                child: const Center(child: CircularProgressIndicator()),
              ),
              maxWidth: LayoutConstant.maxWidth),
          error: (_, __) => wrapBodyMaxWidth(
              buildOverlapBody(
                context,
                child: Center(child: Text(l10n.userInfoUnavailable)),
              ),
              maxWidth: LayoutConstant.maxWidth),
          data: (userInfo) => wrapBodyMaxWidth(
            TabBarView(
              controller: tabController,
              children: [
                IntroView(userInfo: userInfo),
                CollectView(username: widget.username),
                buildTimelineTab(context, l10n),
              ],
            ),
            maxWidth: LayoutConstant.maxWidth,
          ),
        );
      },
    );
  }

  Widget buildTimelineTab(BuildContext context, AppLocalizations l10n) {
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(handle: handle),
        SliverFillRemaining(
          child: Center(child: Text(l10n.timelineComingSoon)),
        ),
      ],
    );
  }
}
