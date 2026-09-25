import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/github/application/github_auth_controller.dart';
import 'package:anime_flow/features/github/domain/github_auth_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubIssueView extends ConsumerStatefulWidget {
  const GitHubIssueView({super.key});

  @override
  ConsumerState<GitHubIssueView> createState() => _GitHubIssueViewState();
}

class _GitHubIssueViewState extends ConsumerState<GitHubIssueView> {
  @override
  void dispose() {
    ref.read(gitHubAuthControllerProvider.notifier).cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final session =
        await ref.read(gitHubAuthControllerProvider.notifier).start();
    if (session != null && mounted) await _open(session);
  }

  Future<void> _open(GitHubDeviceSession session) async {
    var opened = false;
    try {
      opened = await launchUrl(
        session.verificationUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).githubOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(gitHubAuthControllerProvider);
    final controller = ref.read(gitHubAuthControllerProvider.notifier);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.githubFeedbackTitle,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  if (auth.phase == GitHubAuthPhase.loading ||
                      auth.phase == GitHubAuthPhase.requesting) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else if (auth.phase == GitHubAuthPhase.waiting &&
                      auth.session != null) ...[
                    Text(l10n.githubDeviceInstructions),
                    const SizedBox(height: 20),
                    Text(l10n.githubUserCodeLabel),
                    const SizedBox(height: 6),
                    SelectableText(auth.session!.userCode,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: auth.session!.userCode),
                        ),
                        icon: const Icon(Icons.copy),
                        label: Text(l10n.githubCopyCode),
                      ),
                      FilledButton.icon(
                        onPressed: () => _open(auth.session!),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(l10n.githubOpenBrowser),
                      ),
                      TextButton(
                        onPressed: controller.cancel,
                        child: Text(l10n.githubCancel),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(l10n.githubWaiting),
                  ] else if (auth.phase == GitHubAuthPhase.connected) ...[
                    Row(children: [
                      if (auth.user?.avatarUrl != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(auth.user!.avatarUrl!),
                        ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('@${auth.user?.login ?? ''}')),
                    ]),
                    if (auth.user != null) Text('ID: ${auth.user!.id}'),
                    const SizedBox(height: 12),
                    Text(l10n.githubConnectedHint),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.disconnect,
                      child: Text(l10n.githubDisconnect),
                    ),
                  ] else ...[
                    if (auth.error != null) ...[
                      Text(auth.error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 12),
                    ],
                    Text(l10n.githubConnectHint),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.login),
                      label: Text(l10n.githubConnect),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
