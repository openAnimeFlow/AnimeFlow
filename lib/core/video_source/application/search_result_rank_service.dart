import 'dart:isolate';
import 'dart:math';

import 'package:anime_flow/core/utils/string_similarity.dart';

/// 候选标题的匹配度排序结果。
///
/// [indices] 是按匹配度降序排列的下标（对应入参 `names`），
/// [matchRatios] 与入参一一对应。
typedef RankedCandidates = ({List<int> indices, List<double> matchRatios});

/// 根据搜索词条与别名对检索结果进行匹配度排序，名称与别名同等对待。
class SearchResultRankService {
  SearchResultRankService({
    required String searchTerm,
    List<String> aliases = const [],
  }) : _terms = _buildTerms(searchTerm, aliases);

  final List<_SearchTerm> _terms;

  static final _titleNoisePattern =
      RegExp(r'[^0-9a-z\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF]+');
  static final _unicodeRomanSeasonPattern =
      RegExp(r'[\u2160-\u216B\u2170-\u217B]');
  static final _latinRomanSeasonPattern = RegExp(
    r'(?<=[\s\u4E00-\u9FFF])(XII|XI|IX|VIII|VII|VI|IV|III|II|X|V|I)'
    r'(?=\s*(?:$|[:：~～(（]|第))',
    caseSensitive: false,
  );
  static const _romanSeasonNumbers = {
    'i': 1,
    'ii': 2,
    'iii': 3,
    'iv': 4,
    'v': 5,
    'vi': 6,
    'vii': 7,
    'viii': 8,
    'ix': 9,
    'x': 10,
    'xi': 11,
    'xii': 12,
  };

  /// 在后台 isolate 里完成「匹配度计算 → 排序」。
  ///
  /// 复用构造时预处理的搜索词条与别名，调用时只需提供候选标题。
  Future<RankedCandidates> rankInIsolate({
    required List<String> names,
  }) {
    return Isolate.run(() {
      final matchRatios =
          names.map((name) => computeMatchRatio(name)).toList(growable: false);
      final indices = List.generate(names.length, (i) => i, growable: false);
      indices.sort((a, b) {
        final cmp = matchRatios[b].compareTo(matchRatios[a]);
        return cmp != 0 ? cmp : a.compareTo(b);
      });
      return (indices: indices, matchRatios: matchRatios);
    });
  }

  /// 返回与名称及别名的最高匹配度，范围为 0~1。
  double computeMatchRatio(String itemName) {
    if (_terms.isEmpty || itemName.isEmpty) {
      return 0;
    }

    final normalizedItem = _normalize(itemName);
    final itemProfile = _TitleSeasonProfile.parseNormalized(normalizedItem);
    var maxRatio = 0.0;

    for (final term in _terms) {
      final ratio = _pairMatchRatio(
        normalizedItem,
        term.normalized,
        itemProfile: itemProfile,
        termProfile: term.profile,
      );
      maxRatio = max(maxRatio, ratio);
      if (maxRatio >= 1) break;
    }

    return maxRatio.clamp(0.0, 1.0);
  }

  double _pairMatchRatio(
    String item,
    String term, {
    required _TitleSeasonProfile itemProfile,
    required _TitleSeasonProfile termProfile,
  }) {
    final seasonFactor =
        _TitleSeasonProfile.alignmentFactor(termProfile, itemProfile);

    late final double rawRatio;
    if (item == term) {
      rawRatio = 1;
    } else if (item.contains(term)) {
      rawRatio = 0.85 + 0.13 * (term.length / item.length).clamp(0.0, 1.0);
    } else if (term.contains(item)) {
      rawRatio = 0.7 * (item.length / term.length).clamp(0.5, 1.0);
    } else if (itemProfile.baseTitle.isNotEmpty &&
        termProfile.baseTitle.isNotEmpty &&
        itemProfile.baseTitle == termProfile.baseTitle) {
      rawRatio = 0.92;
    } else {
      final windowSimilarity = _bestWindowSimilarity(item, term);
      if (windowSimilarity >= 0.75) {
        rawRatio = windowSimilarity * 0.9;
      } else {
        final charCoverage = _orderedCharCoverage(item, term);
        rawRatio = charCoverage >= 0.8
            ? charCoverage * 0.82
            : calculateSimilarity(item, term);
      }
    }

    return rawRatio * seasonFactor;
  }

