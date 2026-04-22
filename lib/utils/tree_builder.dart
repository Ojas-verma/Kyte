import '../models/member.dart';

class TreeNode {
  const TreeNode({required this.member, required this.children});

  final Member member;
  final List<TreeNode> children;

  bool get hasChildren => children.isNotEmpty;
}

List<TreeNode> buildTree(List<Member> members) {
  final childrenByManagerId = <String, List<Member>>{};
  final roots = <Member>[];

  for (final member in members) {
    final managerId = member.managerId;
    if (managerId == null || managerId.isEmpty) {
      roots.add(member);
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
    );
  }

  return roots.map(buildNode).toList(growable: false);
}
