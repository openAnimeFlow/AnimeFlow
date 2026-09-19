import 'package:anime_flow/shared/models/bangumi/interest_item.dart';
import 'package:anime_flow/shared/models/bangumi/user_collections_item.dart';
import 'package:anime_flow/shared/models/flow/collection_update_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local collections and detail interests allow missing remote IDs', () {
    final json = <String, dynamic>{'id': null, 'type': 3, 'updatedAt': null};
    final listInterest = UserCollectionInterest.fromJson(json);
    final detailInterest = InterestItem.fromJson(json);
    expect(listInterest.id, isNull);
    expect(detailInterest.id, isNull);
    expect(listInterest.type, 3);
    expect(detailInterest.type, 3);
    expect(detailInterest.tags, isEmpty);
    expect(listInterest.updatedAt, 0);
    expect(UserCollectionInterest.fromJson(listInterest.toJson()).id, isNull);
  });

  test('partial remote failure is a successful local save', () {
    for (final status in ['PENDING', 'AUTH_REQUIRED', 'CONFLICT']) {
      final result = CollectionUpdateResult.fromResponse({
        'localSaved': true,
        'remoteSyncStatus': status,
        'localVersion': 12,
      });
      expect(result.remoteSyncStatus.apiValue, status);
      expect(result.localVersion, 12);
    }
  });

  test('legacy and unknown responses never imply successful synchronization',
      () {
    expect(CollectionUpdateResult.fromResponse('success').remoteSyncStatus,
        CollectionRemoteSyncStatus.unknown);
    expect(
        CollectionUpdateResult.fromResponse({
          'localSaved': true,
          'remoteSyncStatus': 'NEW_SERVER_STATUS',
        }).remoteSyncStatus,
        CollectionRemoteSyncStatus.unknown);
    expect(() => CollectionUpdateResult.fromResponse({'localSaved': false}),
        throwsFormatException);
  });
}
