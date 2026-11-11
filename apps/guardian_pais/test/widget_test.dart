import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pais/app.dart';

void main() {
  testWidgets('exibe o estado inicial sem perfis vinculados', (tester) async {
    await tester.pumpWidget(const GuardianApp());

    expect(find.text('Comece por aqui'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(find.text('Nenhuma criança vinculada'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });

  testWidgets('abre a demonstração de alerta ao solicitar exploração', (tester) async {
    await tester.pumpWidget(const GuardianApp());

    await tester.ensureVisible(find.text('Explorar demonstração'));
    await tester.tap(find.text('Explorar demonstração'));
    await tester.pumpAndSettle();

    expect(find.text('Possível sinal de risco'), findsOneWidget);
    expect(find.text('Pedido de segredo'), findsOneWidget);
    expect(find.text('Mudança de plataforma'), findsOneWidget);
    expect(find.text('A continuidade em outro aplicativo não foi confirmada.'), findsOneWidget);
  });

  testWidgets('abre o diálogo de pareamento', (tester) async {
    await tester.pumpWidget(const GuardianApp());

    final buttonFinder = find.widgetWithText(FilledButton, 'Vincular app da criança');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Pareamento futuro'), findsOneWidget);
    expect(
      find.text(
        'O pareamento do app da criança será implementado após a integração com o backend. Neste protótipo, a conexão real ainda não está disponível.',
      ),
      findsOneWidget,
    );
  });
}
