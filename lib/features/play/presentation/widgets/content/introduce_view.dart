import 'package:anime_flow/features/play/application/player_bindings.dart';
import 'package:anime_flow/features/auth/auth_api.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/recommendations.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/danmaku_card.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/episodes.dart';
import 'package:anime_flow/features/play/presentation/widgets/content/resources.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/play/presentation/providers/play_args_provider.dart';
import 'package:anime_flow/core/network/clients/flow_client.dart';
import 'package:anime_flow/features/anime_info/presentation/providers/anime_info_provider.dart';
import 'package:anime_flow/shared/widgets/collection_button.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:anime_flow/features/play/presentation/providers/episodes_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/play_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_ui_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/video_source_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/danmaku_state_provider.dart';
import 'package:anime_flow/features/play/presentation/providers/recommendation_provider.dart';

@Dependencies([
  playExtra,
  AnimeInfo,
  Episodes,
  playSession,
  PlayStateNotifier,
  VideoUiNotifier,
  VideoSourceNotifier,
  DanmakuStateNotifier,
  recommendation
])
class IntroduceView extends StatefulWidget {
  const IntroduceView({super.key, required this.onShowDetails});

  final VoidCallback onShowDetails;

  @override
  State<IntroduceView> createState() => _IntroduceViewState();
}

class _IntroduceViewState extends State<IntroduceView>
    with AutomaticKeepAliveClientMixin {
  final _collectionMenuTurns = ValueNotifier<double>(0);

  @override
  void dispose() {
    _collectionMenuTurns.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Consumer(builder: (context, ref, child) {
              final extra = ref.watch(playExtraProvider).playExtra;
              final isLoggedIn = ref.watch(isLoggedInProvider).value ?? false;
              final subject = ref.watch(animeInfoProvider).asData?.value;
              final l10n = AppLocalizations.of(context);

              return Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onShowDetails,
                      borderRadius: BorderRadius.circular(10),
                      child: Text(
                        extra.subjectName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isLoggedIn && subject != null)
                    CollectionButton(
                      key: ValueKey(extra.subjectId),
                      collectType:
                          collectTypeFromApiType(subject.interest?.type),
                      onMenuOpen: () => _collectionMenuTurns.value = 0.5,
                      onMenuClose: () => _collectionMenuTurns.value = 0,
                      buttonBuilder: (context, label, icon, onPressed) {
                        return IconButton(
                          tooltip: label,
                          onPressed: onPressed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: ValueListenableBuilder<double>(
                            valueListenable: _collectionMenuTurns,
                            builder: (context, turns, child) =>
                                AnimatedRotation(
                              turns: turns,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              child: child,
                            ),
                            child: const Icon(Icons.expand_more_outlined),
                          ),
                        );
                      },
                      onCollectTypeChanged: (newType) async {
                        try {
                          await ref
                              .read(animeInfoProvider.notifier)
                              .updateCollectionType(newType.value);
                        } on AnimeFlowApiException catch (e) {
                          NotificationToast.show(
                            e.message,
                            title: l10n.updateFailed,
                          );
                          rethrow;
                        } catch (e) {
                          NotificationToast.show(
                            e.toString(),
                            title: l10n.updateFailed,
                          );
                          rethrow;
                        }
                      },
                    ),
                ],
              );
            }),
            const SizedBox(height: 5),
            //章节
            const EpisodesListView(),
            //数据源
            const VideoResourcesView(),
            //弹幕
            const DanmakuCard(),
            const RecommendationsView(),
          ],
        ),
      ),
    );
  }
}
