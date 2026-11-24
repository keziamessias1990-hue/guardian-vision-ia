import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class GuardianApi {
  static const baseUrl = String.fromEnvironment('GUARDIAN_API_URL',
      defaultValue: 'http://10.0.2.2:3000/api');
  static const _controls = MethodChannel('guardian/notification_controls');
  static bool get _hasSecureStorage =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String? deviceToken;
  static String? childId;

  static void clearLocalLink() {
    childId = null;
    deviceToken = null;
  }

  static Future<void> restoreLink() async {
    if (!_hasSecureStorage) return;
    try {
      final data =
          await _controls.invokeMapMethod<String, String>('loadDeviceLink');
      if (data == null) return;
      childId = data['childId'];
      deviceToken = data['deviceToken'];
    } on PlatformException {
      clearLocalLink();
    } on MissingPluginException {
      clearLocalLink();
    }
  }

  static Future<void> pair(String code) async {
    final response = await http
        .post(Uri.parse('$baseUrl/pairings/confirm'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'pairingCode': code}))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201)
      throw Exception('Pareamento recusado (${response.statusCode})');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final id = data['childId'] as String;
    final token = data['deviceToken'] as String;
    if (_hasSecureStorage) {
      await _controls.invokeMethod<void>('saveDeviceLink', {
        'childId': id,
        'deviceToken': token,
      });
    }
    childId = id;
    deviceToken = token;
  }

  static Future<void> confirmProtectionControl(String password) async {
    final token = deviceToken;
    if (token == null) throw StateError('Dispositivo não pareado');
    final uri = Uri.parse('$baseUrl/device/confirm-control');
    if (uri.scheme != 'https' &&
        !(kDebugMode && uri.scheme == 'http' && uri.host == '10.0.2.2')) {
      throw StateError('Use HTTPS para confirmar a proteção');
    }
    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 201)
      throw GuardianAlertException(response.statusCode);
  }

  static Future<List<String>> protectionSources() async {
    final token = deviceToken;
    return token == null ? [] : (await protectionPolicy(token)).sources;
  }

  static Future<({List<String> sources, int revision})> protectionPolicy(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/device/protection'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200)
      throw GuardianAlertException(response.statusCode);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      sources: (data['sources'] as List).cast<String>(),
      revision: data['revision'] as int? ?? 0
    );
  }

  static Future<void> reportProtection(
      String token, String status, int revision) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/device/protection/status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'status': status, 'revision': revision}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 201)
      throw GuardianAlertException(response.statusCode);
  }

  static Future<void> notificationAlert({
    required String childId,
    required String deviceToken,
    required String category,
    required String severity,
    required DateTime occurredAt,
  }) =>
      _sendAlert(childId, deviceToken, category, severity, occurredAt,
          'guardian-kids-notification');

  static Future<void> _sendAlert(String childId, String token, String category,
      String severity, DateTime occurredAt, String source) async {
    final uri = Uri.parse('$baseUrl/alerts');
    if (source == 'guardian-kids-notification' &&
        uri.scheme != 'https' &&
        !(kDebugMode && uri.scheme == 'http' && uri.host == '10.0.2.2')) {
      throw StateError('Use HTTPS para os alertas de notificações');
    }
    final client = http.Client();
    try {
      final request = http.Request('POST', uri)
        ..followRedirects = false
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        })
        ..body = jsonEncode({
          'childId': childId,
          'category': category,
          'severity': severity,
          'occurredAt': occurredAt.toUtc().toIso8601String(),
          'confirmationState': 'pending',
          'source': source,
        });
      final response =
          await client.send(request).timeout(const Duration(seconds: 10));
      await response.stream.drain<void>().timeout(const Duration(seconds: 10));
      if (response.statusCode != 201)
        throw GuardianAlertException(response.statusCode);
    } finally {
      client.close();
    }
  }
}

class GuardianAlertException implements Exception {
  const GuardianAlertException(this.status);
  final int status;
  @override
  String toString() => 'Falha no envio ($status)';
}
