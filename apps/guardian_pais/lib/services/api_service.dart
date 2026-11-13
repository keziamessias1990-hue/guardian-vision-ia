import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiChild {
  const ApiChild({
    required this.id,
    required this.parentId,
    required this.name,
    required this.ageGroup,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String parentId;
  final String name;
  final String ageGroup;
  final String status;
  final String createdAt;

  factory ApiChild.fromJson(Map<String, dynamic> json) {
    return ApiChild(
      id: (json['id'] ?? '').toString(),
      parentId: (json['parentId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      ageGroup: (json['ageGroup'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class ApiAlert {
  const ApiAlert({
    required this.id,
    required this.childId,
    required this.category,
    required this.severity,
    required this.source,
    required this.summary,
    required this.occurredAt,
    required this.confirmationState,
  });

  final String id;
  final String childId;
  final String category;
  final String severity;
  final String source;
  final String summary;
  final String occurredAt;
  final String confirmationState;

  factory ApiAlert.fromJson(Map<String, dynamic> json) {
    return ApiAlert(
      id: (json['id'] ?? '').toString(),
      childId: (json['childId'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      severity: (json['severity'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      occurredAt: (json['occurredAt'] ?? '').toString(),
      confirmationState: (json['confirmationState'] ?? '').toString(),
    );
  }
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.children,
    required this.alerts,
  });

  final List<ApiChild> children;
  final List<ApiAlert> alerts;
}

class ApiService {
  static const List<String> _defaultBaseUrls = <String>[
    'http://127.0.0.1:3000/api',
    'http://127.0.0.1:3001/api',
    'http://localhost:3000/api',
    'http://localhost:3001/api',
  ];

  static String _baseUrl = _defaultBaseUrls.first;
  static http.Client _client = http.Client();

  static void configureBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  static Future<http.Response> _request(String path, {required String method, Map<String, String>? headers, String? body}) async {
    final candidates = _baseUrl.isNotEmpty ? <String>[_baseUrl] : _defaultBaseUrls;

    Object? lastError;
    for (final base in candidates) {
      try {
        final uri = Uri.parse('$base/$path');
        final response = method == 'POST'
            ? await _client.post(uri, headers: headers ?? const {}, body: body)
            : await _client.get(uri);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        if (response.statusCode == 404 || response.statusCode == 500) {
          throw http.ClientException('Endpoint unavailable at $base');
        }

        return response;
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? const FormatException('Não foi possível conectar com o backend.');
  }

  static Future<DashboardSnapshot> fetchDashboard() async {
    final children = await fetchChildren();
    final alerts = await fetchAlerts();
    return DashboardSnapshot(children: children, alerts: alerts);
  }

  static Future<List<ApiChild>> fetchChildren() async {
    final response = await _request('children', method: 'GET');
    _ensureSuccess(response, 'children');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const <ApiChild>[];
    }

    return decoded
        .map((item) => ApiChild.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<List<ApiAlert>> fetchAlerts() async {
    final response = await _request('alerts', method: 'GET');
    _ensureSuccess(response, 'alerts');

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      return const <ApiAlert>[];
    }

    return decoded
        .map((item) => ApiAlert.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static void _ensureSuccess(http.Response response, String label) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Falha ao consultar $label (status ${response.statusCode}): ${response.body}',
      );
    }
  }
}
