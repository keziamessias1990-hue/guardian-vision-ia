import 'package:flutter/material.dart';
import 'app.dart';
import 'services/notification_worker.dart';
import 'services/guardian_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GuardianApi.restoreLink();
  runApp(const GuardianApp());
}

@pragma('vm:entry-point')
void notificationWorker() {
  WidgetsFlutterBinding.ensureInitialized();
  startNotificationWorker();
}
