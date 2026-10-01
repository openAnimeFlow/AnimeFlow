import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/core/network/core/dio_factory.dart';
import 'package:anime_flow/features/github/domain/github_issue_models.dart';
import 'package:dio/dio.dart';

class GitHubIssueApi {
  GitHubIssueApi({Dio? dio}) : _dio = dio ?? DioFactory.githubAuthorizedDio;

  static const pageSize = 30;
  final Dio _dio;

  Future<GitHubIssuePage> listPage(int page) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    final response = await _dio.get<dynamic>(
      GitHubApi.repositoryIssues,
      queryParameters: {
        'state': 'all',
        'sort': 'updated',
        'direction': 'desc',
        'per_page': pageSize,
        'page': page,
      },
    );
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid GitHub issues response');
    }
    final issues = <GitHubIssue>[];
    for (final item in data) {
      if (item is! Map) {
        throw const FormatException('Invalid GitHub issues response');
      }
      if (item['pull_request'] != null) continue;
      issues.add(GitHubIssue.fromJson(Map<String, dynamic>.from(item)));
    }
    return GitHubIssuePage(
      issues,
      _nextPage(response.headers.value('link'), page),
    );
  }

  static int? _nextPage(String? link, int currentPage) {
    if (link == null) return null;
    for (final entry in link.split(',')) {
      final match = RegExp(r'<([^>]+)>;\s*rel="next"').firstMatch(entry);
      if (match == null) continue;
      final uri = Uri.tryParse(match.group(1)!);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'api.github.com' ||
          uri.path != GitHubApi.repositoryIssues) {
        return null;
      }
      final next = int.tryParse(uri.queryParameters['page'] ?? '');
      return next != null && next > currentPage ? next : null;
    }
    return null;
  }
}
