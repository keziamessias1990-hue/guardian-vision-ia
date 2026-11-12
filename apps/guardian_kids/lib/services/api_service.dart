import 'dart:convert';

import 'package:http/http.dart' as http;

class KidAlertPayload {
  const KidAlertPayload({
    required this.childId,
    required this.category,
    required this.severity,
    required this.summary,
    this.source = 'guardian_kids',
  });

  final String childId;
  final String category;
  final String severity;
  final String summary;
  final String source;

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'category': category,
      'severity': severity,
      'summary': summary,
      'source': source,
    };
  }
}

class KidApiService {
  static const List<String> _baseUrls = <String>[
    'http://127.0.0.1:3000/api',
    'http://127.0.0.1:3001/api',
    'http://localhost:3000/api',
    'http://localhost:3001/api',
  ];

  static http.Client _client = http.Client();

  static void configureForTesting({required http.Client client}) {
    _client = client;
  }

  static void resetClient() {
    _client = http.Client();
  }

  static Future<bool> sendAlert(KidAlertPayload payload) async {
    Object? lastError;

    for (final baseUrl in _baseUrls) {
      try {
        final response = await _client.post(
          Uri.parse('$baseUrl/alerts'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload.toJson()),
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }

        lastError = http.ClientException('status ${response.statusCode}');
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      return false;
    }

    return false;
  }
}
