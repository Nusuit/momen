import 'package:flutter/widgets.dart';
import 'package:momen/app.dart';
import 'package:momen/app/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  await AppBootstrap.initialize();
  runApp(const MomenApp());
}
