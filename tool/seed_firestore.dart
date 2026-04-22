import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

import 'package:kyte/utils/demo_member_seed.dart';

Future<void> main() async {
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  final collection = firestore.collection('members');

  for (final member in demoMembers) {
    batch.set(collection.doc(member.id), member.toMap());
  }

  await batch.commit();
  stdout.writeln('Seeded ${demoMembers.length} members into Firestore.');
}
