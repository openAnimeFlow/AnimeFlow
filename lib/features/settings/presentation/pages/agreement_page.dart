import 'package:anime_flow/shared/widgets/adaptive_app_bar.dart';
import 'package:anime_flow/features/settings/presentation/widgets/settings_page_builder.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class AgreementPage extends StatefulWidget {
  const AgreementPage({super.key});

  @override
  State<AgreementPage> createState() => _AgreementPageState();
}

class _AgreementPageState extends State<AgreementPage> {
  bool _isLoading = false;
  String? _licenseText;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLicense();
  }

  Future<void> _loadLicense() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final licenseText = await rootBundle.loadString('LICENSE.txt');
      if (!mounted) return;
      setState(() {
        _licenseText = licenseText;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SettingsPageBuilder(
        builder: (context, glassStyle) => Scaffold(
              extendBodyBehindAppBar: glassStyle,
              appBar: AdaptiveAppBar(
                glassStyle: glassStyle,
                title: Text(l10n.openSourceLicense),
              ),
              body: _buildBody(context, l10n),
            ));
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loadFailed,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLicense,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_licenseText == null || _licenseText!.isEmpty) {
      return Center(
        child: Text(l10n.noLicenseInfo),
      );
    }

    return SingleChildScrollView(
      padding: (const EdgeInsets.all(16))
          .add(EdgeInsets.only(top: SettingsPageBuilder.topInsetOf(context))),
      child: Center(
        child: SelectableText(
          _licenseText!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.6,
              ),
        ),
      ),
    );
  }
}
