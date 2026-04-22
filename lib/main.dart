import 'package:flutter/material.dart';

import 'app/bootstrap.dart';
import 'app/kyte_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  runApp(KyteApp(bootstrap: bootstrap));
}
