class BgmUtils {
  ///角色类型
  static String getCharacterType(int type) {
    switch (type) {
      case 1:
        return '主角';
      case 2:
        return '配角';
      case 3:
        return '客串';
      case 4:
        return '闲角';
      case 5:
        return '旁白';
      default:
        return '未知';
    }
  }
}
