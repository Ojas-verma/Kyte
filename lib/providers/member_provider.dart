import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/member.dart';
import '../services/firestore_service.dart';

class MemberProvider extends ChangeNotifier {
  MemberProvider(this._service) {
    unawaited(_connect());
  }

  final FirestoreService _service;
  StreamSubscription<List<Member>>? _subscription;

  List<Member> _members = <Member>[];
  bool _isLoading = true;
  String? _errorMessage;

  List<Member> get members => List.unmodifiable(_members);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDemoMode => _service.isDemoMode;

  Future<void> _connect() async {
    _subscription = _service.watchMembers().listen(
      (members) {
        _members = List<Member>.from(members)
          ..sort((left, right) => left.name.compareTo(right.name));
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    if (_service.isDemoMode) {
      _service.emitCurrentMembers();
    }
  }

  Future<void> addMember(Member member) => _service.addMember(member);

  Future<void> updateMember(Member member) => _service.updateMember(member);

  Future<void> deleteMember(String memberId) => _service.deleteMember(memberId);

  Future<void> deleteSubtree(String memberId) => _service.deleteSubtree(memberId);

  Future<bool> isCircular(String memberId, String? newManagerId) =>
      _service.isCircular(memberId, newManagerId);

  Future<List<Member>> getMembersOnce() => _service.getMembersOnce();

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _service.dispose();
    super.dispose();
  }
}
