import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/app/router/app_router.dart';
import 'package:anime_flow/app/router/model/info_route_extra.dart';
import 'package:anime_flow/features/play/presentation/providers/play_history_provider.dart';
import 'package:anime_flow/app/router/model/play_route_extra.dart';
import 'package:anime_flow/core/utils/system_util.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/shared/widgets/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayRecordView extends ConsumerStatefulWidget {
  const PlayRecordView({super.key});

  @override
  ConsumerState<PlayRecordView> createState() => _PlayRecordViewState();
}

class _PlayRecordViewState extends ConsumerState<PlayRecordView> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScrollLeft = position.pixels > 0.5;
    final canScrollRight = position.pixels < position.maxScrollExtent - 0.5;
    if (canScrollLeft == _canScrollLeft && canScrollRight == _canScrollRight) {
      return;
    }
    if (mounted) {
      setState(() {
        _canScrollLeft = canScrollLeft;
        _canScrollRight = canScrollRight;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  double windowWidth(BuildContext context) => MediaQuery.of(context).size.width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final playHistoryList = ref.watch(playHistoryControllerProvider).value;
    if (playHistoryList == null || playHistoryList.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    } else {
      final playHistory = playHistoryList;
      final filterHistory = playHistory.take(6).toList();
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.playHistorySection,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (playHistory.length > 6)
                  TextButton(
                    onPressed: () => const PlayRecordRoute().push(context),
                    child: Row(
                      children: [
                        Text(
                          l10n.viewMore,
                          style: TextStyle(
                              fontSize: windowWidth(context) > 600 ? 16 : 14,
                              color: Colors.grey),
                        ),
                        const Icon(Icons.keyboard_double_arrow_right_rounded,
                            color: Colors.grey)
                      ],
                    ),
                  )
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 180,
              child: _buildDesktopScrollControls(
                context,
                ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: filterHistory.length,
                  itemBuilder: (context, index) {
                    final history = filterHistory[index];
                    final subjectBasicData = InfoRouteExtra(
                        id: history.subjectId,
                        name: history.subjectName,
                        image: history.cover);
                    return Container(
                      width: 300,
                      padding: EdgeInsets.only(
                          right: index == filterHistory.length - 1 ? 0 : 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          AnimeInfoRoute.fromExtra(subjectBasicData)
                              .push(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: AnimationNetworkImage(
                                          alignment: Alignment.topCenter,
                                          fit: BoxFit.cover,
                                          url: history.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                              Colors.black87,
                                              Colors.transparent,
                                            ])),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    l10n.watchedProgress(
                                                      history.episodeSort,
                                                      Utils.calculatePercentage(
                                                        history.position,
                                                        history.duration,
                                                      ),
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                    child:
                                                        LinearProgressIndicator(
                                                      value: history.duration >
                                                              0
                                                          ? history.position /
                                                              history.duration
                                                          : 0,
                                                      minHeight: 4,
                                                      backgroundColor: Colors
                                                          .white
                                                          .withValues(
                                                              alpha: 0.3),
                                                      valueColor:
                                                          const AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                PlayRoute.fromExtra(
                                                  PlayRouteExtra(
                                                      playExtra: PlayExtra(
                                                          subjectId:
                                                              history.subjectId,
                                                          subjectName: history
                                                              .subjectName,
                                                          subjectCover:
                                                              history.cover,
                                                          subjectAliases:
                                                              history.alias),
                                                      continueEpisodeId:
                                                          history.episodeId),
                                                ).push(context);
                                              },
                                              child: const Icon(
                                                Icons.play_circle,
                                                color: Colors.white70,
                                                size: 40,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              history.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDesktopScrollControls(BuildContext context, Widget child) {
    if (!SystemUtil.isDesktop) return child;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollButtons();
    });
    return Stack(
      children: [
        Positioned.fill(child: child),
        _buildScrollButton(
          alignment: Alignment.centerLeft,
          icon: Icons.chevron_left_rounded,
          enabled: _canScrollLeft,
          onPressed: () => _scrollBy(-windowWidth(context) * 0.55),
        ),
        _buildScrollButton(
          alignment: Alignment.centerRight,
          icon: Icons.chevron_right_rounded,
          enabled: _canScrollRight,
          onPressed: () => _scrollBy(windowWidth(context) * 0.55),
        ),
      ],
    );
  }

  Widget _buildScrollButton({
    required Alignment alignment,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          shape: const CircleBorder(),
          elevation: 2,
          child: IconButton(
            onPressed: enabled ? onPressed : null,
            constraints: const BoxConstraints(minHeight: 50, minWidth: 50),
            icon: Icon(icon),
            style: ButtonStyle(
                mouseCursor: WidgetStatePropertyAll(
              enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
            )),
          ),
        ),
      ),
    );
  }
}
