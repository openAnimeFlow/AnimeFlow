/// 角色详情页传给 [CharacterInfo] 的参数集。
class CharacterInfoExtra {
  final int characterId;
  final String characterName;
  final String characterImage;

  const CharacterInfoExtra({
    required this.characterId,
    required this.characterName,
    required this.characterImage,
  });
}