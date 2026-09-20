import 'package:anime_flow/app/localization/app_localizations.dart';
import 'package:anime_flow/shared/models/flow/collection_update_result.dart';
import 'package:anime_flow/shared/widgets/notification_toast.dart';
import 'package:flutter/widgets.dart';

String collectionSaveMessage(
        AppLocalizations l10n, CollectionRemoteSyncStatus status) =>
    switch (status) {
      CollectionRemoteSyncStatus.localOnly => l10n.collectionSavedLocally,
      CollectionRemoteSyncStatus.pending => l10n.collectionSavedPending,
      CollectionRemoteSyncStatus.authRequired =>
        l10n.collectionSavedAuthRequired,
      CollectionRemoteSyncStatus.conflict => l10n.collectionSavedConflict,
      CollectionRemoteSyncStatus.synced => l10n.collectionSavedSynced,
      CollectionRemoteSyncStatus.unknown => l10n.collectionSaved,
    };

void showCollectionSaveNotice(
    BuildContext context, CollectionUpdateResult? result) {
  if (result == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  NotificationToast.show(
    collectionSaveMessage(l10n, result.remoteSyncStatus),
    title: l10n.tip,
    maxWidth: 500,
  );
}
