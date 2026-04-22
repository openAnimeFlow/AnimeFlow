import 'dart:io';

import 'package:anime_flow/http/requests/request.dart';
import 'package:anime_flow/models/item/anime_image_search_result_item.dart';
import 'package:anime_flow/routes/routes.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class AnimeImageSearchPage extends StatefulWidget {
  const AnimeImageSearchPage({super.key});

  @override
  State<AnimeImageSearchPage> createState() => _AnimeImageSearchPageState();
}

class _AnimeImageSearchPageState extends State<AnimeImageSearchPage> {
  bool isSearching = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _imageUrlController = TextEditingController();
  AnimeImageSearchResultItem? animeImageSearchResultItem;

  Future<void> _pickAndSearchImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        isSearching = true;
        animeImageSearchResultItem = null;
      });
      final result = await Request.getAnimeInfoByImageFile(File(image.path));

      if (!mounted) return;
      setState(() {
        isSearching = false;
        animeImageSearchResultItem = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSearching = false;
      });
      Logger().e(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片选择或上传失败: $e')),
      );
    }
  }

  Future<void> _searchByImageUrl() async {
    final imageUrl = _imageUrlController.text.trim();
    final uri = Uri.tryParse(imageUrl);
    final isValidUrl =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的图片链接')),
      );
      return;
    }

    try {
      setState(() {
        animeImageSearchResultItem = null;
        isSearching = true;
      });
      final result = await Request.getAnimeInfoByImageUrl(imageUrl);
      if (!mounted) return;
      setState(() {
        animeImageSearchResultItem = result;
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSearching = false;
      });
      Logger().e(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('链接识别失败: $e')),
      );
    }
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = animeImageSearchResultItem;

    return Scaffold(
      body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back)),
                  const Text("番剧截图搜索"),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _imageUrlController,
                        enabled: !isSearching,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchByImageUrl(),
                        decoration: const InputDecoration(
                          hintText: "番剧图片链接",
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                        ),
                      ),
                    ),
                    // IconButton(
                    //   onPressed: isSearching ? null : _searchByImageUrl,
                    //   tooltip: '通过链接搜索',
                    //   icon: isSearching
                    //       ? const SizedBox(
                    //           width: 20,
                    //           height: 20,
                    //           child: CircularProgressIndicator(strokeWidth: 2),
                    //         )
                    //       : const Icon(Icons.search),
                    // ),
                    TextButton(
                      onPressed: isSearching ? null : _pickAndSearchImage,
                      child: const Icon(
                        Icons.drive_file_move_rounded,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                  child: isSearching == true
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : result == null
                          ? Center(
                              child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.image_search_outlined,
                                      size: 100),
                                  const Text("上传截图搜索出处"),
                                  Text(
                                    "上传原始比例的截图以提高搜索准确度",
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                  ),
                                ],
                              ),
                            ))
                          : result.result.isEmpty
                              ? Center(
                                  child: Text(result.error.isNotEmpty
                                      ? result.error
                                      : '未找到匹配结果'))
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: result.result.length,
                                  itemBuilder: (context, index) {
                                    final match = result.result[index];
                                    return InkWell(
                                      onTap: () {
                                        context.push(RouteName.search,
                                            extra:
                                                match.anilist?.title.native ??
                                                    match.filename);
                                      },
                                      child: _SearchResultCard(match: match),
                                    );
                                  },
                                ))
            ],
          )),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final AnimeImageSearchMatchItem match;

  const _SearchResultCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final similarityPercent = (match.similarity * 100).toStringAsFixed(1);
    final episodeText = _buildEpisodeText(match.episodes);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.anilist?.title.native ?? match.filename,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AnimationNetworkImage(
                      borderRadius: BorderRadius.circular(8),
                      url: match.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (episodeText != null) Text(episodeText),
                      Text('相似度: $similarityPercent%'),
                      Text(
                        '时间: ${_formatTime(match.from)} - ${_formatTime(match.to)}',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String? _buildEpisodeText(List<double> episodes) {
    if (episodes.isEmpty) return null;
    final episodeLabel = episodes.map((item) {
      if (item % 1 == 0) return item.toInt().toString();
      return item.toStringAsFixed(1);
    }).join(', ');
    return '第 $episodeLabel 集';
  }
}
