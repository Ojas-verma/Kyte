import 'package:flutter_test/flutter_test.dart';
import 'package:kyte/models/member.dart';
import 'package:kyte/utils/tree_builder.dart';

void main() {
  test('buildTree creates nested children and multiple roots', () {
    final members = <Member>[
      const Member(
        id: 'root-a',
        name: 'Alpha',
        role: 'Engineering Manager',
        department: 'Engineering',
        team: 'Platform',
      ),
      const Member(
        id: 'root-b',
        name: 'Beta',
        role: 'Product Manager',
        department: 'Product',
        team: 'Growth',
      ),
      const Member(
        id: 'child-a1',
        name: 'Alpha Child',
        role: 'SDE II',
        department: 'Engineering',
        team: 'Platform',
        managerId: 'root-a',
      ),
      const Member(
        id: 'grandchild-a1',
        name: 'Alpha Grandchild',
        role: 'SDE I',
        department: 'Engineering',
        team: 'Platform',
        managerId: 'child-a1',
      ),
    ];

    final tree = buildTree(members);

    expect(tree, hasLength(2));
    expect(tree.first.member.id, 'root-a');
    expect(tree.last.member.id, 'root-b');
    expect(tree.first.children, hasLength(1));
    expect(tree.first.children.first.member.id, 'child-a1');
    expect(tree.first.children.first.children, hasLength(1));
    expect(tree.first.children.first.children.first.member.id, 'grandchild-a1');
    expect(tree.last.children, isEmpty);
  });
}
