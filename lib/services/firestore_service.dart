import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member.dart';
import '../utils/demo_member_seed.dart';

class FirestoreService {
  FirestoreService({bool demoMode = false})
    : _demoMode = demoMode,
      _demoMembers = List<Member>.from(demoMembers),
      _demoController = StreamController<List<Member>>.broadcast();

  final bool _demoMode;
  final List<Member> _demoMembers;
  final StreamController<List<Member>> _demoController;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _firestoreClient {
    return _firestore ??= FirebaseFirestore.instance;
  }

  bool get isDemoMode => _demoMode;

  Future<List<Member>> getMembersOnce() async {
    if (_demoMode) {
      return _sortedDemoMembers();
    }

    final snapshot = await _firestoreClient.collection('members').get();
    final members = snapshot.docs.map(Member.fromFirestore).toList();
    members.sort((left, right) => left.name.compareTo(right.name));
    return members;
  }

  Future<Member?> getMemberById(String memberId) async {
    if (memberId.isEmpty) {
      return null;
    }

    if (_demoMode) {
      for (final member in _demoMembers) {
        if (member.id == memberId) {
          return member;
        }
      }
      return null;
    }

    final doc = await _firestoreClient.collection('members').doc(memberId).get();
    if (!doc.exists) {
      return null;
    }
    return Member.fromFirestore(doc);
  }

  Future<bool> isCircular(String memberId, String? newManagerId) async {
    if (newManagerId == null || newManagerId.isEmpty) {
      return false;
    }

    if (memberId == newManagerId) {
      return true;
    }

    var currentManagerId = newManagerId;
    final visited = <String>{};

    while (currentManagerId.isNotEmpty && visited.add(currentManagerId)) {
      if (currentManagerId == memberId) {
        return true;
      }

      final manager = await getMemberById(currentManagerId);
      if (manager == null) {
        return false;
      }

      currentManagerId = manager.managerId ?? '';
    }

    return false;
  }

  Stream<List<Member>> watchMembers() {
    if (_demoMode) {
      return _demoController.stream;
    }

    return _firestoreClient.collection('members').snapshots().map((snapshot) {
      final members = snapshot.docs.map(Member.fromFirestore).toList();
      members.sort((left, right) => left.name.compareTo(right.name));
      return members;
    });
  }

  void emitCurrentMembers() {
    if (!_demoMode || _demoController.isClosed) {
      return;
    }

    _demoController.add(_sortedDemoMembers());
  }

  Future<String> addMember(Member member) async {
    if (_demoMode) {
      final newMember = member.id.isEmpty
          ? member.copyWith(id: 'demo-${DateTime.now().millisecondsSinceEpoch}')
          : member;
      _demoMembers.add(newMember);
      emitCurrentMembers();
      return newMember.id;
    }

    final docRef = member.id.isEmpty
        ? _firestoreClient.collection('members').doc()
        : _firestoreClient.collection('members').doc(member.id);
    final payload = member.copyWith(id: docRef.id);
    await docRef.set(payload.toMap());
    return docRef.id;
  }

  Future<void> updateMember(Member member) async {
    if (_demoMode) {
      final index = _demoMembers.indexWhere((item) => item.id == member.id);
      if (index != -1) {
        _demoMembers[index] = member;
        emitCurrentMembers();
      }
      return;
    }

    await _firestoreClient
        .collection('members')
        .doc(member.id)
        .set(member.toMap());
  }

  Future<void> deleteMember(String memberId) async {
    if (_demoMode) {
      _demoMembers.removeWhere((member) => member.id == memberId);
      emitCurrentMembers();
      return;
    }

    await _firestoreClient.collection('members').doc(memberId).delete();
  }

  Future<void> deleteSubtree(String memberId) async {
    final members = await getMembersOnce();
    final idsToDelete = _collectSubtreeIds(memberId, members);

    if (_demoMode) {
      _demoMembers.removeWhere((member) => idsToDelete.contains(member.id));
      emitCurrentMembers();
      return;
    }

    const batchLimit = 500;
    var index = 0;
    while (index < idsToDelete.length) {
      final batch = _firestoreClient.batch();
      final chunkEnd = (index + batchLimit).clamp(0, idsToDelete.length);
      for (final id in idsToDelete.sublist(index, chunkEnd)) {
        batch.delete(_firestoreClient.collection('members').doc(id));
      }
      await batch.commit();
      index = chunkEnd;
    }
  }

  List<String> _collectSubtreeIds(String rootMemberId, List<Member> members) {
    final childLookup = <String, List<String>>{};
    for (final member in members) {
      final managerId = member.managerId;
      if (managerId == null || managerId.isEmpty) {
        continue;
      }

      childLookup.putIfAbsent(managerId, () => <String>[]).add(member.id);
    }

    final idsToDelete = <String>[];
    final queue = <String>[rootMemberId];

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      idsToDelete.add(currentId);
      queue.addAll(childLookup[currentId] ?? const <String>[]);
    }

    return idsToDelete;
  }

  List<Member> _sortedDemoMembers() {
    final members = List<Member>.from(_demoMembers);
    members.sort((left, right) => left.name.compareTo(right.name));
    return members;
  }

  void dispose() {
    _demoController.close();
  }
}
