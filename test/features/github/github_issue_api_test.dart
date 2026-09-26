import 'package:anime_flow/core/network/api_path.dart';
import 'package:anime_flow/features/github/data/github_issue_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists all states, filters pull requests and follows Link pages',
      () async {
    final dio = Dio(BaseOptions(baseUrl: GitHubApi.apiBaseUrl));
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      final page = options.queryParameters['page'] as int;
      final data = switch (page) {
        1 => [
            {
              'number': 11,
              'title': 'First issue',
              'state': 'open',
              'user': {'login': 'alice'},
            },
            {
              'number': 12,
              'title': 'A pull request',
              'state': 'open',
              'pull_request': {'url': 'https://api.github.com/pulls/12'},
            },
          ],
        2 => [
            {
              'number': 13,
              'title': 'Another pull request',
              'state': 'closed',
              'pull_request': {'url': 'https://api.github.com/pulls/13'},
            },
          ],
        _ => [
            {
              'number': 14,
              'title': 'Closed issue',
              'state': 'closed',
              'user': {'login': 'bob'},
            },
          ],
      };
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: data,
        headers: Headers.fromMap({
          if (page < 3)
            'link': [
              '<https://api.github.com${GitHubApi.repositoryIssues}?state=all&per_page=30&page=${page + 1}>; rel="next"'
            ],
        }),
      ));
    }));
    final api = GitHubIssueApi(dio: dio);

    final first = await api.listPage(1);
    final second = await api.listPage(first.nextPage!);
    final third = await api.listPage(second.nextPage!);

    expect(first.issues.map((issue) => issue.number), [11]);
    expect(first.issues.single.url.toString(),
        'https://github.com/openAnimeFlow/AnimeFlow/issues/11');
    expect(second.issues, isEmpty);
    expect(second.nextPage, 3);
    expect(third.issues.single.isOpen, isFalse);
    expect(third.nextPage, isNull);
    expect(
        requests.map((request) => request.queryParameters['page']), [1, 2, 3]);
    expect(requests.first.queryParameters, {
      'state': 'all',
      'sort': 'updated',
      'direction': 'desc',
      'per_page': 30,
      'page': 1,
    });
    expect(requests.first.uri.host, 'api.github.com');
    expect(requests.first.headers.containsKey('Authorization'), isFalse);
  });

  test('ignores a next-page URL outside the fixed GitHub repository', () async {
    final dio = Dio(BaseOptions(baseUrl: GitHubApi.apiBaseUrl));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: <Object>[],
        headers: Headers.fromMap({
          'link': ['<https://example.com/issues?page=2>; rel="next"'],
        }),
      ));
    }));

    final page = await GitHubIssueApi(dio: dio).listPage(1);

    expect(page.nextPage, isNull);
  });
}
