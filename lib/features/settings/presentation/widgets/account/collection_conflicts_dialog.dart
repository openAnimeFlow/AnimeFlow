import 'package:anime_flow/shared/models/flow/bgm_collection_sync_status_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/features/user/data/repository/collection_sync_repository.dart';
import 'package:anime_flow/features/user/application/bgm_collection_sync_provider.dart';
import 'package:anime_flow/features/user/presentation/providers/user_state_provider.dart';
import 'package:anime_flow/shared/models/flow/collection_conflict_item.dart';

String collectionTypeLabel(AppLocalizations l, int? type) => switch (type) {
      1 => l.collectionPlanToWatch,
      2 => l.collectionWatched,
      3 => l.collectionWatching,
      4 => l.collectionOnHold,
      5 => l.collectionAbandoned,
      _ => '—',
    };

class CollectionConflictsDialog extends ConsumerStatefulWidget {
  const CollectionConflictsDialog({super.key, required this.taskId});
  final int taskId;
  @override
  ConsumerState<CollectionConflictsDialog> createState() =>
      _CollectionConflictsDialogState();
}

class _CollectionConflictsDialogState
    extends ConsumerState<CollectionConflictsDialog> {
  static const _limit = 20;
  final _items = <CollectionConflictItem>[];
  final _selected = <int, (int, int)>{}; // conflict version and choice
  bool _busy = false, _hasMore = true, _requiresRefresh = false;
  bool _accepted = false, _submitError = false, _loadError = false;
  int _offset = 0;
  late final (String?, int?) _owner;

  (String?, int?) get _identity => (
        ref.read(currentFlowTokenProvider).value?.sessionId,
        ref.read(bangumiBindProvider).value?.platformUid,
      );
  bool get _valid =>
      mounted &&
      _identity == _owner &&
      ref.read(bangumiBindProvider).value?.bound == true;

  @override
  void initState() {
    super.initState();
    _owner = _identity;
    Future.microtask(() => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy || !_valid) return;
    setState(() {
      _busy = true;
      _loadError = false;
    });
    try {
      final page = await ref
          .read(collectionSyncRepositoryProvider)
          .conflicts(widget.taskId, reset ? 0 : _offset, _limit);
      if (!_valid) return;
      setState(() {
        if (reset) {
          _items.clear();
          _offset = 0;
        }
        _offset += page.length;
        final ids = _items.map((e) => e.conflictId).toSet();
        for (final item in page) {
          if (ids.add(item.conflictId)) _items.add(item);
          final draft = _selected[item.conflictId];
          if (draft != null && draft.$1 != item.conflictVersion) {
            _selected.remove(item.conflictId);
          }
        }
        if (reset) {
          final fresh = page.map((e) => e.conflictId).toSet();
          _selected.removeWhere((id, _) => !fresh.contains(id));
        }
        _hasMore = page.length == _limit;
        _requiresRefresh = false;
      });
    } catch (_) {
      if (_valid) {
        setState(() {
          _loadError = true;
          if (reset) _requiresRefresh = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _chooseSide(bool local) {
    setState(() {
      for (final item in _items) {
        final type = local ? item.localType : item.remoteType;
        if (type != null && type >= 1 && type <= 5) {
          _selected[item.conflictId] = (item.conflictVersion, type);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_busy || !_valid || _requiresRefresh || _selected.isEmpty) return;
    final body = _items
        .where((e) => _selected.containsKey(e.conflictId))
        .map((e) => {
              'conflictId': e.conflictId,
              'conflictVersion': _selected[e.conflictId]!.$1,
              'selectedType': _selected[e.conflictId]!.$2,
            })
        .toList();
    setState(() {
      _busy = true;
      _submitError = false;
      _accepted = false;
    });
    try {
      await ref
          .read(collectionSyncRepositoryProvider)
          .resolve(widget.taskId, body);
      if (!_valid) return;
      setState(() {
        _accepted = true;
        for (final entry in body) {
          _selected.remove(entry['conflictId']);
        }
      });
    } catch (_) {
      if (_valid) {
        setState(() {
          _submitError = true;
          _requiresRefresh = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!_valid) return;
    // The endpoint may accept a prefix of the batch before rejecting a stale item.
    // Reload from offset zero because accepted items disappear from the conflict list.
    await _load(reset: true);
    if (!_valid) return;
    try {
      await ref.read(bgmCollectionSyncProvider.notifier).refreshStatus();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentFlowTokenProvider);
    ref.watch(bangumiBindProvider);
    final l10n = AppLocalizations.of(context);
    final task = ref.watch(bgmCollectionSyncProvider).value;
    final executionMessage = task?.taskId != widget.taskId
        ? l10n.syncAccepted
        : switch (task?.status) {
            BgmCollectionSyncStatus.success => l10n.syncStatusSuccess,
            BgmCollectionSyncStatus.partialFailed ||
            BgmCollectionSyncStatus.failed =>
              l10n.syncRetryMessage,
            BgmCollectionSyncStatus.cancelled => l10n.syncCancelled,
            BgmCollectionSyncStatus.waitingConflict => l10n.syncWaitingConflict,
            _ => l10n.syncAccepted,
          };
    final enabled = !_busy && _valid && !_requiresRefresh;
    return AlertDialog(
      title: Text(l10n.syncConflictsTitle),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择需要同步的类型'),
          Expanded(
            child: SizedBox(
              width: 600,
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: !_valid
                  ? Text(l10n.syncBindingChanged)
                  : Column(children: [
                      Wrap(spacing: 8, children: [
                        TextButton(
                            onPressed: enabled ? () => _chooseSide(true) : null,
                            child: Text(l10n.syncUseLocal)),
                        TextButton(
                            onPressed:
                                enabled ? () => _chooseSide(false) : null,
                            child: Text(l10n.syncUseRemote)),
                        TextButton(
                            onPressed: _busy ? null : () => _load(reset: true),
                            child: Text(l10n.refreshStatus)),
                      ]),
                      if (_busy) const LinearProgressIndicator(),
                      if (_accepted) Text(executionMessage),
                      if (_submitError)
                        Text(l10n.syncResolveFailed,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      if (_loadError) Text(l10n.collectionLoadFailed),
                      if (_requiresRefresh) Text(l10n.syncRefreshRequired),
                      Expanded(
                          child: ListView(children: [
                        if (_items.isEmpty && !_busy && !_loadError)
                          Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(l10n.syncNoConflicts)),
                        for (final item in _items)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.subjectName ??
                                            l10n.syncSubject(item.subjectId)),
                                        const SizedBox(height: 8),
                                        _ConflictTypeSelector(
                                          conflictId: item.conflictId,
                                          remoteType: item.remoteType,
                                          localType: item.localType,
                                          selectedType:
                                              _selected[item.conflictId]?.$2,
                                          enabled: enabled,
                                          onChanged: (type) => setState(() {
                                            if (type == null) {
                                              _selected.remove(item.conflictId);
                                            } else {
                                              _selected[item.conflictId] =
                                                  (item.conflictVersion, type);
                                            }
                                          }),
                                        ),
                                      ]))),
                        if (_hasMore && !_requiresRefresh)
                          TextButton(
                              onPressed: _busy ? null : () => _load(),
                              child: Text(
                                  _loadError ? l10n.retry : l10n.syncLoadMore)),
                      ])),
                    ]),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
        FilledButton(
            onPressed: enabled && _selected.isNotEmpty ? _submit : null,
            child: Text(l10n.syncSubmitSelected(_selected.length))),
      ],
    );
  }
}

/// A shared selection background slides horizontally between the two choices.
class _ConflictTypeSelector extends StatelessWidget {
  const _ConflictTypeSelector({
    required this.conflictId,
    required this.remoteType,
    required this.localType,
    required this.selectedType,
    required this.enabled,
    required this.onChanged,
  });

  final int conflictId;
  final int? remoteType, localType, selectedType;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  bool _valid(int? type) => type != null && type >= 1 && type <= 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    Widget side(String id, String name, int? type) {
      final selected = type != null && selectedType == type;
      return Expanded(
        child: Semantics(
          selected: selected,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('conflict-$conflictId-$id'),
              borderRadius: BorderRadius.circular(12),
              onTap: enabled && _valid(type) ? () => onChanged(type) : null,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(children: [
                  Text(name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(collectionTypeLabel(l10n, type),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurface)),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Column(children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: selectedType == null ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: AnimatedAlign(
                    alignment: selectedType == localType && selectedType != null
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      child: DecoratedBox(
                        key: ValueKey('conflict-$conflictId-highlight'),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(textDirection: TextDirection.ltr, children: [
              side('bangumi', 'Bangumi', remoteType),
              side('animeflow', 'AnimeFlow', localType),
            ]),
          ]),
        ),
      ),
      if (selectedType == null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(l10n.collectionSelectType,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ),
    ]);
  }
}
