import 'package:anime_flow/http/requests/bgm_request.dart';
import 'package:anime_flow/models/item/bangumi/character_detail_item.dart';
import 'package:anime_flow/widget/animation_network_image/animation_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CharacterInfo extends StatefulWidget {
  const CharacterInfo({super.key});

  @override
  State<CharacterInfo> createState() => _CharacterInfoState();
}

class _CharacterInfoState extends State<CharacterInfo> {
  late String characterName;
  late int characterId;
  late String characterImage;
  CharacterDetailItem? characterDetail;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>;
    characterName = arguments['characterName'] as String;
    characterId = arguments['characterId'] as int;
    characterImage = arguments['characterImage'] as String;
    _getCharacterInfo();
  }

  void _getCharacterInfo() async {
    final characterInfo = await BgmRequest.characterInfoService(characterId);
    setState(() {
      characterDetail = characterInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(characterName),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Hero(
                  tag: 'character:$characterImage',
                  child: AnimationNetworkImage(
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      borderRadius: BorderRadius.circular(20),
                      height: 250,
                      width: 150,
                      url: characterImage),
                ),
                const SizedBox(width: 5),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(characterName,
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      if (characterDetail != null) {
                        final character = characterDetail!;
                        final info = character.info;
                        return Text(
                          info,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    })
                  ],
                ))
              ]),
              if (characterDetail != null) ...[
                const SizedBox(height: 20),
                const Text(
                  '介绍',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  characterDetail!.summary,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