  /// 在较长标题中寻找与词条最相似的片段，避免季数/标签稀释整串相似度。
  static double _bestWindowSimilarity(String item, String term) {
    if (term.isEmpty || item.isEmpty) {
      return 0;
    }
    if (term.length >= item.length) {
      return calculateSimilarity(item, term);
    }

    var best = 0.0;
    final maxWindow = min(item.length, term.length + 6);
    for (var windowSize = term.length; windowSize <= maxWindow; windowSize++) {
      for (var start = 0; start <= item.length - windowSize; start++) {
        final window = item.substring(start, start + windowSize);
        final sim = calculateSimilarity(window, term);
        if (sim > best) {
          best = sim;
          // 已达调用方判断阈值，无需继续扫描
          if (best >= 0.75) return best;
        }
      }
    }
    return best;
  }

  /// 词条字符按顺序出现在结果标题中的比例。
  static double _orderedCharCoverage(String item, String term) {
    if (term.isEmpty) {
      return 0;
    }

    var termIndex = 0;
    for (var i = 0; i < item.length && termIndex < term.length; i++) {
      if (item[i] == term[termIndex]) {
        termIndex++;
      }
    }
    return termIndex / term.length;
  }

  static List<_SearchTerm> _buildTerms(
    String searchTerm,
    List<String> aliases,
  ) {
    final terms = <_SearchTerm>[];
    final seen = <String>{};
    final normalizedSearch = _normalize(searchTerm);
    final searchProfile = _TitleSeasonProfile.parseNormalized(normalizedSearch);

    for (final normalized in [normalizedSearch, ...aliases.map(_normalize)]) {
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      final profile = normalized == normalizedSearch
          ? searchProfile
          : _TitleSeasonProfile.parseNormalized(normalized);
      terms.add(_SearchTerm(
        normalized: normalized,
        // 别名可能省略季数或部分，用主搜索词补齐，避免错误结果借助别名得到高分。
        profile: _TitleSeasonProfile(
          baseTitle: profile.baseTitle,
          markerKind: profile.hasSeasonMarker
              ? profile.markerKind
              : searchProfile.markerKind,
          seasonNumber: profile.hasSeasonMarker
              ? profile.seasonNumber
              : searchProfile.seasonNumber,
          partNumber: profile.partNumber ?? searchProfile.partNumber,
        ),
      ));
    }

    return terms;
  }

  static String _normalize(String text) {
    // 在移除标点和空格前识别罗马数字季标，保留其语义及英文单词边界。
    final withSeasons = text.replaceAllMapped(_unicodeRomanSeasonPattern, (m) {
      final code = m.group(0)!.codeUnitAt(0);
      final number = code - (code >= 0x2170 ? 0x2170 : 0x2160) + 1;
      return '第$number季';
    }).replaceAllMapped(_latinRomanSeasonPattern, (m) {
      final number = _romanSeasonNumbers[m.group(1)!.toLowerCase()]!;
      return '第$number季';
    });
    // 评分前统一移除 ~、～、标点及空白，保留文字、数字和已识别的季数。
    return withSeasons.toLowerCase().replaceAll(_titleNoisePattern, '');
  }
}

enum _SeasonMarkerKind {
  none,
  numbered,
  finalSeason,
  oad,
  movie,
  special,
  spinoff,
}

class _TitleSeasonProfile {
  const _TitleSeasonProfile({
    required this.baseTitle,
    required this.markerKind,
    this.seasonNumber,
    this.partNumber,
  });

  static final _leadingNoisePattern = RegExp(
    r'^(?:\d{4}年)?(?:\d{1,2}月)?(?:新番|动画|动漫|tv)',
  );
  static final _numberedSeasonPattern =
      RegExp(r'第([一二三四五六七八九十\d]+)(?:季|部(?!分))');
  static final _latinSeasonPattern = RegExp(r'season([1-9]\d*)');
  static final _partPattern = RegExp(r'第([一二三四五六七八九十\d]+)部分|part([1-9]\d*)');
  static final _qualityNoisePattern = RegExp(
    r'完整版|无修正|中文字幕|高清|超清|抢先版|同步播出|独家|连载|1080[pP]|720[pP]',
  );

  static const _markerPatterns = <(_SeasonMarkerKind, String)>[
    (_SeasonMarkerKind.finalSeason, r'最终季|完结季|thefinalseason|finalseason'),
    (_SeasonMarkerKind.oad, r'oad|ova'),
    (_SeasonMarkerKind.movie, r'剧场版|劇場版|movie'),
    (_SeasonMarkerKind.spinoff, r'编年史|外传|前传|续篇|回忆录|无悔的选择'),
    (_SeasonMarkerKind.special, r'特别篇|总集篇|合集|sp|special'),
  ];

  final String baseTitle;
  final _SeasonMarkerKind markerKind;
  final int? seasonNumber;
  final int? partNumber;

