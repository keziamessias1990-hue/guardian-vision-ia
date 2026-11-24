import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pais/app.dart';
void main() {
  testWidgets('não exibe alertas fictícios silenciosamente', (tester) async {
    await tester.pumpWidget(const GuardianApp());
    await tester.pump();
    expect(find.text('Não autenticado'), findsWidgets);
    expect(find.text('Guilherme'), findsNothing);
  });
}
