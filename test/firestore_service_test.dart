import 'package:flutter_test/flutter_test.dart';
import 'package:kyte/services/firestore_service.dart';

void main() {
  test('detects circular manager assignments in demo mode', () async {
    final service = FirestoreService(demoMode: true);

    expect(await service.isCircular('eng-001', 'eng-003'), isTrue);
    expect(await service.isCircular('eng-003', 'ceo-001'), isFalse);
    expect(await service.isCircular('eng-001', 'eng-001'), isTrue);
  });

  test('deletes a subtree in demo mode', () async {
    final service = FirestoreService(demoMode: true);

    await service.deleteSubtree('eng-mgr-001');
    final remainingIds = (await service.getMembersOnce()).map((member) => member.id).toSet();

    expect(remainingIds.contains('eng-mgr-001'), isFalse);
    expect(remainingIds.contains('eng-001'), isFalse);
    expect(remainingIds.contains('eng-002'), isFalse);
    expect(remainingIds.contains('eng-003'), isFalse);
    expect(remainingIds.contains('ceo-001'), isTrue);
    expect(remainingIds.contains('product-001'), isTrue);
  });
}
