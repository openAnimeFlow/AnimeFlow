import 'package:anime_flow/shared/models/bangumi/actor_item.dart';

/// 角色详情页传给 [CharacterInfo] 的参数集。
class CharacterInfoExtra {
  final int characterId;
  final String characterName;
  final String characterImage;
  final List<CharacterCast> casts;

  const CharacterInfoExtra({
    required this.characterId,
    required this.characterName,
    required this.characterImage,
    this.casts = const [],
  });
}
