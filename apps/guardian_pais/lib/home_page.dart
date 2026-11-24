import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color navy = Color(0xFF12356B);
  static const Color blue = Color(0xFF1769E0);
  static const Color background = Color(0xFFF3F7FD);
  static const Color muted = Color(0xFF65758D);
  static const Color green = Color(0xFF179B74);

  final TextEditingController _controller = TextEditingController();
  final List<ApiChild> _apiChildren = <ApiChild>[];
  final List<ApiAlert> _apiAlerts = <ApiAlert>[];
  bool _loadingDashboard = true;
  String _connection = 'Não autenticado';
  Timer? _refreshTimer;
  int _selectedTab = 0;
  bool _showDemoAlert = false;
  String _result = 'Nenhuma mensagem fictícia analisada nesta sessão.';
  String _riskLevel = 'Sem análise';
  bool _hasResult = false;
  bool _hasRisk = false;
  bool _migration = false;
  bool _contested = false;

  Future<void> _loadDashboard() async {
    final token = ApiService.accessToken;
    if (token == null) {
      if (mounted) setState(() {
        _connection = 'Não autenticado';
        _loadingDashboard = false;
        _apiChildren.clear();
        _apiAlerts.clear();
      });
      return;
    }
    try {
      final snapshot = await ApiService.fetchDashboard();
      if (!mounted || ApiService.accessToken != token) return;
      setState(() {
        _apiChildren..clear()..addAll(snapshot.children);
        _apiAlerts..clear()..addAll(snapshot.alerts);
        _loadingDashboard = false;
        _connection = 'API conectada';
      });
    } catch (failure) {
      if (!mounted || ApiService.accessToken != token) return;
      final expired = failure is ApiRequestException && failure.status == 401;
      if (expired) {
        try { await ApiService.clearSession(); } catch (_) {}
        if (!mounted || ApiService.accessToken != null) return;
      }
      setState(() {
        if (expired) {
          _apiChildren.clear();
          _apiAlerts.clear();
        }
        _loadingDashboard = false;
        _connection = expired ? 'Sessão expirada. Entre novamente.' : 'API indisponível';
      });
    }
  }

  Future<void> _loginDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailPattern = RegExp(r'^\S+@\S+\.\S+$');
    var email = '';
    var password = '';
    var submitting = false;
    String? error;
    final signedIn = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submit({required bool register}) async {
            if (submitting || !formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            final submittedEmail = email.trim();
            final submittedPassword = password.trim();
            try {
              if (register) {
                await ApiService.register(submittedEmail, submittedPassword);
              }
              await ApiService.login(submittedEmail, submittedPassword);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            } catch (failure) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                submitting = false;
                error = switch (failure) {
                  ApiRequestException(status: 401) =>
                    'Confira o e-mail e a senha e tente entrar novamente.',
                  ApiRequestException(message: 'Conta já cadastrada') =>
                    'Este e-mail já está cadastrado. Toque em Entrar.',
                  ApiRequestException(status: 400) =>
                    'Confira o formato do e-mail e o tamanho da senha.',
                  _ => 'Não foi possível acessar a API. Tente novamente.',
                };
              });
            }
          }

          return PopScope(
            canPop: !submitting,
            child: AlertDialog(
              title: const Text('Acesso do responsável'),
              scrollable: true,
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      enabled: !submitting,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      onChanged: (value) => email = value,
                      validator: (value) {
                        final address = value?.trim() ?? '';
                        if (address.length > 120 || !emailPattern.hasMatch(address)) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      enabled: !submitting,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha (mínimo 12 caracteres)',
                      ),
                      onChanged: (value) => password = value,
                      validator: (value) {
                        final size = (value ?? '').trim().length;
                        if (size < 12 || size > 256) {
                          return 'Use de 12 a 256 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          error!,
                          style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: submitting ? null : () => submit(register: true),
                  child: const Text('Cadastrar'),
                ),
                FilledButton(
                  onPressed: submitting ? null : () => submit(register: false),
                  child: Text(submitting ? 'Aguarde…' : 'Entrar'),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (signedIn == true && mounted) await _loadDashboard();
  }

  void _analyze() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isEmpty) {
      _showInfo('Mensagem vazia', 'Digite um texto fictício para realizar a simulação.');
      return;
    }

    final secret = ['segredo', 'só entre nós', 'so entre nos', 'não contar', 'nao contar', 'não conte', 'nao conte']
        .any(text.contains);
    final migration = ['discord', 'telegram', 'whatsapp', 'outro aplicativo', 'outro app']
        .any(text.contains);
    final personal = ['seu endereço', 'seu endereco', 'manda foto', 'seu telefone', 'seu número', 'seu numero']
        .any(text.contains);
    final risk = secret || migration || personal;

    setState(() {
      _hasResult = true;
      _hasRisk = risk;
      _migration = migration;
      _contested = false;
      _riskLevel = risk ? 'Atenção necessária' : 'Nenhum sinal identificado';
      _result = risk
          ? 'O texto contém ${[
              if (secret) 'pedido de segredo',
              if (migration) 'menção a outra plataforma',
              if (personal) 'pedido de informação pessoal',
            ].join(', ')}. Isso merece uma conversa cuidadosa. A continuidade em outro aplicativo não foi confirmada.'
          : 'Esta demonstração não encontrou as expressões de risco cadastradas. Isso não garante que o conteúdo seja seguro.';
    });

    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _showInfo(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi')),
        ],
      ),
    );
  }

  Future<void> _showProfile() async {
    if (ApiService.accessToken == null) {
      await _loginDialog();
      if (!mounted || ApiService.accessToken == null) return;
    }
    try {
      final email = await ApiService.profileEmail();
      if (mounted) await _showInfo('Perfil parental', 'E-mail cadastrado\n$email');
    } catch (_) {
      if (mounted) {
        await _showInfo('Perfil parental', 'Não foi possível consultar o perfil. Confira a conexão e entre novamente se a sessão expirou.');
      }
    }
  }

  Future<void> _showPrivacy() => _showInfo(
    'Privacidade e transparência',
    'Versão de teste para contas e perfis fictícios. O Guardian Pais usa a '
    'internet para acessar a conta, os perfis e os alertas da família. No '
    'Guardian Pais, o responsável escolhe as fontes. No Kids, a análise é ativada com o '
    'aviso do Android visível. A pausa pelo Kids exige a senha do responsável.\n\n'
    'A prévia é analisada no aparelho. A API recebe o identificador do perfil, '
    'categoria, gravidade, horário e origem do alerta. O servidor de teste '
    'guarda os dados até a limpeza administrativa. Alertas são sinais a verificar. '
    'Para dúvidas ou remoção de registros de teste, fale com a equipe responsável pelo teste.',
  );

  Future<void> _showPermissions() => _showInfo(
    'Permissões',
    'Guardian Pais usa a conexão com a internet para entrar, criar perfis, '
    'parear dispositivos e consultar alertas no painel.\n\n'
    'No Android da criança, abra Guardian Kids → Configurações → Proteção de '
    'notificações para consultar as fontes escolhidas no Pais, autorizar o acesso do Android, '
    'permitir o aviso visível de proteção ativa ou pausar a análise.',
  );

  Future<void> _confirmClearSession() async {
    if (ApiService.accessToken == null) {
      await _loginDialog();
      if (!mounted || ApiService.accessToken == null) return;
    }
    var password = '';
    var confirming = false;
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: !confirming,
          child: AlertDialog(
            title: const Text('Confirmar exclusão local'),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Confirme com a senha do responsável para apagar a demonstração '
                  'deste aparelho. Contas, perfis e alertas da API continuam disponíveis.',
                ),
                TextField(
                  enabled: !confirming,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Senha do responsável', errorText: error),
                  onChanged: (value) => password = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: confirming ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: confirming ? null : () async {
                  if (password.trim().isEmpty) {
                    setDialogState(() => error = 'Informe a senha.');
                    return;
                  }
                  setDialogState(() {
                    confirming = true;
                    error = null;
                  });
                  try {
                    await ApiService.confirmPassword(password.trim());
                    if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  } catch (failure) {
                    if (!dialogContext.mounted) return;
                    setDialogState(() {
                      confirming = false;
                      error = failure is ApiRequestException && failure.status == 401
                          ? 'Senha incorreta ou sessão expirada.'
                          : 'Não foi possível confirmar com a API.';
                    });
                  }
                },
                child: Text(confirming ? 'Aguarde…' : 'Confirmar exclusão'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _hasResult = false;
      _hasRisk = false;
      _migration = false;
      _contested = false;
      _riskLevel = 'Sem análise';
      _result = 'Nenhuma mensagem fictícia analisada nesta sessão.';
      _showDemoAlert = false;
      _controller.clear();
    });
    await _showInfo('Dados locais apagados', 'A demonstração desta sessão foi limpa.');
  }

  Future<void> _showSafetyGuidanceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Orientação acolhedora'),
        content: const Text(
          'Converse com calma, sem culpar a criança. Pergunte como ela se sentiu e procure apoio especializado se houver risco concreto.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi')),
        ],
      ),
    );
  }

  Future<void> _showPairingDialog() async {
    if (ApiService.accessToken == null) {
      await _loginDialog();
      return;
    }
    if (_apiChildren.isEmpty) {
      await _showAddChildDialog();
      return;
    }
    final available = _apiChildren.where((child) => child.status == 'pending').toList();
    if (available.isEmpty) {
      await _showInfo('Perfis vinculados', 'Todos os perfis já têm um dispositivo vinculado.');
      return;
    }
    final child = available.length == 1
        ? available.single
        : await showDialog<ApiChild>(
            context: context,
            builder: (dialogContext) => SimpleDialog(
              title: const Text('Qual perfil você quer vincular?'),
              children: [
                for (final profile in available)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialogContext, profile),
                    child: Text(profile.name),
                  ),
              ],
            ),
          );
    if (child == null || !mounted) return;
    try {
      final code = await ApiService.createPairing(child.id);
      if (!mounted) return;
      var copied = false;
      String? copyError;
      await showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Código de pareamento'),
            scrollable: true,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Perfil: ${child.name}'),
                const SizedBox(height: 12),
                SelectableText(code),
                const SizedBox(height: 12),
                const Text('Cole no Guardian Kids. Válido por 5 minutos e para um único uso.'),
                if (copyError != null) Text(copyError!),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fechar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!dialogContext.mounted) return;
                    setDialogState(() {
                      copied = true;
                      copyError = null;
                    });
                  } on PlatformException {
                    if (dialogContext.mounted) {
                      setDialogState(() => copyError = 'Selecione o código e copie manualmente.');
                    }
                  }
                },
                icon: Icon(copied ? Icons.check : Icons.copy),
                label: Text(copied ? 'Código copiado' : 'Copiar código'),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted) await _showInfo('Não foi possível parear', '$error');
    }
  }

  Future<void> _showAddChildDialog() async {
    if (ApiService.accessToken == null) {
      await _loginDialog();
      return;
    }
    final formKey = GlobalKey<FormState>();
    var name = '';
    var ageGroup = '11-13';
    final child = await showDialog<({String name, String ageGroup})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cadastrar perfil infantil'),
        scrollable: true,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nome (fictício no teste)'),
                onChanged: (value) => name = value.trim(),
                validator: (_) => name.isEmpty || name.length > 80
                    ? 'Informe um nome de até 80 caracteres.'
                    : null,
              ),
              TextFormField(
                initialValue: '11-13',
                decoration: const InputDecoration(labelText: 'Faixa etária'),
                onChanged: (value) => ageGroup = value.trim(),
                validator: (_) => ageGroup.isEmpty || ageGroup.length > 20
                    ? 'Informe uma faixa etária de até 20 caracteres.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, (name: name, ageGroup: ageGroup));
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (child == null || !mounted) return;
    try {
      await ApiService.addChild(child.name, child.ageGroup);
      await _loadDashboard();
    } catch (error) {
      if (mounted) await _showInfo('Falha ao cadastrar', '$error');
    }
  }

  void _triggerDemoAlert() {
    setState(() => _showDemoAlert = true);
  }

  void _navigateToAlerts() {
    setState(() => _selectedTab = 2);
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadDashboard());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Início', 'Filhos', 'Alertas', 'Planos', 'Configurações'];
    const icons = [
      Icons.home_rounded,
      Icons.people_alt_rounded,
      Icons.notifications_rounded,
      Icons.workspace_premium_rounded,
      Icons.settings_rounded,
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Guardian Vision'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF12356B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.family_restroom_rounded, color: Color(0xFF12356B), size: 28),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Perfil parental',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Mãe / Pai responsável',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF12356B)),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                _showProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined, color: navy),
              title: const Text('Autorizações'),
              onTap: () {
                Navigator.pop(context);
                _showAuthorizations();
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF12356B)),
              title: const Text('Privacidade'),
              onTap: () {
                Navigator.pop(context);
                _showPrivacy();
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF12356B)),
              title: const Text('Ajuda'),
              onTap: () {
                Navigator.pop(context);
                _showInfo(
                  'Ajuda e suporte',
                  'O app ainda não aciona responsáveis, contatos ou serviços de emergência automaticamente.',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFF12356B)),
              title: const Text('Sair'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ApiService.logout();
                } catch (_) {
                  // O token local é descartado mesmo em falhas de rede.
                }
                if (!mounted) return;
                await _loadDashboard();
                if (mounted) await _showInfo('Sessão encerrada', 'O token local foi descartado. A API invalida a sessão quando está acessível.');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _home(),
            _childrenPage(),
            _alertsPage(),
            _plansPage(),
            _settingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _selectedTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDCEBFF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: List.generate(
          tabs.length,
          (i) => NavigationDestination(
            icon: Icon(icons[i], size: 22),
            label: tabs[i],
          ),
        ),
      ),
    );
  }

  Widget _home() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            ListTile(title: Text(_connection), subtitle: const Text('Nenhum dado demonstrativo substitui respostas da API'),
              trailing: IconButton(icon: const Icon(Icons.login), tooltip: 'Acessar conta', onPressed: _loginDialog)),
            const SizedBox(height: 20),
            _onboardingCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metric(Icons.notifications_active_outlined, '${_apiAlerts.length}', 'Alertas', Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metric(Icons.fact_check_outlined, '${_apiAlerts.length}', 'Análises recebidas', blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metric(Icons.people_outline, '${_apiChildren.length}', 'Perfis cadastrados', green),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section('Seus filhos', 'Adicionar criança', _showAddChildDialog),
            const SizedBox(height: 10),
            ..._childCards(),
            const SizedBox(height: 24),
            _section('Alertas e orientações', 'Ver todos', _navigateToAlerts),
            const SizedBox(height: 10),
            if (_showDemoAlert)
              _demoAlertCard()
            else if (_apiAlerts.isNotEmpty)
              _apiAlertCard(_apiAlerts.first)
            else
              _surface(
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Deseja visualizar uma demonstração de alerta local?',
                        style: TextStyle(color: navy, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _triggerDemoAlert,
                      icon: const Icon(Icons.preview_rounded),
                      label: const Text('Explorar demonstração'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Ações rápidas',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    Icons.search_rounded,
                    'Testar demonstração',
                    const Color(0xFFE6F0FF),
                    blue,
                    _openAnalyzer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    Icons.menu_book_rounded,
                    'Orientações',
                    const Color(0xFFFFF2DD),
                    const Color(0xFFB97912),
                    _showSafetyGuidanceDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    Icons.privacy_tip_outlined,
                    'Privacidade',
                    const Color(0xFFE7F8F1),
                    const Color(0xFF159768),
                    _showPrivacy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    Icons.support_agent_rounded,
                    'Ajuda',
                    const Color(0xFFE4F8EF),
                    const Color(0xFF159768),
                    () => _showInfo(
                      'Ajuda e suporte',
                      'O app ainda não aciona responsáveis, contatos ou serviços de emergência automaticamente.',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'DEMONSTRAÇÃO • Os alertas de exemplo não representam monitoramento real. Nenhuma conversa é capturada automaticamente.',
              style: TextStyle(fontSize: 11, color: muted, height: 1.5),
            ),
          ],
        ),
      );

  Widget _header() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF248BFA), Color(0xFF104AAB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_user_rounded, size: 34, color: Colors.white),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guardian Vision IA',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cuidado digital para sua família',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _navigateToAlerts,
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            ),
          ],
        ),
      );

  Widget _onboardingCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE4ECF8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comece por aqui',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 12),
            _onboardingStep('1', 'Criar perfil da criança'),
            _onboardingStep('2', 'Vincular app da criança'),
            _onboardingStep('3', 'Revisar preferências de proteção'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _showPairingDialog,
                child: const Text('Vincular app da criança'),
              ),
            ),
          ],
        ),
      );

  Widget _onboardingStep(String number, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFE6F0FF),
              child: Text(number, style: const TextStyle(color: blue, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(color: navy, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _demoAlertCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFF0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCCD0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFCE3142)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Possível sinal de risco',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA91F32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text('Pedido de segredo'),
                  backgroundColor: Color(0xFFEEE3FF),
                  labelStyle: TextStyle(color: Color(0xFF5D2CA5)),
                ),
                Chip(
                  label: Text('Mudança de plataforma'),
                  backgroundColor: Color(0xFFEFF7FF),
                  labelStyle: TextStyle(color: Color(0xFF1B5EA8)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'A continuidade em outro aplicativo não foi confirmada.',
              style: TextStyle(fontSize: 13, color: navy, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _showSafetyGuidanceDialog,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('Ver orientação'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _navigateToAlerts,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ver detalhes'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _apiAlertCard(ApiAlert alert) {
    final childName = _apiChildren
        .where((child) => child.id == alert.childId)
        .map((child) => child.name)
        .firstOrNull;
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4ECF8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFCE3142)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.summary,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: navy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${alert.originLabel}\n'
              '${childName == null ? '' : '$childName · '}Nível: ${alert.severity}\n'
              '${alert.occurredAt} · Sinal a verificar com a criança',
              style: const TextStyle(fontSize: 12, color: muted),
            ),
            TextButton(onPressed: alert.contested ? null : () async {
              try { await ApiService.contest(alert.id); await _loadDashboard(); }
              catch(e) { if (mounted) await _showInfo('Falha ao contestar', '$e'); }
            }, child: Text(alert.contested ? 'Alerta contestado' : 'Contestar alerta')),
          ],
        ),
      );

  }

  Widget _metric(IconData icon, String value, String label, Color color) => _surface(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
        child: Column(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: muted),
            ),
          ],
        ),
      );

  Widget _section(String title, String action, VoidCallback onTap) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: navy),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      );

  Widget _quickAction(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) => Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, size: 28, color: fg),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: navy),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _surface({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4ECF8)),
          boxShadow: const [
            BoxShadow(color: Color(0x0B173D70), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: child,
      );

  Widget _circleIcon(IconData icon, Color bg, Color fg) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: 27),
      );

  Future<void> _showAuthorizations() async {
    if (ApiService.accessToken == null) {
      await _loginDialog();
      if (!mounted || ApiService.accessToken == null) return;
    }
    await _loadDashboard();
    if (!mounted) return;
    if (_connection != 'API conectada' || _apiChildren.isEmpty) {
      await _showInfo('Autorizações', _connection == 'API conectada'
          ? 'Cadastre um perfil infantil para escolher os aplicativos autorizados.'
          : 'Conecte-se à API para consultar as autorizações.');
      return;
    }
    final child = await showDialog<ApiChild>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Autorizações'),
        children: [
          for (final profile in _apiChildren)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, profile),
              child: Text('${profile.name} · ${profile.protectionSources.length} app(s) autorizado(s)'),
            ),
        ],
      ),
    );
    if (child != null && mounted) await _editChildProtection(child);
  }

  Future<void> _editChildProtection(ApiChild child) async {
    final selected = child.protectionSources.toSet();
    const applications = {
      'com.whatsapp': 'WhatsApp',
      'com.discord': 'Discord',
      'org.telegram.messenger': 'Telegram',
      'com.roblox.client': 'Roblox',
      if (kDebugMode && bool.fromEnvironment('GUARDIAN_ENABLE_NOTIFICATION_FIXTURE'))
        'com.example.guardian_notification_fixture': 'Emissor de teste',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text('Proteção de ${child.name}'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Alterações pausam a análise assim que o Kids recebe a nova lista. Revise e ative novamente no Kids.'),
              for (final entry in applications.entries)
                CheckboxListTile(
                  title: Text(entry.value),
                  value: selected.contains(entry.key),
                  onChanged: (checked) => update(() {
                    if (checked == true) {
                      selected.add(entry.key);
                    } else {
                      selected.remove(entry.key);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar proteção')),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.setProtectionSources(child.id, selected);
      await _loadDashboard();
    } catch (_) {
      if (mounted) await _showInfo('Proteção', 'Não foi possível salvar os aplicativos.');
    }
  }

  String _reportedStatus(ApiChild child) {
    final state = child.protectionLabel(DateTime.now());
    final time = child.reportedAt?.toLocal();
    if (time == null) return 'Proteção · $state';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return 'Proteção · $state\nÚltimo contato $day/$month às $hour:$minute';
  }

  List<Widget> _childCards({bool editable = false}) {
    if (_apiChildren.isEmpty) {
      final message = switch (_connection) {
        'API conectada' => 'Nenhuma criança cadastrada',
        'API indisponível' => 'Não foi possível consultar os perfis.',
        _ => 'Entre para ver os perfis da família.',
      };
      return [_surface(child: Text(message))];
    }
    return [
      for (final child in _apiChildren)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _surface(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _circleIcon(Icons.person_rounded, const Color(0xFFE6F0FF), blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
                      Text('Faixa etária: ${child.ageGroup}', style: const TextStyle(color: muted)),
                      Text(
                        child.status == 'linked' ? 'Dispositivo vinculado' : 'Aguardando pareamento',
                        style: const TextStyle(color: muted),
                      ),
                      if (child.status == 'linked')
                        Text(_reportedStatus(child), style: const TextStyle(color: navy)),
                      if (editable)
                        TextButton(
                          onPressed: () => _editChildProtection(child),
                          child: const Text('Configurar proteção'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _childrenPage() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfis infantis',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: navy),
            ),
            if (_connection == 'API conectada')
              Text('${_apiChildren.length} cadastrados · ${_apiChildren.where((child) => child.status == 'linked').length} vinculados'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _showAddChildDialog,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar criança'),
            ),
            TextButton.icon(
              onPressed: _showPairingDialog,
              icon: const Icon(Icons.link),
              label: const Text('Gerar código de pareamento'),
            ),
            const SizedBox(height: 12),
            ..._childCards(editable: true),
          ],
        ),
      );

  Widget _alertsPage() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Central de alertas',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 6),
            Text(
              'Alertas da família autenticada • $_connection',
              style: const TextStyle(color: muted),
          ),
            const SizedBox(height: 18),
            if (_showDemoAlert)
              _demoAlertCard()
            else
              _surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Demonstração separada dos alertas da API.',
                      style: TextStyle(color: navy, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _triggerDemoAlert,
                      icon: const Icon(Icons.preview_rounded),
                      label: const Text('Explorar demonstração'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            for (final alert in _apiAlerts) Padding(
              padding: const EdgeInsets.only(bottom: 10), child: _apiAlertCard(alert)),
            if (_hasResult)
              _surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _riskLevel,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _hasRisk ? const Color(0xFFC13E2F) : const Color(0xFF13855D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      style: const TextStyle(height: 1.5, color: navy),
                    ),
                    if (_migration) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Migração entre plataformas: não confirmada.',
                        style: TextStyle(fontWeight: FontWeight.w700, color: muted),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _contested = true),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: Text(_contested ? 'Contestação registrada localmente' : 'Contestar resultado'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _openAnalyzer,
              icon: const Icon(Icons.search),
              label: const Text('Analisar texto fictício'),
            ),
          ],
        ),
      );

  Widget _plansPage() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Planos',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 6),
            const Text('Valores apenas para simulação acadêmica.', style: TextStyle(color: muted)),
            const SizedBox(height: 20),
            _surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plano Família',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'R\$ 45,00/mês',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fidelidade de 12 meses. São 12 mensalidades de R\$ 45,00, totalizando R\$ 540,00 por família. A simulação não realiza cobranças.',
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _showInfo(
                        'Checkout de demonstração',
                        'O pagamento sandbox ainda não está integrado. Nenhuma assinatura foi criada.',
                      ),
                      child: const Text('Simular contratação'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _settingsPage() => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configurações',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 20),
            _surface(
              child: Column(
                children: [
                  _settingsTile(
                    Icons.privacy_tip_outlined,
                    'Privacidade e transparência',
                    _showPrivacy,
                  ),
                  const Divider(),
                  _settingsTile(
                    Icons.lock_outline,
                    'Permissões',
                    _showPermissions,
                  ),
                  const Divider(),
                  _settingsTile(
                    Icons.delete_outline,
                    'Excluir dados da sessão',
                    _confirmClearSession,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _settingsTile(IconData icon, String title, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: blue),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  void _openAnalyzer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulador de mensagens',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: navy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use apenas textos fictícios. A análise é feita localmente por palavras-chave.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Ex.: Não conte a ninguém. Vamos conversar no Discord.',
                  filled: true,
                  fillColor: background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) {
                      _showInfo('Mensagem vazia', 'Digite um texto fictício para realizar a simulação.');
                      return;
                    }
                    _analyze();
                    Navigator.pop(sheetContext);
                    setState(() => _selectedTab = 2);
                  },
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Analisar mensagem'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
