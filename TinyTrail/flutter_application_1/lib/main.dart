import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrapState = await initializeFirebase();
  runApp(TinyTrailApp(bootstrapState: bootstrapState));
}
