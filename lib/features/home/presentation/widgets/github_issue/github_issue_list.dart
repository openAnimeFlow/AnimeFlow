import 'dart:async';

import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/github/data/github_issue_api.dart';
import 'package:anime_flow/features/github/domain/github_issue_models.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubIssueList extends StatefulWidget {
  const GitHubIssueList({super.key});

  @override
  State<GitHubIssueList> createState() => _GitHubIssueListState();
}

class _GitHubIssueListState extends State<GitHubIssueList> {
  final _api = GitHubIssueApi();
  final _issues = <GitHubIssue>[];
  int? _nextPage = 1;
  int _failedPage = 1;
  bool _loading = false;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    final page = reset ? 1 : _nextPage;
    if (page == null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _api.listPage(page);
      if (!mounted) return;
      setState(() {
        if (reset) _issues.clear();
        final seen = _issues.map((issue) => issue.number).toSet();
        for (final issue in result.issues) {
          if (seen.add(issue.number)) _issues.add(issue);
        }
        _nextPage = result.nextPage;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _failedPage = page;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(GitHubIssue issue) async {
    var opened = false;
    try {
      opened = await launchUrl(issue.url, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).githubIssueOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(l10n.githubIssuesTitle,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                tooltip: l10n.githubIssuesRefresh,
                onPressed: _loading ? null : () => _load(reset: true),
                icon: const Icon(Icons.refresh),
              ),
            ]),
            if (_loading && !_loaded)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_loaded && _issues.isEmpty && !_loading && !_failed)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_nextPage == null
                    ? l10n.githubIssuesEmpty
                    : l10n.githubIssuesNoResultsYet),
              ),
            for (final issue in _issues)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  issue.isOpen
                      ? Icons.radio_button_unchecked
                      : Icons.check_circle_outline,
                  color:
                      issue.isOpen ? colors.primary : colors.onSurfaceVariant,
                ),
                title: Text(issue.title),
                subtitle: Text(
                  '#${issue.number} · @${issue.author} · '
                  '${issue.isOpen ? l10n.githubIssueOpen : l10n.githubIssueClosed}',
                ),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(issue),
              ),
            if (_failed) ...[
              Text(l10n.githubIssuesLoadFailed,
                  style: TextStyle(color: colors.error)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _load(reset: _failedPage == 1),
                  child: Text(l10n.retry),
                ),
              ),
            ],
            if (_loading && _loaded)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && !_failed && _nextPage != null)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _load,
                  child: Text(l10n.githubIssuesLoadMore),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
