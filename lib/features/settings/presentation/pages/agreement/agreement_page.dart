import 'package:anime_flow/core/network/api/api.dart';
import 'package:anime_flow/core/utils/utils.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';

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
    _fetchLicense();
  }

  Future<void> _fetchLicense() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Api.getResources<String>(Utils.jsDelivrCdnUrl(
          'https://raw.githubusercontent.com/openAnimeFlow/AnimeFlow/main/LICENSE.txt'));
      setState(() {
        _licenseText = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.openSourceLicense),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
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
              onPressed: _fetchLicense,
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
      padding: const EdgeInsets.all(16),
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
