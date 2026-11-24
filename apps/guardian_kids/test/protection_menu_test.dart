import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_kids/app.dart';
import 'package:guardian_kids/services/guardian_api.dart';

void main() {
  testWidgets('mostra o estado Android e abre Proteção e Privacidade',
      (tester) async {
    const channel = MethodChannel('guardian/notification_controls');
    final messenger = tester.binding.defaultBinaryMessenger;
    GuardianApi.deviceToken = 'linked-test-device';
    var sources = <String>['com.discord'];
    messenger.setMockMethodCallHandler(
        channel,
        (call) async => {
              'access': true,
              'connected': true,
              'indicatorAllowed': true,
              'sources': sources,
            });
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      GuardianApi.deviceToken = null;
    });

    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Este celular está sendo acompanhado'),
        findsOneWidget);

    sources = [];
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Acompanhamento pausado'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proteção'));
    await tester.pumpAndSettle();
    expect(find.text('Proteção de notificações pausada'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacidade'));
    await tester.pumpAndSettle();
    expect(find.text('Privacidade e transparência'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
