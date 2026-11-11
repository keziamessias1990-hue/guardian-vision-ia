import 'package:flutter/material.dart';

class AlertDetailPage extends StatelessWidget {
  const AlertDetailPage({
    super.key,
    required this.title,
    required this.nivel,
    required this.tempo,
    required this.descricao,
    required this.mensagem,
    required this.origem,
    required this.cor,
    required this.textoCor,
  });

  final String title;
  final String nivel;
  final String tempo;
  final String descricao;
  final String mensagem;
  final String origem;
  final Color cor;
  final Color textoCor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do alerta'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF163B5C),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          nivel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textoCor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tempo,
                    style: const TextStyle(
                      color: Color(0xFF4E6479),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Descrição',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF163B5C)),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              style: const TextStyle(fontSize: 16, color: Color(0xFF35526D)),
            ),
            const SizedBox(height: 22),
            const Text(
              'Mensagem identificada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF163B5C)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                mensagem,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF163B5C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Origem',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF163B5C)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.source_rounded, color: Color(0xFF163B5C)),
                  const SizedBox(width: 12),
                  Text(
                    origem,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF163B5C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF163B5C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: const Text('Entrar em contato com a criança'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
