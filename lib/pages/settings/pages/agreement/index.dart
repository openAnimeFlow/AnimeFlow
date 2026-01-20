import 'package:anime_flow/http/dio/dio_request.dart';
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
      final response = await dioRequest.get<String>(
        'https://raw.githubusercontent.com/openAnimeFlow/AnimeFlow/main/LICENSE.txt',
      );
      
      setState(() {
        _licenseText = response.data ?? '';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('开源协议'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              '加载失败',
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
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_licenseText == null || _licenseText!.isEmpty) {
      return const Center(
        child: Text('暂无许可证信息'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _licenseText!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.6,
            ),
      ),
    );
  }
}
