import 'dart:convert';
import 'dart:io';

import 'package:anime_flow/shared/models/bangumi/actor_item.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> loadResponse() => jsonDecode(
      File('test/shared/models/fixtures/subject_characters.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  test('round-trips the complete subject characters response', () {
    final json = loadResponse();
    final characters = CharactersItem.fromJson(json);

    expect(characters.data, hasLength(10));
    expect(characters.total, 23);
    expect(characters.data.expand((item) => item.casts), hasLength(8));
    expect(characters.data.first.actors.single.name, '坂田将吾');
    expect(characters.data[6].casts, isEmpty);
    expect(characters.data[6].actors, isEmpty);
    expect(jsonDecode(jsonEncode(characters.toJson())), equals(json));
  });

  test('preserves multiple casts, nonzero relations and summaries', () {
    final json = loadResponse();
    final data = json['data'] as List;
    final casts = data.first['casts'] as List;
    casts.first['relation'] = 2;
    casts.first['summary'] = '少年时期';
    casts.add((data[1]['casts'] as List).first);
    casts[1]['relation'] = 1;
    casts[1]['summary'] = '另一语言配音';

    final characters = CharactersItem.fromJson(json);

    expect(characters.data.first.actors, hasLength(2));
    expect(characters.data.first.casts.first.relation, 2);
    expect(characters.data.first.casts.first.summary, '少年时期');
    expect(jsonDecode(jsonEncode(characters.toJson())), equals(json));
  });

  test('reads legacy actors and writes their full person data as casts', () {
    final json = loadResponse();
    final item = (json['data'] as List).first as Map<String, dynamic>;
    final casts = item.remove('casts') as List;
    item['actors'] = casts.map((cast) => cast['person']).toList();

    final character = CharacterActorData.fromJson(item);
    final output = character.toJson();

    expect(character.actors.single.id, 36872);
    expect((output['casts'] as List).single, {
      'person': casts.single['person'],
      'relation': 0,
      'summary': '',
    });
    expect(output['character'], equals(item['character']));
    expect(output['type'], item['type']);
    expect(output['order'], item['order']);

    final constructed = CharacterActorData(
      character: character.character,
      actors: character.actors,
      type: character.type,
      order: character.order,
    );
    expect(constructed.toJson(), equals(output));
  });
}
