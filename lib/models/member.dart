import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.team,
    this.managerId,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String role;
  final String department;
  final String team;
  final String? managerId;
  final String? photoUrl;

  bool get hasManager => managerId != null && managerId!.isNotEmpty;

  Member copyWith({
    String? id,
    String? name,
    String? role,
    String? department,
    String? team,
    String? managerId,
    String? photoUrl,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      team: team ?? this.team,
      managerId: managerId ?? this.managerId,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory Member.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Member.fromMap(doc.data() ?? <String, dynamic>{}, id: doc.id);
  }

  factory Member.fromMap(Map<String, dynamic> map, {String? id}) {
    return Member(
      id: (id ?? map['id'] as String? ?? '').trim(),
      name: (map['name'] as String? ?? '').trim(),
      role: (map['role'] as String? ?? '').trim(),
      department: (map['department'] as String? ?? '').trim(),
      team: (map['team'] as String? ?? '').trim(),
      managerId: map['managerId'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'role': role,
      'department': department,
      'team': team,
      'managerId': managerId,
      'photoUrl': photoUrl,
    };
  }
}
