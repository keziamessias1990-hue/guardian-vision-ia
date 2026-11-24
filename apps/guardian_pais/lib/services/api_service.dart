import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ApiChild {
  const ApiChild({
    required this.id,
    required this.parentId,
    required this.name,
    required this.ageGroup,
    required this.status,
    required this.createdAt,
    this.protectionSources = const [],
    this.protectionRevision = 0,
    this.reportedRevision,
    this.reportedStatus,
    this.reportedAt,
  });
  final String id, parentId, name, ageGroup, status, createdAt;
  final List<String> protectionSources;
  final int protectionRevision;
  final int? reportedRevision;
  final String? reportedStatus;
  final DateTime? reportedAt;

  String protectionLabel(DateTime now) {
    if (status != 'linked') return 'Aguardando pareamento';
    final lastReport = reportedAt;
    if (lastReport == null || now.difference(lastReport) >= const Duration(seconds: 45)) {
      return 'Sem comunicação';
    }
    if (reportedRevision != protectionRevision) return 'Aguardando atualização';
    return switch (reportedStatus) {
      'active' => 'Ativo',
      'paused' => 'Pausado',
      _ => 'Sem comunicação',
    };
  }

  factory ApiChild.fromJson(Map<String, dynamic> json) {
    final report = json['protectionReport'] as Map<String, dynamic>?;
    return ApiChild(
      id: '${json['id']}',
      parentId: '${json['parentId']}',
      name: '${json['name']}',
      ageGroup: '${json['ageGroup']}',
      status: '${json['status']}',
      createdAt: '${json['createdAt']}',
      protectionSources: (json['protectionSources'] as List?)?.whereType<String>().toList() ?? const [],
      protectionRevision: json['protectionRevision'] as int? ?? 0,
      reportedRevision: report?['revision'] as int?,
      reportedStatus: report?['status'] as String?,
      reportedAt: DateTime.tryParse(report?['reportedAt'] as String? ?? ''),
    );
  }
}
class ApiAlert {
  const ApiAlert({required this.id, required this.childId, required this.category, required this.severity, required this.source, required this.occurredAt, required this.confirmationState, this.contested = false});
  final String id, childId, category, severity, source, occurredAt, confirmationState;
  final bool contested;
  String get originLabel => switch (source) {
    'guardian-kids-notification' => 'API · Notificação analisada pelo Guardian Kids',
    'guardian-kids-local' => 'API · Teste manual do Guardian Kids',
    _ => 'API · Origem não reconhecida',
  };
  String get summary => switch (category) {
    'secret-sharing' => 'Possível pedido de segredo',
    'platform-change' => 'Possível convite para outro aplicativo',
    'personal-data' => 'Possível solicitação de dados pessoais',
    _ => 'Possível sinal de risco',
  };
  factory ApiAlert.fromJson(Map<String,dynamic> j) => ApiAlert(id: '${j['id']}', childId: '${j['childId']}', category: '${j['category']}', severity: '${j['severity']}', source: '${j['source']}', occurredAt: '${j['occurredAt']}', confirmationState: '${j['confirmationState']}', contested: j['contested'] == true);
}
class DashboardSnapshot {
  const DashboardSnapshot({required this.children, required this.alerts});
  final List<ApiChild> children;
  final List<ApiAlert> alerts;
}
class ApiRequestException implements Exception {
  const ApiRequestException(this.status, this.body);

  final int status;
  final String body;

  String? get message {
    try {
      final data = jsonDecode(body);
      return data is Map && data['message'] is String
          ? data['message'] as String
          : null;
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => 'Exception: API $status: $body';
}

class ApiService {
  static const String baseUrl = String.fromEnvironment('GUARDIAN_API_URL', defaultValue: 'http://10.0.2.2:3000/api');
  static String? accessToken;
  static const _sessionStorage = MethodChannel('guardian/parent_session');
  static bool get _canPersist => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> restoreSession() async {
    if (!_canPersist) return;
    try {
      accessToken = await _sessionStorage.invokeMethod<String>('load');
    } on PlatformException {
      accessToken = null;
    } on MissingPluginException {
      accessToken = null;
    }
  }

  static Future<void> clearSession() async {
    accessToken = null;
    if (_canPersist) await _sessionStorage.invokeMethod<void>('clear');
  }

  static Future<void> logout() async {
    // Snapshot the request before clearing the local token to avoid restoring it on a restart.
    final token = accessToken;
    await clearSession();
    if (token == null) return;
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
  }
  static Future<dynamic> request(String path, {String method = 'GET', Map<String,dynamic>? data, bool authenticated = true}) async {
    final uri = Uri.parse('$baseUrl/$path');
    final headers = {'Content-Type':'application/json', if (authenticated && accessToken != null) 'Authorization':'Bearer $accessToken'};
    final response = method == 'POST' ? await http.post(uri, headers: headers, body: jsonEncode(data ?? {})).timeout(const Duration(seconds: 10)) : await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiRequestException(response.statusCode, response.body);
    return jsonDecode(response.body);
  }
  static Future<String> profileEmail() async {
    final data = await request('auth/me');
    return data['email'] as String;
  }

  static Future<void> confirmPassword(String password) async {
    await request('auth/confirm-password', method: 'POST', data: {'password': password});
  }

  static Future<void> register(String email, String password) async { await request('auth/register', method: 'POST', data: {'email':email,'password':password}, authenticated: false); }
  static Future<void> login(String email, String password) async {
    final response = await request('auth/login', method: 'POST', data: {
      'email': email,
      'password': password,
    }, authenticated: false);
    final token = response['accessToken'] as String;
    if (_canPersist) await _sessionStorage.invokeMethod<void>('save', {'token': token});
    accessToken = token;
  }
  static Future<ApiChild> addChild(String name, String ageGroup) async => ApiChild.fromJson(Map<String,dynamic>.from(await request('children',method:'POST',data:{'name':name,'ageGroup':ageGroup})));
  static Future<void> setProtectionSources(String childId, Set<String> sources) async {
    await request('children/$childId/protection', method: 'POST', data: {'sources': sources.toList()});
  }
  static Future<String> createPairing(String childId) async => (await request('children/$childId/pairings',method:'POST'))['pairingCode'] as String;
  static Future<void> contest(String id) async { await request('alerts/$id/contest',method:'POST'); }
  static Future<DashboardSnapshot> fetchDashboard() async => DashboardSnapshot(children: await fetchChildren(), alerts: await fetchAlerts());
  static Future<List<ApiChild>> fetchChildren() async => (await request('children') as List).map((v)=>ApiChild.fromJson(Map<String,dynamic>.from(v as Map))).toList();
  static Future<List<ApiAlert>> fetchAlerts() async => (await request('alerts') as List).map((v)=>ApiAlert.fromJson(Map<String,dynamic>.from(v as Map))).toList();
}
