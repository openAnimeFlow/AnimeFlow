import 'package:anime_flow/shared/navigation/settings_destination.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/navigation/app_navigator_provider.dart';
import 'package:anime_flow/core/constants/constants.dart';
import 'package:anime_flow/core/webview/browser/browser_webview_controller.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class WebsitePage extends StatefulWidget {
  const WebsitePage({super.key});

  @override
  State<WebsitePage> createState() => _WebsitePageState();
}

class _WebsitePageState extends State<WebsitePage> {
  BrowserWebviewController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= BrowserWebviewController(
      url: Constants.animeFlowWebsite,
      title: AppLocalizations.of(context).projectWebsite,
    )..load();
  }

  Future<void> _openInBrowser() async {
    if (await _controller!.openInBrowser() || !mounted) return;
    final l10n = AppLocalizations.of(context);
    NotificationToast.show(l10n.deviceUnsupportedWeb,
        title: l10n.unableOpenWeb);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      appNavigatorOf(context).goToSettings(context, SettingsDestination.about);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(l10n.projectWebsite),
          actions: [
            IconButton(
              tooltip: l10n.reload,
              onPressed: controller.isLoading ? null : controller.load,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: l10n.openInBrowser,
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_new),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(children: [
            if (controller.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: controller.hasError
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(l10n.loadFailed),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: controller.load,
                            child: Text(l10n.retry)),
                      ]),
                    )
                  : controller.buildView() ??
                      Center(
                        child: controller.isLoading
                            ? const CircularProgressIndicator()
                            : controller.isWindowOpen
                                ? Text(l10n.websiteWindowOpened)
                                : FilledButton(
                                    onPressed: controller.load,
                                    child: Text(l10n.openWebsiteWindow),
                                  ),
                      ),
            ),
          ]),
        ),
      ),
    );
  }
}
