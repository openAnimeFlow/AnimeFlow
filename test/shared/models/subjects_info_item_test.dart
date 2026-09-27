import 'package:anime_flow/shared/models/bangumi/subjects_info_item.dart';
import 'package:anime_flow/shared/models/bangumi/interest_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith can clear interest after local cancellation', () {
    final subject = SubjectsInfoItem.fromJson({
      'id': 42,
      'name': 'Example',
      'collection': <String, dynamic>{},
      'eps': 0,
      'volumes': 0,
      'infobox': <dynamic>[],
      'info': '',
      'metaTags': <String>[],
      'locked': false,
      'nsfw': false,
      'series': false,
      'redirect': 0,
      'seriesEntry': 0,
      'summary': '',
      'type': 2,
      'platform': {
        'id': 1,
        'type': 'TV',
        'typeCN': 'TV',
        'alias': 'tv',
        'order': 0,
        'enableHeader': true,
        'wikiTpl': 'TVAnime',
      },
      'rating': {
        'rank': 0,
        'count': List<int>.filled(10, 0),
        'score': 0,
        'total': 0,
      },
      'tags': <dynamic>[],
      'images': <String, String>{},
      'interest': {
        'id': 7,
        'type': 3,
        'rate': 0,
        'comment': '',
        'tags': <dynamic>[],
        'epStatus': 0,
        'volStatus': 0,
        'private': false,
        'updatedAt': 0,
      },
    });

    expect(subject.interest, isA<InterestItem>());
    expect(subject.copyWith(clearInterest: true).interest, isNull);
    expect(subject.interest!.type, 3);
  });

  test('allows a missing airtime from the API', () {
    final subject = SubjectsInfoItem.fromJson({
      'id': 656083,
      'name': '人付き合いが苦手な未亡人の雪女さんと呪いの指輪',
      'nameCN': '不擅交际的未亡人雪女与诅咒戒指',
      'collection': <String, dynamic>{},
      'eps': 0,
      'volumes': 0,
      'infobox': <dynamic>[],
      'info': '',
      'metaTags': <String>[],
      'locked': false,
      'nsfw': false,
      'series': false,
      'redirect': 0,
      'seriesEntry': 0,
      'summary': '',
      'type': 2,
      'platform': {
        'id': 1,
        'type': 'TV',
        'typeCN': 'TV',
        'alias': 'tv',
        'order': 0,
        'enableHeader': true,
        'wikiTpl': 'TVAnime',
      },
      'rating': {
        'rank': 0,
        'count': List<int>.filled(10, 0),
        'score': 0,
        'total': 0,
      },
      'tags': <dynamic>[],
      'images': <String, String>{},
    });

    expect(subject.airtime, isNull);
  });
}
