import 'dart:convert';

/// Decodes UTF-8 SSE frames whose data field contains JSON.
Stream<dynamic> decodeJsonSseEvents(Stream<List<int>> bytes) async* {
  final data = <String>[];

  await for (final line in bytes
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        yield jsonDecode(data.join('\n'));
      }
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue;

    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    if (field == 'data') data.add(value);
  }
}
