import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyte/models/member.dart';
import 'package:kyte/widgets/org_tree_view.dart';

void main() {
  testWidgets('tapping child node opens child profile sheet', (
    WidgetTester tester,
  ) async {
    final members = <Member>[
      const Member(
        id: 'root-1',
        name: 'Root Leader',
        role: 'Engineering Manager',
        department: 'Engineering',
        team: 'Platform',
      ),
      const Member(
        id: 'child-1',
        name: 'Child Engineer',
        role: 'SDE II',
        department: 'Engineering',
        team: 'Platform',
        managerId: 'root-1',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrgTreeView(members: members, onAddRequested: () {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Child Engineer').first);
    await tester.pumpAndSettle();

    expect(find.text('Member ID'), findsOneWidget);
    expect(find.text('child-1'), findsOneWidget);
  });
}
