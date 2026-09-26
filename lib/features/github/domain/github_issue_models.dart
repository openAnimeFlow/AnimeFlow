class GitHubIssue {
  const GitHubIssue({
    required this.number,
    required this.title,
    required this.isOpen,
    required this.author,
  });

  final int number;
  final String title;
  final bool isOpen;
  final String author;

  Uri get url => Uri.https(
        'github.com',
        '/openAnimeFlow/AnimeFlow/issues/$number',
      );

  factory GitHubIssue.fromJson(Map<String, dynamic> json) {
    final number = json['number'];
    final title = json['title'];
    final state = json['state'];
    final user = json['user'];
    if (number is! int || number <= 0 || title is! String || state is! String) {
      throw const FormatException('Invalid GitHub issue');
    }
    return GitHubIssue(
      number: number,
      title: title,
      isOpen: state == 'open',
      author:
          user is Map && user['login'] is String ? user['login'] as String : '',
    );
  }
}

class GitHubIssuePage {
  const GitHubIssuePage(this.issues, this.nextPage);

  final List<GitHubIssue> issues;
  final int? nextPage;
}
