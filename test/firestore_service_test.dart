import 'package:flutter_test/flutter_test.dart';
import 'package:kyte/models/member.dart';
import 'package:kyte/services/firestore_service.dart';

void main() {
  test('returns members sorted by name in demo mode', () async {
    final service = FirestoreService(demoMode: true);

    final members = await service.getMembersOnce();
    final sortedNames = [...members.map((member) => member.name)]..sort();

    expect(members.map((member) => member.name).toList(), sortedNames);
  });

  test('adds, updates, and fetches member by id in demo mode', () async {
    final service = FirestoreService(demoMode: true);
    const member = Member(
      id: '',
      name: 'Zara Hussain',
      role: 'SDE II',
      department: 'Engineering',
      team: 'Platform',
      managerId: 'eng-mgr-001',
    );

    final memberId = await service.addMember(member);
    final added = await service.getMemberById(memberId);

    expect(memberId, startsWith('demo-'));
    expect(added, isNotNull);
    expect(added?.name, 'Zara Hussain');

    await service.updateMember(
      added!.copyWith(role: 'Senior Software Engineer'),
    );
    final updated = await service.getMemberById(memberId);

    expect(updated, isNotNull);
    expect(updated?.role, 'Senior Software Engineer');
  });

  test('deletes member in demo mode', () async {
    final service = FirestoreService(demoMode: true);
    const member = Member(
      id: '',
      name: 'Delete Candidate',
      role: 'QA / Test Engineer',
      department: 'Quality',
      team: 'Automation',
    );

    final memberId = await service.addMember(member);
    expect(await service.getMemberById(memberId), isNotNull);

    await service.deleteMember(memberId);

    expect(await service.getMemberById(memberId), isNull);
  });

  test('watchMembers emits current and updated lists in demo mode', () async {
    final service = FirestoreService(demoMode: true);
    final emittedCounts = <int>[];
    final subscription = service.watchMembers().listen((members) {
      emittedCounts.add(members.length);
    });

    service.emitCurrentMembers();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await service.addMember(
      const Member(
        id: '',
        name: 'Stream Member',
        role: 'DevOps Engineer',
        department: 'Infrastructure',
        team: 'Platform',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(emittedCounts.length, greaterThanOrEqualTo(2));
    expect(emittedCounts[1], greaterThan(emittedCounts[0]));

    await subscription.cancel();
  });

  test('detects circular manager assignments in demo mode', () async {
    final service = FirestoreService(demoMode: true);

    expect(await service.isCircular('eng-001', 'eng-003'), isTrue);
    expect(await service.isCircular('eng-003', 'ceo-001'), isFalse);
    expect(await service.isCircular('eng-001', 'eng-001'), isTrue);
  });

  test('deletes a subtree in demo mode', () async {
    final service = FirestoreService(demoMode: true);

    await service.deleteSubtree('eng-mgr-001');
    final remainingIds = (await service.getMembersOnce())
        .map((member) => member.id)
        .toSet();

    expect(remainingIds.contains('eng-mgr-001'), isFalse);
    expect(remainingIds.contains('eng-001'), isFalse);
    expect(remainingIds.contains('eng-002'), isFalse);
    expect(remainingIds.contains('eng-003'), isFalse);
    expect(remainingIds.contains('ceo-001'), isTrue);
    expect(remainingIds.contains('product-001'), isTrue);
  });
}
