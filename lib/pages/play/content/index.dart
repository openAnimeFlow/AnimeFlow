import 'package:anime_flow/providers/user/user_state_provider.dart';
import 'package:anime_flow/pages/play/content/introduce/index.dart';
import 'package:anime_flow/pages/play/providers/play_provider.dart';
import 'package:anime_flow/pages/play/providers/video_ui_provider.dart';
import 'package:anime_flow/widget/danmaku_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comments/index.dart';

class ContentView extends ConsumerStatefulWidget {
  const ContentView({super.key});

  @override
  ConsumerState<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends ConsumerState<ContentView>
    with SingleTickerProviderStateMixin {
  late final PlaySession playSession;
  late final VideoUiNotifier videoUiStateController;
  final List<String> tabs = ['简介', '吐槽'];
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    playSession = ref.read(playSessionProvider);
    videoUiStateController = ref.read(videoUiProvider.notifier);
    tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> onSendDanmaku(String text, int userId) async {
    final success = await playSession.sendDanmaku(
      text,
      bgmUserId: userId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '弹幕发送成功' : '当前不支持发送弹幕',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TabBar(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                dividerHeight: 0,
                controller: tabController,
                tabAlignment: TabAlignment.start,
                isScrollable: true,
                tabs: tabs.map((name) => Tab(text: name)).toList(),
              ),
              ref.watch(playStateProvider.select((state) => state.isWideScreen))
                  ? const Spacer()
                  : Consumer(
                      builder: (context, ref, _) {
                        final isLogin = ref.watch(isLoggedInProvider).value;
                        if (isLogin != true) return const SizedBox.shrink();
                        final userInfo = ref.watch(currentUserInfoProvider).value;
                        return SizedBox(
                          width: 200,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: DanmakuTextField(
                              onFocusChange: (hasFocus) {
                                if (hasFocus) {
                                  playSession.stopPlaying();
                                  videoUiStateController.cancelUiTimer();
                                } else {
                                  playSession.startPlaying();
                                  videoUiStateController.hideControlsUi();
                                }
                              },
                              onSend: (text) =>
                                  onSendDanmaku(text, userInfo!.id),
                            ),
                          ),
                        );
                      },
                    )
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                IntroduceView(),
                CommentsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
