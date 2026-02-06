import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bgm_user_page_item.dart';
import 'package:anime_flow/pages/user_space/user_stores.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView>
    with AutomaticKeepAliveClientMixin {
  late UserSpaceStores userSpaceStores;
  BgmUserPageItem? userPageItem;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    userSpaceStores = Get.find<UserSpaceStores>();
    _getUserPageItem();
  }

  ///获取bgm用户页面信息
  void _getUserPageItem() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final username = userSpaceStores.userInfo.value.username;
    final result = await UserRequest.getBgmUserPageService(username);
    Get.log('用户统计数据:$result');
    if (mounted) {
      setState(() {
        userPageItem = result;
        isLoading = false;
      });
    }
  }

  BoxDecoration _cardDecoration(int index) {
    switch (index) {
      case 0: // 粉色
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
      case 1: // 绿色
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
      case 2: // 浅蓝色
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
      case 3: // 橙色
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
      case 4: // 紫色
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
      default: // 深蓝色
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
    super.build(context);
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => false,
      child: CustomScrollView(
        slivers: <Widget>[
          SliverOverlapInjector(handle: handle),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: SizedBox(
                    width: 600,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          alignment: Alignment.centerLeft,
                          decoration: _cardDecoration(index),
                          child: _cardContent(index, context),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///卡片内容
  Widget _cardContent(int index, BuildContext context) {
    double fontSize({bool isTitle = false}) {
      double width = MediaQuery.of(context).size.width;
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
    switch (index) {
      case 0:
        final userItem = userPageItem?.statistics[0];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(userItem?.value ?? '', style: titleStyle),
            Text(
              userItem?.name ?? '',
              style: contentStyle,
            ),
          ],
        );
      case 1:
        final userItem = userPageItem?.statistics[1];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userItem?.value ?? '', style: titleStyle),
              Text(userItem?.name ?? '', style: contentStyle)
            ]);
      case 2:
        final userItem = userPageItem?.statistics[2];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userItem?.value ?? '', style: titleStyle),
              Text(userItem?.name ?? '', style: contentStyle)
            ]);
      case 3:
        final userItem = userPageItem?.statistics[3];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userItem?.value ?? '', style: titleStyle),
              Text(userItem?.name ?? '', style: contentStyle)
            ]);
      case 4:
        final userItem = userPageItem?.statistics[4];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userItem?.value ?? '', style: titleStyle),
              Text(userItem?.name ?? '', style: contentStyle)
            ]);
      case 5:
        final userItem = userPageItem?.statistics[5];
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userItem?.value ?? '', style: titleStyle),
              Text(userItem?.name ?? '', style: contentStyle)
            ]);
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('标题', style: titleStyle),
            Text('内容', style: contentStyle),
          ],
        );
    }
  }

  @override
  bool get wantKeepAlive => true;
}
