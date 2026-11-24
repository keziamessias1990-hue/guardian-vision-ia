import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_kids/notification_settings.dart';
import 'package:guardian_kids/services/guardian_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('consulta fontes do Pais sem permitir edição e exige aceite',
      (tester) async {
    const channel = MethodChannel('guardian/notification_controls');
    final messenger = tester.binding.defaultBinaryMessenger;
    GuardianApi.childId = 'child-test';
    GuardianApi.deviceToken = 'token-test';
    List<String> sources = [];
    var starts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'status':
          return {
            'access': true,
            'connected': true,
            'indicatorAllowed': true,
            'sources': sources
          };
        case 'start':
          expect(call.arguments['childId'], 'child-test');
          sources = (call.arguments['sources'] as List).cast<String>();
          starts++;
          return true;
        case 'stop':
          sources = [];
          return null;
        default:
          fail('Chamada inesperada: ${call.method}');
      }
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      GuardianApi.childId = null;
      GuardianApi.deviceToken = null;
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(child: NotificationSettings())),
      ));
      await tester.tap(find.text('Proteção de notificações pausada'));
      await tester.pumpAndSettle();

      final enable =
          find.widgetWithText(FilledButton, 'Ativar alertas automáticos');
      expect(tester.widget<FilledButton>(enable).onPressed, isNull);
      await tester.tap(find.text('Consultar aplicativos autorizados'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(enable).onPressed, isNull);
      expect(find.widgetWithText(CheckboxListTile, 'Discord'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Discord'), findsOneWidget);
      final consent = find.text(
          'Li com meu responsável e concordamos em ativar os alertas automáticos.');
      await tester.ensureVisible(consent);
      await tester.tap(consent);
      await tester.pumpAndSettle();
      await tester.ensureVisible(enable);
      await tester.tap(enable);
      await tester.pumpAndSettle();

      expect(starts, 1);
      expect(sources, ['com.discord']);
      expect(find.text('Proteção de notificações ativa'), findsOneWidget);
      final pause = find.text('Pausar análise');
      await tester.ensureVisible(pause);
      await tester.tap(pause);
      await tester.pumpAndSettle();
      expect(sources, ['com.discord']);
      await tester.enterText(find.byType(TextField), 'senha-ficticia');
      await tester.tap(find.text('Confirmar pausa'));
      await tester.pumpAndSettle();
      expect(sources, isEmpty);
      expect(find.text('Proteção de notificações pausada'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/device/confirm-control')) {
                return http.Response('{"confirmed":true}', 201);
              }
              expect(request.url.path, endsWith('/device/protection'));
              return http.Response('{"sources":["com.discord"]}', 200);
            }));
  });
}
