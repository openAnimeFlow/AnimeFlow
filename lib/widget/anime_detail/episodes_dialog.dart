import 'package:anime_flow/models/item/episodes_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void episodesDialog(BuildContext context, Future<EpisodesItem> episodesItem) {
  Get.defaultDialog(
    title: "章节列表",
    radius: 8,
    titleStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    contentPadding: const EdgeInsets.all(16),
    content: SizedBox(
      //设置最大宽度
      width: MediaQuery.of(context).size.width * 0.6,
      height: MediaQuery.of(context).size.height * 0.3,
      child: FutureBuilder<EpisodesItem>(
        future: episodesItem,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
            return const Center(child: Text("暂无章节信息"));
          }

          final episodes = snapshot.data!.data;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 60,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return Material(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                elevation: 1,
                child: InkWell(
                  onTap: () {
                    // TODO: 实现跳转播放或选集逻辑
                    Get.back();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      "${episode.sort}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
