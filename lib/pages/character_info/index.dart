import 'package:anime_flow/pages/character_info/character_comments.dart';
import 'package:anime_flow/pages/character_info/character_works.dart';
import 'package:anime_flow/pages/character_info/provider/character_info_provider.dart';
import 'package:anime_flow/routes/provider/routes_args.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CharacterInfo extends StatefulWidget {
  const CharacterInfo({super.key});

  @override
  State<CharacterInfo> createState() => _CharacterInfoState();
}

class _CharacterInfoState extends State<CharacterInfo> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final show = _scrollController.offset > 300;
      if (show != _showBackToTop) {
        setState(() {
          _showBackToTop = show;
        });
      }
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 1400.0;

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final name = ref.watch(
              characterInfoArgsProvider.select((e) => e.characterName),
            );
            return Text(name);
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final args = ref.watch(characterInfoArgsProvider);
                      final detailAsync = ref.watch(characterInfoDetailProvider);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'character:${args.characterImage}',
                            child: AnimationNetworkImage(
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              borderRadius: BorderRadius.circular(20),
                              height: 250,
                              width: 150,
                              url: args.characterImage,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  args.characterName,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                detailAsync.when(
                                  data: (character) => Text(
                                    character.info,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final detailAsync = ref.watch(characterInfoDetailProvider);
                  return detailAsync.when(
                    data: (characterDetail) => SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              '介绍',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              characterDetail.summary,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    loading: () => const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    ),
                    error: (_, __) => const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    ),
                  );
                },
              ),
              const SliverPadding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '出演',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const CharacterWorksView(),
              const SliverPadding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '吐槽',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const CharacterCommentsView(),
            ],
          ),
        ),
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton(
        onPressed: _scrollToTop,
        tooltip: '返回顶部',
        child: const Icon(Icons.arrow_upward),
      )
          : null,
    );
  }
}
