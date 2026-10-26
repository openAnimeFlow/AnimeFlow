import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorPage extends StatelessWidget {
  const AuthorPage({super.key});

  static const String authorName = 'Ligg';
  static const String authorEmail = '2954494754@qq.com';

  Future<void> _openLink(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Keep the email address available to copy when no mail client exists.
    }
    if (!opened && context.mounted) {
      NotificationToast.show('未能打开链接，请稍后重试；联系作者也可复制邮箱。');
    }
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: authorEmail));
    if (context.mounted) {
      NotificationToast.show('邮箱已复制');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final paragraphStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.8);
    final headingStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('关于作者')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AnimeFlow 开发者',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '你好，我是 $authorName',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Java / SpringBoot · Flutter / Dart',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '我是一名热爱编程与动漫的开发者，主要开发方向是 Java / SpringBoot 后端与 Flutter 跨平台客户端。我喜欢把想法变成可以使用的产品，通过 AnimeFlow 的开发与持续迭代，打磨功能细节，让代码更可靠、体验更顺畅。',
                    style: paragraphStyle,
                  ),
                  const SizedBox(height: 32),
                  const Divider(height: 1),
                  const SizedBox(height: 32),
                  Text('技术方向', style: headingStyle),
                  const SizedBox(height: 20),
                  const _AuthorSection(
                    title: 'Java / SpringBoot 后端开发',
                    description:
                        '后端开发方向以 Java / SpringBoot 为主，关注业务逻辑、接口设计与数据处理，注重清晰的代码结构和可维护性，希望围绕实际业务需求构建稳定、可靠的后端服务。',
                  ),
                  const SizedBox(height: 24),
                  const _AuthorSection(
                    title: 'Flutter 跨平台开发',
                    description:
                        '围绕 Flutter 与 Dart 开展移动端和桌面端应用开发，在 AnimeFlow 项目中实践页面交互、状态管理、网络请求与多平台适配，兼顾用户体验与代码的可维护性。',
                  ),
                  const SizedBox(height: 28),
                  const Divider(height: 1),
                  const SizedBox(height: 32),
                  Text('期待与你共事', style: headingStyle),
                  const SizedBox(height: 12),
                  Text(
                    '我正在寻找 Java / SpringBoot 后端开发或 Flutter 跨平台客户端开发相关岗位。希望加入愿意交流、重视协作的团队，参与实际业务开发，认真完成每一项任务，与团队一起把产品做好。如果你有合适的岗位或招聘线索，欢迎通过邮箱联系我，进一步交流项目与岗位需求。',
                    style: paragraphStyle,
                  ),
                  const SizedBox(height: 20),
                  SelectableText(
                    authorEmail,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openLink(
                          context,
                          Uri(
                            scheme: 'mailto',
                            path: authorEmail,
                            query:
                                'subject=${Uri.encodeComponent('Java / SpringBoot 后端开发、Flutter 岗位交流 · Ligg')}',
                          ),
                        ),
                        icon: const Icon(Icons.mail_outline_rounded),
                        label: const Text('邮件联系'),
                      ),
                      TextButton.icon(
                        onPressed: () => _copyEmail(context),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('复制邮箱'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorSection extends StatelessWidget {
  const _AuthorSection({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
        ),
      ],
    );
  }
}
