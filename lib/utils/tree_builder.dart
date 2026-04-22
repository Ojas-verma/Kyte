import '../models/member.dart';

class TreeNode {
  const TreeNode({
    required this.member,
    required this.children,
    this.isOrphan = false,
  });

  final Member member;
  final List<TreeNode> children;
  final bool isOrphan;

  bool get hasChildren => children.isNotEmpty;
}

List<TreeNode> buildTree(List<Member> members) {
  final memberIds = members.map((member) => member.id).toSet();
  final childrenByManagerId = <String, List<Member>>{};
  final roots = <Member>[];
  final orphanIds = <String>{};

  for (final member in members) {
    final managerId = member.managerId;
    if (managerId == null || managerId.isEmpty) {
      roots.add(member);
      continue;
    }

    if (!memberIds.contains(managerId)) {
      roots.add(member);
      orphanIds.add(member.id);
      continue;
    }

    childrenByManagerId.putIfAbsent(managerId, () => <Member>[]).add(member);
  }

  roots.sort((left, right) => left.name.compareTo(right.name));
  for (final entry in childrenByManagerId.entries) {
    entry.value.sort((left, right) => left.name.compareTo(right.name));
  }

  TreeNode buildNode(Member member) {
    final childMembers = childrenByManagerId[member.id] ?? <Member>[];
    return TreeNode(
      member: member,
      children: childMembers.map(buildNode).toList(growable: false),
      isOrphan: orphanIds.contains(member.id),
    );
  }

  return roots.map(buildNode).toList(growable: false);
}
