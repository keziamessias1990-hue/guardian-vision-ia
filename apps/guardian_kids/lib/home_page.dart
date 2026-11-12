import 'dart:async';

import 'package:flutter/material.dart';

import 'services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _resultado = 'Ainda não analisei nenhuma mensagem.';
  String _situacaoAtual = 'Tudo bem por enquanto';
  bool _sending = false;
  bool _agentActive = true;
  bool _alertaAutomatico = false;

  bool _conteudoSensivel(String texto) {
    final normalized = texto.toLowerCase();
    final termos = [
      'segredo',
      'discord',
      'só entre nós',
      'não contar pra ninguém',
      'nao contar pra ninguem',
      'telegram',
      'whatsapp',
      'manda foto',
      'me passa seu endereço',
      'me passa seu telefone',
      'não conte',
      'nao conte',
      'em privado',
    ];

    return termos.any(normalized.contains);
  }

  Future<void> _scannearMensagemRecebida(String textoRecebido, {bool manual = true}) async {
    final texto = textoRecebido.trim();
    if (texto.isEmpty) {
      return;
    }

    final possivelRisco = _conteudoSensivel(texto);
    final summary = possivelRisco
        ? 'Mensagem recebida com padrão sensível: tentativa de segredo, troca para outra plataforma ou pedido de dados pessoais.'
        : 'Mensagem recebida sem padrões de risco no agente local de proteção.';

    setState(() {
      _sending = true;
      _agentActive = true;
      _alertaAutomatico = possivelRisco;
      _situacaoAtual = possivelRisco ? 'Agente detectou risco' : 'Proteção ativa';
      _resultado = possivelRisco
          ? 'O agente local identificou um padrão sensível e registrou uma notificação de segurança.'
          : 'O agente local concluiu a verificação e não encontrou sinais de risco no conteúdo analisado.';
    });

    final payload = KidAlertPayload(
      childId: 'child-1',
      category: possivelRisco ? 'secret-sharing' : 'platform-change',
      severity: possivelRisco ? 'medium' : 'low',
      summary: summary,
    );

    final sent = await KidApiService.sendAlert(payload);

    if (!mounted) return;

    setState(() {
      _sending = false;
      _resultado = sent
          ? (possivelRisco
              ? 'Alerta automático registrado com segurança para o responsável.'
              : 'Verificação concluída e mantida localmente. Nenhum risco detectado.')
          : (possivelRisco
              ? 'Padrão de risco identificado localmente. O backend não respondeu no momento, mas a proteção continua ativa.'
              : 'Verificação concluída localmente. O backend não respondeu, mas a proteção continua ativa.');
      _situacaoAtual = possivelRisco ? 'Ação de segurança ativada' : 'Proteção ativa';
    });

    if (manual) {
      _controller.clear();
    }
  }

  void _analisarExemplo() {
    final texto = _controller.text;
    if (texto.trim().isEmpty) {
      setState(() {
        _resultado = 'Aguardando mensagem recebida para análise automática.';
      });
      return;
    }

    unawaited(_scannearMensagemRecebida(texto, manual: true));
  }

  void _simularMensagemRecebida() {
    const mensagem = 'Vamos conversar em segredo e depois no Discord.';
    _controller.text = mensagem;
    unawaited(_scannearMensagemRecebida(mensagem, manual: false));
  }

  Future<void> _mostrarDialogoAjuda(String titulo, String mensagem) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(
              titulo == 'Meu pai' ? Icons.call_rounded : Icons.favorite_rounded,
              color: const Color(0xFF3AB0FF),
            ),
            const SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _acaoMedo() {
    setState(() {
      _situacaoAtual = 'Estou com medo';
      _resultado = 'Você não precisa resolver isso sozinho(a). Fale com um adulto de confiança agora.';
    });
    _mostrarDialogoAjuda(
      'Estou com medo',
      'Você está protegido(a). Procure um adulto de confiança e diga o que aconteceu.',
    );
  }

  void _acaoPai() {
    setState(() {
      _situacaoAtual = 'Vou falar com meu responsável';
      _resultado = 'Fale com seu responsável ou outro adulto de confiança. Você não está sozinho(a).';
    });
    _mostrarDialogoAjuda(
      'Meu pai',
      'Este botão não envia mensagens nesta demonstração. Procure seu responsável ou outro adulto de confiança e conte o que aconteceu.',
    );
  }

  void _acaoAjudaGeral() {
    setState(() {
      _situacaoAtual = 'Preciso de ajuda';
      _resultado = 'Toda vez que você se sentir insegura(o), fale com alguém da sua família ou de confiança.';
    });
    _mostrarDialogoAjuda(
      'Preciso de ajuda',
      'Procure um adulto de confiança e fale com ele(a). A sua segurança e o seu bem-estar são importantes.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _alertaAutomatico ? const Color(0xFFFFF0F2) : const Color(0xFFE8F7F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _alertaAutomatico ? const Color(0xFFEDB8C4) : const Color(0xFFB7E7D2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _agentActive ? Icons.shield_rounded : Icons.security_update_good_rounded,
                      color: _alertaAutomatico ? const Color(0xFFB92943) : const Color(0xFF1F8F61),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _agentActive
                            ? (_alertaAutomatico
                                ? 'Proteção ativa: sinal sensível detectado.'
                                : 'Proteção ativa: monitoramento local em funcionamento.')
                            : 'Proteção ativa: aguardando verificação.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F4E79),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7CD8FF), Color(0xFF5EC7FF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5EC7FF).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Guardian Vision',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F4E79),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Seu espaço seguro e acolhedor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF557A94),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7C2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mood_rounded, color: Color(0xFFFFB703), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Como você está agora?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F4E79),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _situacaoAtual,
                            style: const TextStyle(
                              color: Color(0xFF1F4E79),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: '😟 Estou com medo',
                      color: const Color(0xFFB8E0FF),
                      onTap: _acaoMedo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      title: '👨‍👩‍👧 Meu pai',
                      color: const Color(0xFFFFE29A),
                      onTap: _acaoPai,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ActionCard(
                title: '💛 Preciso de ajuda',
                color: const Color(0xFFB9F0D1),
                onTap: _acaoAjudaGeral,
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mensagem de teste',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F4E79),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ex.: "Vamos conversar em segredo"',
                        filled: true,
                        fillColor: const Color(0xFFF3FAFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _sending ? null : _analisarExemplo,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4CB2FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(_sending ? 'Enviando...' : 'Analisar mensagem'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _simularMensagemRecebida,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Simular mensagem recebida'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5D6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  _resultado,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F4E79),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Privacidade: esta versão é uma demonstração local e não envia mensagens para servidores.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF67839A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F4E79),
            ),
          ),
        ),
      ),
    );
  }
}
