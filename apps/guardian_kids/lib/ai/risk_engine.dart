
class RiskAnalysis {
  const RiskAnalysis({
    required this.category,
    required this.severity,
    required this.signals,
    required this.explanation,
    required this.requiresAttention,
  });

  final String category;
  final String severity;
  final List<String> signals;
  final String explanation;
  final bool requiresAttention;
}

class GuardianRiskEngine {
  String _normalize(String value) {
    var text = value.toLowerCase();

    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
    };

    accents.forEach((key, replacement) {
      text = text.replaceAll(key, replacement);
    });

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any((term) => text.contains(term));
  }

  RiskAnalysis analyze(String message) {
    final text = _normalize(message);
    final signals = <String>[];
    var score = 0;

    final secrecy = _containsAny(text, [
      'nao conte',
      'nao contar',
      'so entre nos',
      'nosso segredo',
      'guarde segredo',
      'esconda dos seus pais',
      'nao conte para seus pais',
      'nao conte pra ninguem',
      'nao fale para seus pais',
    ]);

    final migration = _containsAny(text, [
      'vamos para o discord',
      'conversar no discord',
      'me chama no discord',
      'vamos conversar no discord',
      'me chama no telegram',
      'vamos para o whatsapp',
      'outro aplicativo',
      'outro app',
    ]);

    final personalData = _containsAny(text, [
      'me passa seu endereco',
      'mande seu telefone',
      'me diga onde mora',
      'envie seu numero',
      'mande sua localizacao',
      'qual e seu endereco',
      'me manda uma foto sua',
    ]);

    final coercion = _containsAny(text, [
      'se voce contar',
      'vou te ameacar',
      'ninguem vai acreditar',
      'voce vai se arrepender',
      'vou divulgar suas fotos',
    ]);

    final isolation = _containsAny(text, [
      'seus pais nao entenderiam',
      'nao confie nos seus pais',
      'so eu te entendo',
      'nao precisa falar com sua familia',
    ]);

    if (secrecy) {
      score += 2;
      signals.add('Pedido de segredo');
    }

    if (migration) {
      score += 1;
      signals.add('Convite para outra plataforma');
    }

    if (personalData) {
      score += 3;
      signals.add('Solicitação de dados pessoais');
    }

    if (coercion) {
      score += 4;
      signals.add('Possível ameaça ou coerção');
    }

    if (isolation) {
      score += 2;
      signals.add('Possível isolamento familiar');
    }

    if (secrecy && migration) score += 2;
    if (secrecy && isolation) score += 2;

    final severity = score >= 5
        ? 'high'
        : score >= 2
            ? 'medium'
            : 'low';

    final category = coercion
        ? 'general-risk'
        : personalData
            ? 'personal-data'
            : secrecy || isolation
                ? 'secret-sharing'
                : migration
                    ? 'platform-change'
                    : 'general-risk';

    final explanation = score >= 2
        ? 'O Guardian identificou sinais que merecem '
          'atenção: ${signals.join(", ")}. '
          'Isso não comprova uma situação de abuso. '
          'Converse com um adulto de confiança.'
        : 'Nenhum sinal configurado foi identificado. '
          'Isso não garante que a mensagem seja segura. '
          'Sempre que precisar, converse com um adulto '
          'de confiança.';

    return RiskAnalysis(
      category: category,
      severity: severity,
      signals: List.unmodifiable(signals),
      explanation: explanation,
      requiresAttention: score >= 2,
    );
  }
}
