import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pais/app.dart';
import 'package:guardian_pais/services/api_service.dart';
import 'package:http/http.dart' as http;

class FakeApiClient extends http.BaseClient {
  FakeApiClient({this.children = const [], this.alerts = const []});

  final List<Map<String, dynamic>> children;
  final List<Map<String, dynamic>> alerts;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));

    late final String body;
    if (request.url.path.endsWith('/children')) {
      body = jsonEncode(children);
    } else if (request.url.path.endsWith('/alerts')) {
      body = jsonEncode(alerts);
    } else if (request.url.path.endsWith('/auth/login')) {
      body = jsonEncode({
        'token': 'fake-token',
        'parent': {
          'id': 'parent-1',
          'name': 'Mãe responsável',
          'email': 'mae@guardianvision.local',
          'createdAt': '2026-11-11T00:00:00.000Z',
        },
      });
    } else {
      body = jsonEncode([]);
    }

    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      request: request,
    );
  }
}

void main() {
  testWidgets('exibe a tela inicial com a estrutura do fluxo parental', (tester) async {
    ApiService.configureForTesting(
      client: FakeApiClient(
        children: const [
          {
            'id': 'child-1',
            'parentId': 'parent-1',
            'name': 'Ana',
            'ageGroup': '10-12',
            'status': 'pending',
            'createdAt': '2026-11-11T00:00:00.000Z',
          },
        ],
        alerts: const [
          {
            'id': 'alert-1',
            'childId': 'child-1',
            'category': 'secret-sharing',
            'severity': 'medium',
            'source': 'demo',
            'summary': 'Pedido de segredo e mudança para outra plataforma.',
            'occurredAt': '2026-11-11T00:00:00.000Z',
            'confirmationState': 'pending',
          },
        ],
      ),
    );

    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();

    expect(find.text('Guardian Vision'), findsOneWidget);
    expect(find.text('Comece por aqui'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.byKey(const ValueKey('pairing_button')), findsOneWidget);

    ApiService.resetClient();
  });

  testWidgets('abre a demonstração de alerta ao solicitar exploração', (tester) async {
    ApiService.configureForTesting(
      client: FakeApiClient(
        children: const [],
        alerts: const [],
      ),
    );

    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();

    final demoButton = find.byKey(const ValueKey('explore_demo_button'));
    await tester.ensureVisible(demoButton);
    await tester.tap(demoButton);
    await tester.pumpAndSettle();

    expect(find.text('Possível sinal de risco'), findsOneWidget);
    expect(find.text('Pedido de segredo'), findsOneWidget);
    expect(find.text('Mudança de plataforma'), findsOneWidget);
    expect(find.text('A continuidade em outro aplicativo não foi confirmada.'), findsOneWidget);

    ApiService.resetClient();
  });

  testWidgets('abre o diálogo de pareamento', (tester) async {
    ApiService.configureForTesting(
      client: FakeApiClient(
        children: const [],
        alerts: const [],
      ),
    );

    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pairing_button')));
    await tester.pumpAndSettle();

    expect(find.text('Pareamento futuro'), findsOneWidget);
    expect(
      find.text(
        'O pareamento do app da criança será implementado após a integração com o backend. Neste protótipo, a conexão real ainda não está disponível.',
      ),
      findsOneWidget,
    );

    ApiService.resetClient();
  });
}