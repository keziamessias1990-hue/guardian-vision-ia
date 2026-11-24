import 'dart:async';

import 'package:flutter/services.dart';

import '../ai/risk_engine.dart';
import 'guardian_api.dart';

const _channel = MethodChannel('guardian/notification_worker');

void startNotificationWorker() {
  final engine = GuardianRiskEngine();
  _channel.setMethodCallHandler((call) {
    if (call.method != 'analyze') return Future<void>.value();
    final event = call.arguments as Map;
    final analysis = engine.analyze(event['text'] as String);
    if (!analysis.requiresAttention) return Future<void>.value();

    // The asynchronous delivery path receives only the classification and time.
    return _deliver(
      event['id'] as int,
      event['time'] as int,
      analysis.category,
      analysis.severity,
    );
  });
  _channel.invokeMethod<void>('ready').then((_) {
    var syncing = false;
    Future<void> sync() async {
      if (syncing) return;
      syncing = true;
      String? token;
      try {
        token = await _channel.invokeMethod<String>('policyLink');
        if (token == null) return;
        final policy = await GuardianApi.protectionPolicy(token);
        final state = await _channel.invokeMethod<String>('applyPolicy', {
          'deviceToken': token,
          'sources': policy.sources,
        });
        if (state != null)
          await GuardianApi.reportProtection(token, state, policy.revision);
      } on GuardianAlertException catch (error) {
        if (error.status == 401 && token != null) {
          await _channel
              .invokeMethod<void>('invalidateLink', {'deviceToken': token});
        }
      } on Exception {
        // The Android listener expires the active window without a fresh policy.
      } finally {
        syncing = false;
      }
    }

    unawaited(sync());
    Timer.periodic(const Duration(seconds: 15), (_) => unawaited(sync()));
  });
}

Future<void> _deliver(
    int id, int time, String category, String severity) async {
  final session = await _channel.invokeMapMethod<String, String>('session', {
    'id': id,
  });
  if (session == null) return;
  try {
    await GuardianApi.notificationAlert(
      childId: session['childId']!,
      deviceToken: session['token']!,
      category: category,
      severity: severity,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(time, isUtc: true),
    );
  } on GuardianAlertException catch (error) {
    if (error.status == 401) {
      await _channel.invokeMethod<void>('unlinked', {'id': id});
    }
  } on Exception {
    // MVP uses no offline queue or payload logs.
  }
}
