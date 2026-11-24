import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pais/app.dart';

void main() {
  testWidgets('valida os campos de cadastro e login no próprio formulário', (
    tester,
  ) async {
    await tester.pumpWidget(const GuardianApp());
    final access = find.byIcon(Icons.login);
    await tester.ensureVisible(access);
    await tester.tap(access);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Use de 12 a 256 caracteres.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'teste@guardian.test');
    await tester.enterText(find.byType(TextFormField).last, 'curta');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsNothing);
    expect(find.text('Use de 12 a 256 caracteres.'), findsOneWidget);
    expect(find.text('Acesso do responsável'), findsOneWidget);
  });
}
