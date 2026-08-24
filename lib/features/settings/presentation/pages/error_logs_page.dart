import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/core/logger/logger.dart';
import 'package:anime_flow/features/settings/presentation/providers/setting_provider.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorLogsPage extends StatefulWidget {
  const ErrorLogsPage({super.key});

  @override
  State<ErrorLogsPage> createState() => _ErrorLogsPageState();
}

class _ErrorLogsPageState extends State<ErrorLogsPage> {
  static const int _initialLoadCount = 50;
  static const int _loadMoreCount = 100;

  final List<String> _logLines = [];
  final ScrollController _scrollController = ScrollController();
  List<String> _allLines = [];
  String _fullContent = '';
  int _displayedLines = 0;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _displayedLines >= _allLines.length) {
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll * 0.8) {
      _loadMoreLines();
    }
  }

  Future<void> _loadLogs() async {
    try {
      final file = await getLogsPath();
      final content = await file.readAsString();
      if (!mounted) return;

      _allLines = content.split('\n');
      if (_allLines.isNotEmpty && _allLines.last.isEmpty) {
        _allLines.removeLast();
      }
      _fullContent = content;

      final initialCount = _allLines.length < _initialLoadCount
          ? _allLines.length
          : _initialLoadCount;
      setState(() {
        _logLines
          ..clear()
          ..addAll(_allLines.take(initialCount));
        _displayedLines = initialCount;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _loadMoreLines() {
    if (_displayedLines >= _allLines.length) {
      return;
    }

    Future.microtask(() {
      if (!mounted) return;

      final remainingLines = _allLines.length - _displayedLines;
      final linesToLoad =
          remainingLines < _loadMoreCount ? remainingLines : _loadMoreCount;
      final newLines = _allLines.skip(_displayedLines).take(linesToLoad);

      setState(() {
        _logLines.addAll(newLines);
        _displayedLines += linesToLoad;
      });
    });
  }

  Future<void> _clearLogs(AppLocalizations l10n) async {
    final success = await clearLogs();
    if (!mounted) return;

    if (success) {
      setState(() {
        _logLines.clear();
        _allLines.clear();
        _fullContent = '';
        _displayedLines = 0;
      });
      NotificationToast.show(l10n.errorLogsCleared);
    } else {
      NotificationToast.show(l10n.errorLogsClearFailed);
    }
  }

  Future<void> _copyLogs(AppLocalizations l10n) async {
    try {
      await Clipboard.setData(ClipboardData(text: _fullContent));
      if (!mounted) return;
      NotificationToast.show(l10n.errorLogsCopied);
    } catch (_) {
      if (!mounted) return;
      NotificationToast.show(l10n.errorLogsCopyFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final l10n = AppLocalizations.of(context);
        final isWideScreen = ref.watch(settingsLayoutProvider);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.errorLogs),
            automaticallyImplyLeading: !isWideScreen,
          ),
          body: buildBody(context, l10n),
          floatingActionButton:
              _logLines.isEmpty ? null : buildFloatingButtons(l10n),
        );
      },
    );
  }

  Widget buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(child: Text(l10n.errorLogsLoadFailed));
    }
    if (_logLines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.errorLogsEmpty,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth < 600 ? 600.0 : screenWidth;
    return SelectionArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: contentWidth,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _logLines.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _logLines[index],
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildFloatingButtons(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'clearLogs',
          onPressed: () => _clearLogs(l10n),
          tooltip: l10n.errorLogsClear,
          child: const Icon(Icons.clear_all),
        ),
        const SizedBox(width: 15),
        FloatingActionButton(
          heroTag: 'copyLogs',
          onPressed: () => _copyLogs(l10n),
          tooltip: l10n.errorLogsCopy,
          child: const Icon(Icons.copy),
        ),
      ],
    );
  }
}
