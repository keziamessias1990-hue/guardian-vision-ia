import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_pais/services/api_service.dart';

void main() {
  test('mostra estado confirmado, revisão pendente e perda de comunicação', () {
    final now = DateTime.utc(2026, 11, 23, 12);
    ApiChild profile(String status, {int revision = 1}) => ApiChild.fromJson({
          'status': 'linked',
          'protectionRevision': revision,
          'protectionReport': {
            'status': status,
            'revision': 1,
            'reportedAt': now.toIso8601String(),
          },
        });
    expect(profile('active').protectionLabel(now), 'Ativo');
    expect(profile('paused').protectionLabel(now), 'Pausado');
    expect(profile('active', revision: 2).protectionLabel(now),
        'Aguardando atualização');
    expect(
        profile('active').protectionLabel(now.add(const Duration(seconds: 45))),
        'Sem comunicação');
  });
}
