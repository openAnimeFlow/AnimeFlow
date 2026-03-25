import 'package:anime_flow/models/item/bgm_user_page_item.dart';
import 'package:html/parser.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class UserPageCrawler {
  ///解析用户页面数据
  static Future<BgmUserPageItem> parseUserPage(String userPageHtml) async {
    const String statisticsDocument = '//*[@id="userStatsContainers"] /div[1]';
    final parser = parse(userPageHtml).documentElement!;

    final statisticsElement = parser.queryXPath(statisticsDocument);
    final List<Statistic> statistics = [];

    for (int i = 1; i <= 6; i++) {
      final statisticsValueDocument = '/div[1] /div[$i] /span[1]';
      final statisticsNameDocument = '/div[1] /div[$i] /span[2]';

      final statisticsValueElement =
          statisticsElement.node!.queryXPath(statisticsValueDocument);
      final statisticsNameElement =
          statisticsElement.node!.queryXPath(statisticsNameDocument);

      String value = '';
      String name = '';

      if (statisticsValueElement.nodes.isNotEmpty) {
        value = statisticsValueElement.nodes[0].text?.trim() ?? '';
      }

      if (statisticsNameElement.nodes.isNotEmpty) {
        name = statisticsNameElement.nodes[0].text?.trim() ?? '';
      }

      statistics.add(Statistic(value: value, name: name));
    }

    return BgmUserPageItem(statistics: statistics);
  }
}
