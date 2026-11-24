import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/guardian_api.dart';
import 'notification_settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _situacaoAtual = 'Tudo bem por enquanto';
  bool _pareando = false;
  bool _showProtection = false;
  bool? _protectionActive;

  String get _acompanhamento {
    if (!_dispositivoVinculado) {
      return 'O acompanhamento começa após o vínculo e a ativação da proteção.';
    }
    return switch (_protectionActive) {
      true =>
        'Este celular está sendo acompanhado. O Guardian analisa as notificações dos apps selecionados.',
      false => 'Acompanhamento pausado. Você pode ativá-lo no menu Proteção.',
      null => 'O estado do acompanhamento está indisponível.',
    };
  }

  void _updateProtection(bool? active) {
    if (mounted && _protectionActive != active) {
      setState(() => _protectionActive = active);
    }
  }

  bool get _dispositivoVinculado => GuardianApi.deviceToken != null;

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _pairDialog() async {
    if (_pareando) return;
    var code = '';
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vincular ao responsável'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => code = value.trim(),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Código recebido do responsável',
                hintText: 'ABCD-2345',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, code),
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
    if (!mounted || submitted == null || submitted.isEmpty) return;
    setState(() => _pareando = true);
    try {
      await NotificationSettings.pause();
      await GuardianApi.pair(submitted);
      if (!mounted) return;
      setState(() {
        _protectionActive = false;
      });
      _mostrarMensagem('Dispositivo vinculado com sucesso.');
    } on PlatformException {
      _mostrarMensagem(
          'O Android não conseguiu guardar o vínculo com segurança.');
    } catch (_) {
      _mostrarMensagem('Confira se o código está correto e ainda é válido.');
    } finally {
      if (mounted) setState(() => _pareando = false);
    }
  }

  Future<void> _mostrarDialogoAjuda(
    String titulo,
    String mensagem,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _acaoMedo() {
    setState(() {
      _situacaoAtual = 'Estou com medo';
    });

    _mostrarDialogoAjuda(
      'Estou com medo',
      'Se alguém está ameaçando você, procure '
          'imediatamente um adulto de confiança. '
          'Você merece proteção e acolhimento.',
    );
  }

  void _acaoPai() {
    setState(() {
      _situacaoAtual = 'Vou falar com meu responsável';
    });

    _mostrarDialogoAjuda(
      'Meu responsável',
      'Este botão oferece uma orientação, mas '
          'não envia uma mensagem automaticamente. '
          'Procure seu responsável ou outro adulto '
          'de confiança para conversar.',
    );
  }

  void _acaoAjudaGeral() {
    setState(() {
      _situacaoAtual = 'Preciso de ajuda';
    });

    _mostrarDialogoAjuda(
      'Preciso de ajuda',
      'Você pode pedir ajuda sempre que precisar. '
          'Sua segurança e seu bem-estar são importantes.',
    );
  }

  Future<void> _showPrivacy() => _mostrarDialogoAjuda(
        'Privacidade e transparência',
        'Seu responsável escolhe os aplicativos no Guardian Pais. Quando a proteção '
            'está ativa, o Android mostra um aviso. A pausa pelo Kids exige a senha '
            'do responsável. O Android controla as permissões.\n\n'
            'O Guardian analisa no aparelho as prévias das notificações. Seu '
            'responsável pode receber um alerta com o tipo de risco, o nível e o '
            'horário. A mensagem fica fora do alerta.',
      );

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1F4E79);

    return Scaffold(
      appBar:
          AppBar(title: Text(_showProtection ? 'Proteção' : 'Guardian Kids')),
      drawer: Drawer(
        child: Builder(
          builder: (drawerContext) => SafeArea(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Início'),
                  selected: !_showProtection,
                  onTap: () {
                    Navigator.pop(drawerContext);
                    setState(() => _showProtection = false);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Proteção'),
                  selected: _showProtection,
                  onTap: () {
                    Navigator.pop(drawerContext);
                    setState(() => _showProtection = true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacidade'),
                  onTap: () {
                    Navigator.pop(drawerContext);
                    _showPrivacy();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _showProtection ? 1 : 0,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _dispositivoVinculado
                          ? Icons.verified_user_rounded
                          : Icons.link_off_rounded,
                      color:
                          _dispositivoVinculado ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      _dispositivoVinculado
                          ? 'Dispositivo vinculado'
                          : 'Dispositivo não vinculado',
                    ),
                    trailing: _dispositivoVinculado
                        ? null
                        : TextButton(
                            onPressed: _pareando ? null : _pairDialog,
                            child: const Text('Parear'),
                          ),
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text(_acompanhamento),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7CD8FF),
                            Color(0xFF5EC7FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
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
                        color: navy,
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
                        const Icon(
                          Icons.mood_rounded,
                          color: Color(0xFFFFB703),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Como você está agora?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: navy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _situacaoAtual,
                                style: const TextStyle(
                                  color: navy,
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
                  const Text(
                    'A análise acontece nas notificações de apps e jogos '
                    'selecionados. O Guardian envia um alerta mínimo se encontrar '
                    'um possível risco. O responsável pode autorizar a pausa no menu Proteção.',
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(_acompanhamento),
                NotificationSettings(
                  onProtectionChanged: _updateProtection,
                  onLinkRevoked: () {
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
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