  bool get hasSeasonMarker => markerKind != _SeasonMarkerKind.none;

  static _TitleSeasonProfile parseNormalized(String normalized) {
    var work = normalized;
    var markerKind = _SeasonMarkerKind.none;
    int? seasonNumber;
    int? partNumber;

    work = work.replaceAll(_leadingNoisePattern, '');

    final partMatch = _partPattern.firstMatch(work);
    if (partMatch != null) {
      partNumber = _parseNumberToken(partMatch.group(1) ?? partMatch.group(2)!);
      work = work.replaceAll(partMatch.group(0)!, '');
    }

    final numberedMatch = _numberedSeasonPattern.firstMatch(work);
    if (numberedMatch != null) {
      markerKind = _SeasonMarkerKind.numbered;
      seasonNumber = _parseNumberToken(numberedMatch.group(1)!);
      work = work.replaceAll(numberedMatch.group(0)!, '');
    } else {
      for (final (kind, pattern) in _markerPatterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(work)) {
          markerKind = kind;
          work = work.replaceAll(regex, '');
          break;
        }
      }

      if (markerKind == _SeasonMarkerKind.none) {
        final latinSeasonMatch = _latinSeasonPattern.firstMatch(work);
        if (latinSeasonMatch != null) {
          markerKind = _SeasonMarkerKind.numbered;
          seasonNumber = int.tryParse(latinSeasonMatch.group(1)!);
          work = work.replaceAll(latinSeasonMatch.group(0)!, '');
        }
      }
    }

    work = work.replaceAll(_qualityNoisePattern, '');

    return _TitleSeasonProfile(
      baseTitle: work,
      markerKind: markerKind,
      seasonNumber: seasonNumber,
      partNumber: partNumber,
    );
  }

  /// 搜索词与结果季数、类型及部分编号的对齐系数。
  static double alignmentFactor(
    _TitleSeasonProfile search,
    _TitleSeasonProfile result,
  ) {
    final partFactor = search.partNumber == result.partNumber
        ? 1.0
        : search.partNumber == null || result.partNumber == null
            ? 0.85
            : 0.52;
    return _seasonAlignmentFactor(search, result) * partFactor;
  }

  static double _seasonAlignmentFactor(
    _TitleSeasonProfile search,
    _TitleSeasonProfile result,
  ) {
    if (!search.hasSeasonMarker && !result.hasSeasonMarker) {
      return 1;
    }

    if (!search.hasSeasonMarker && result.hasSeasonMarker) {
      return switch (result.markerKind) {
        _SeasonMarkerKind.numbered => 0.88,
        _SeasonMarkerKind.finalSeason => 0.86,
        _SeasonMarkerKind.oad => 0.8,
        _SeasonMarkerKind.movie => 0.78,
        _SeasonMarkerKind.special => 0.76,
        _SeasonMarkerKind.spinoff => 0.72,
        _ => 0.85,
      };
    }

    if (search.hasSeasonMarker && !result.hasSeasonMarker) {
      return 0.8;
    }

    if (search.markerKind == result.markerKind) {
      if (search.markerKind == _SeasonMarkerKind.numbered) {
        return search.seasonNumber == result.seasonNumber ? 1 : 0.52;
      }
      return 1;
    }

    if (search.markerKind == _SeasonMarkerKind.numbered &&
        result.markerKind == _SeasonMarkerKind.finalSeason) {
      return 0.62;
    }

    if (search.markerKind == _SeasonMarkerKind.finalSeason &&
        result.markerKind == _SeasonMarkerKind.numbered) {
      return 0.58;
    }

    return 0.5;
  }

  static int? _parseNumberToken(String token) {
    if (RegExp(r'^\d+$').hasMatch(token)) {
      return int.tryParse(token);
    }

    const digitMap = {
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };

    if (token.length == 1) {
      if (token == '十') {
        return 10;
      }
      return digitMap[token];
    }

    if (token.startsWith('十') && token.length == 2) {
      return 10 + (digitMap[token[1]] ?? 0);
    }

    if (token.endsWith('十') && token.length == 2) {
      return (digitMap[token[0]] ?? 0) * 10;
    }

    if (token.length == 3 && token[1] == '十') {
      final tens = digitMap[token[0]] ?? 0;
      final ones = digitMap[token[2]] ?? 0;
      return tens * 10 + ones;
    }

    return null;
  }
}

class _SearchTerm {
  const _SearchTerm({
    required this.normalized,
    required this.profile,
  });

  final String normalized;
  final _TitleSeasonProfile profile;
}
