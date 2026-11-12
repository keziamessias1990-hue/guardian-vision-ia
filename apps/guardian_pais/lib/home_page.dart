import 'package:flutter/material.dart';

import 'services/api_service.dart';

// Guardian Vision Pais - Home demonstrativa.
// Os dados da API são usados quando o backend estiver disponível; o app continua
// funcionando em modo demonstrativo quando a API não responder.
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
  int _selectedTab = 0;
  bool _showDemoAlert = false;
  String _result = 'Nenhuma mensagem fictícia analisada nesta sessão.';
  String _riskLevel = 'Sem análise';
  bool _hasResult = false;
  bool _hasRisk = false;
  bool _migration = false;
  bool _contested = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final snapshot = await ApiService.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _apiChildren
          ..clear()
          ..addAll(snapshot.children);
        _apiAlerts
          ..clear()
          ..addAll(snapshot.alerts);
        _loadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDashboard = false);
    }
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
      ),
    );
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPairingDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pareamento futuro'),
        content: const Text(
          'O pareamento do app da criança será implementado após a integração com o backend. Neste protótipo, a conexão real ainda não está disponível.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddChildDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Adicionar criança'),
        content: const Text(
          'O cadastro e o pareamento dependem do backend. Este protótipo apresenta apenas a experiência inicial e não cria vínculo real.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _triggerDemoAlert() {
    setState(() => _showDemoAlert = true);
  }

  void _navigateToAlerts() {
    setState(() => _selectedTab = 2);
  }

  @override
  void dispose() {
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
                _showInfo('Perfil', 'A edição do perfil parental será habilitada após a integração com o backend.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF12356B)),
              title: const Text('Privacidade'),
              onTap: () {
                Navigator.pop(context);
                _showInfo(
                  'Privacidade',
                  'O protótipo não acessa conversas de outros aplicativos e não envia textos para servidores.',
                );
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
              onTap: () {
                Navigator.pop(context);
                _showInfo('Sair', 'Este protótipo não encerra sessão real, apenas demonstra a ação visual de saída.');
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
            _simplePage(
              'Perfis infantis',
              Icons.people_alt_outlined,
              'Cadastre e vincule os dispositivos das crianças quando o backend de pareamento estiver disponível.',
            ),
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
            const SizedBox(height: 20),
            _onboardingCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metric(Icons.notifications_active_outlined, _loadingDashboard ? '…' : '${_apiAlerts.length}', 'Alertas', Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metric(Icons.fact_check_outlined, _loadingDashboard ? '…' : '${_apiAlerts.length}', 'Análises recebidas', blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metric(Icons.people_outline, _loadingDashboard ? '…' : '${_apiChildren.length}', 'Crianças vinculadas', green),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section('Seus filhos', 'Adicionar criança', _showAddChildDialog),
            const SizedBox(height: 10),
            _surface(
              child: _loadingDashboard
                  ? const Center(child: CircularProgressIndicator())
                  : (_apiChildren.isEmpty
                      ? Row(
                          children: [
                            _circleIcon(Icons.person_add_alt_1_rounded, const Color(0xFFE6F0FF), blue),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nenhuma criança vinculada',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: navy),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Adicione uma criança para começar.',
                                    style: TextStyle(color: muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _showAddChildDialog,
                              child: const Text('Adicionar criança'),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final child in _apiChildren)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    _circleIcon(Icons.person_rounded, const Color(0xFFE6F0FF), blue),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            child.name,
                                            style: const TextStyle(fontWeight: FontWeight.w700, color: navy),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Faixa etária: ${child.ageGroup}',
                                            style: const TextStyle(color: muted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(child.status == 'linked' ? 'Vinculada' : 'Pendente'),
                                      backgroundColor: child.status == 'linked' ? const Color(0xFFE7F8F1) : const Color(0xFFFFF2DD),
                                      labelStyle: TextStyle(
                                        color: child.status == 'linked' ? const Color(0xFF159768) : const Color(0xFFB97912),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )),
            ),
            const SizedBox(height: 24),
            _section('Alertas e orientações', 'Ver todos', _navigateToAlerts),
            const SizedBox(height: 10),
            if (_showDemoAlert)
              _demoAlertCard()
            else if (_loadingDashboard)
              const Center(child: CircularProgressIndicator())
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
                      key: const ValueKey('explore_demo_button'),
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
                    () => _showInfo(
                      'Privacidade',
                      'O protótipo não acessa conversas de outros apps e não envia textos para servidores.',
                    ),
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
                color: Colors.white.withValues(alpha: 0.18),
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

  Widget _onboardingCard() => _surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comece por aqui',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 14),
            _onboardingStep('1', 'Criar perfil da criança'),
            _onboardingStep('2', 'Vincular app da criança'),
            _onboardingStep('3', 'Revisar preferências de proteção'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('pairing_button'),
                onPressed: _showPairingDialog,
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Vincular app da criança'),
              ),
            ),
          ],
        ),
      );

  Widget _onboardingStep(String number, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEBFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: navy),
              ),
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

  Widget _apiAlertCard(ApiAlert alert) => Container(
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
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFCE3142)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.category == 'secret-sharing' ? 'Possível sinal de risco' : 'Alerta da criança',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA91F32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(_alertTagLabel(alert.category)),
                  backgroundColor: const Color(0xFFEEE3FF),
                  labelStyle: const TextStyle(color: Color(0xFF5D2CA5)),
                ),
                if (alert.severity.isNotEmpty)
                  Chip(
                    label: Text(alert.severity.toUpperCase()),
                    backgroundColor: const Color(0xFFEFF7FF),
                    labelStyle: const TextStyle(color: Color(0xFF1B5EA8)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.summary,
              style: const TextStyle(fontSize: 13, color: navy, height: 1.4),
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

  String _alertTagLabel(String category) {
    switch (category) {
      case 'secret-sharing':
        return 'Pedido de segredo';
      case 'platform-change':
        return 'Mudança de plataforma';
      case 'personal-info':
        return 'Solicitação de dados pessoais';
      default:
        return category.isEmpty ? 'Alerta' : category;
    }
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

  Widget _simplePage(String title, IconData icon, String message) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: navy),
            ),
            const SizedBox(height: 20),
            _surface(
              child: Column(
                children: [
                  Icon(icon, size: 52, color: blue),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _showPairingDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar criança'),
                  ),
                ],
              ),
            ),
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
            const Text(
              'Exemplos e análises locais desta sessão',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 18),
            if (_showDemoAlert)
              _demoAlertCard()
            else if (_loadingDashboard)
              const Center(child: CircularProgressIndicator())
            else if (_apiAlerts.isNotEmpty)
              _apiAlertCard(_apiAlerts.first)
            else
              _surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nenhum alerta demonstrativo selecionado.',
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
                    'Plano Família • cenário-base',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: navy),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'R\$ 59,00/mês',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preço hipotético, ainda não validado. Nenhuma cobrança será realizada.',
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
                    'O protótipo não acessa conversas de outros aplicativos.',
                  ),
                  const Divider(),
                  _settingsTile(
                    Icons.lock_outline,
                    'Permissões',
                    'Nenhuma permissão especial de monitoramento está ativada.',
                  ),
                  const Divider(),
                  _settingsTile(
                    Icons.delete_outline,
                    'Excluir dados da sessão',
                    'Apagar a análise temporária desta demonstração.',
                    clear: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _settingsTile(IconData icon, String title, String detail, {bool clear = false}) => Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: blue),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: navy)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (clear) {
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
              _showInfo('Dados locais apagados', 'O resultado temporário desta sessão foi limpo.');
            } else {
              _showInfo(title, detail);
            }
          },
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
