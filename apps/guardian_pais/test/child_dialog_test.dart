import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pais/app.dart';
import 'package:guardian_pais/services/api_service.dart';

void main() {
  testWidgets('fecha e reabre o cadastro infantil sem falhas', (tester) async {
    ApiService.accessToken = 'session-for-test';
    addTearDown(() => ApiService.accessToken = null);
    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filhos'));
    await tester.pumpAndSettle();

    final addChild = find.text('Adicionar criança');
    await tester.ensureVisible(addChild);
    await tester.tap(addChild);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Perfil fictício');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(addChild);
    await tester.pumpAndSettle();
    expect(find.text('Cadastrar perfil infantil'), findsOneWidget);
    expect(find.text('Perfil fictício'), findsNothing);
    expect(find.text('11-13'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
