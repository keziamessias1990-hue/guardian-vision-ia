import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pais/app.dart';

void main() {
  testWidgets('exibe o cenário atualizado com Guilherme vinculado', (tester) async {
    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();

    expect(find.text('Guardian Vision IA'), findsOneWidget);
    expect(find.text('Guilherme'), findsOneWidget);
    expect(find.text('Vinculada'), findsAtLeastNWidgets(1));
    expect(find.text('Alertas'), findsAtLeastNWidgets(1));
    expect(find.text('Análises recebidas'), findsOneWidget);
    expect(find.text('Crianças vinculadas'), findsOneWidget);
    expect(find.text('3'), findsAtLeastNWidgets(3));
    expect(find.text('1'), findsAtLeastNWidgets(1));
  });

  testWidgets('exibe um alerta de risco com conteúdo demonstrativo', (tester) async {
    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();

    expect(find.text('Pedido de segredo e continuação em outra plataforma.'), findsOneWidget);
    expect(find.text('Categoria: secret-sharing • Severidade: medium'), findsOneWidget);
  });

  testWidgets('renderiza ações e botões do dashboard', (tester) async {
    await tester.pumpWidget(const GuardianApp());
    await tester.pumpAndSettle();

    expect(find.byType(FilledButton), findsWidgets);
    expect(find.text('Vincular app da criança'), findsAtLeastNWidgets(1));
  });
}
