import 'package:anime_flow/controllers/episodes/episodes_controller.dart';
import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/episode_comments_item.dart';
import 'package:anime_flow/widget/image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({super.key});

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView>
    with AutomaticKeepAliveClientMixin {
  List<EpisodeComment>? comments;
  late EpisodesController episodesController;
  Worker? _episodeIdWorker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    episodesController = Get.find<EpisodesController>();
    _getComments();
    _episodeIdWorker = ever(episodesController.episodeId, (episodeId) {
      if (episodeId > 0) {
        setState(() {
          comments = null;
        });
        _getComments();
      }
    });
  }

  @override
  void dispose() {
    _episodeIdWorker?.dispose();
    super.dispose();
  }

  void _getComments() async {
    final episodeId = episodesController.episodeId.value;
    if (episodeId > 0) {
      try {
        final fetchedComments =
            await BgmRequest.episodeCommentsService(episodeId: episodeId);
        if (mounted) {
          setState(() {
            comments = fetchedComments;
          });
        }
      } catch (e) {
        Logger().e(e);
        if (mounted) {
          setState(() {
            comments = [];
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          comments = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildComments();
  }

  Widget _buildComments() {
    if (comments == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      final comments = this.comments!;
      return CustomScrollView(
        slivers: [
          // 标题行
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Text(
                      '吐槽',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      comments.isNotEmpty ? "评论数 ${comments.length}" : "评论数",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // 评论列表或空状态
          if (comments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无评论',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(left: 10, right: 10, bottom:
                MediaQuery.of(context).padding.bottom
              ),
              sliver: SliverList.builder(
                itemCount: comments.length,
                itemBuilder: (BuildContext context, int index) {
                  final comment = comments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AnimationNetworkImage(
                              height: 48,
                              width: 48,
                              url: comment.user.avatar.large),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.user.nickname,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(comment.content)
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      );
    }
  }
}
