import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_kids/app.dart';

void main() {
  testWidgets('exibe a tela inicial', (tester) async {
    await tester.pumpWidget(const GuardianApp());
    expect(find.text('Seu espaço seguro e acolhedor'), findsOneWidget);
  });
}
