import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/guardian_api.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings(
      {super.key, this.onProtectionChanged, this.onLinkRevoked});

  final ValueChanged<bool?>? onProtectionChanged;
  final VoidCallback? onLinkRevoked;

  static const _channel = MethodChannel('guardian/notification_controls');
  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> pause() async {
    if (_supported) await _channel.invokeMethod<void>('stop');
  }

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings>
    with WidgetsBindingObserver {
  static const _sources = {
    'com.whatsapp': 'WhatsApp',
    'com.discord': 'Discord',
    'org.telegram.messenger': 'Telegram',
    'com.roblox.client': 'Roblox (notificações de mensagens)',
    if (kDebugMode &&
        bool.fromEnvironment('GUARDIAN_ENABLE_NOTIFICATION_FIXTURE'))
      'com.example.guardian_notification_fixture':
          'Emissor de teste (notificações fictícias)',
  };
  List<String>? _approvedSources;
  String? _reviewedToken;
  Map<String, Object?> _status = {};
  Timer? _timer;
  bool _agreed = false;
  bool _busy = false;
  bool _unavailable = false;
  bool _restoreInFlight = false;
  DateTime? _restoreAttempt;

  @override
  void initState() {
    super.initState();
    if (!NotificationSettings._supported) return;
    WidgetsBinding.instance.addObserver(this);
    _watch();
  }

  void _watch() {
    _timer?.cancel();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_busy) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!NotificationSettings._supported) return;
    if (state == AppLifecycleState.resumed) {
      _watch();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _refresh() async {
    try {
      final status = await NotificationSettings._channel
          .invokeMapMethod<String, Object?>('status');
      if (!mounted) return;
      setState(() {
        _status = status ?? {};
        _unavailable = status == null;
      });
      if (status?['linkRevoked'] == true && GuardianApi.deviceToken != null) {
        GuardianApi.clearLocalLink();
        widget.onLinkRevoked?.call();
      }
      widget.onProtectionChanged?.call(
        status == null
            ? null
            : (status['sources'] as List?)?.isNotEmpty == true,
      );
      if (!_busy &&
          status?['resumePending'] == true &&
          status?['connected'] == true &&
          GuardianApi.deviceToken != null) {
        _resumeApprovedProtection();
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() => _unavailable = true);
        widget.onProtectionChanged?.call(null);
      }
      _timer?.cancel();
    } on PlatformException {
      if (mounted) {
        setState(() => _unavailable = true);
        widget.onProtectionChanged?.call(null);
      }
    }
  }

  Future<void> _resumeApprovedProtection() async {
    final now = DateTime.now();
    if (_restoreInFlight ||
        (_restoreAttempt != null &&
            now.difference(_restoreAttempt!) < const Duration(seconds: 15)))
      return;
    final token = GuardianApi.deviceToken;
    _restoreInFlight = true;
    _restoreAttempt = now;
    try {
      final sources = await GuardianApi.protectionSources();
      if (!mounted || token == null || token != GuardianApi.deviceToken) return;
      await NotificationSettings._channel
          .invokeMethod<bool>('restoreProtection', {
        'sources': sources,
        'deviceToken': token,
      });
    } catch (_) {
      // Wait for a fresh authorization from the API before resuming.
    } finally {
      _restoreInFlight = false;
    }
  }

  Future<void> _loadApproved({bool activate = false}) async {
    final token = GuardianApi.deviceToken;
    setState(() => _busy = true);
    try {
      final sources = (await GuardianApi.protectionSources())
          .where(_sources.containsKey)
          .toList();
      if (!mounted || token != GuardianApi.deviceToken) return;
      final unchanged =
          _reviewedToken == token && listEquals(_approvedSources, sources);
      setState(() {
        _reviewedToken = token;
        _approvedSources = sources;
        if (!unchanged) _agreed = false;
      });
      if (activate && unchanged && sources.isNotEmpty && _agreed) {
        await _action('start', {
          'sources': sources,
          'childId': GuardianApi.childId,
          'deviceToken': token,
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _approvedSources = null;
          _agreed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Não foi possível consultar a proteção no Guardian Pais.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPause() async {
    var password = '';
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pausar com autorização'),
        content: TextField(
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: (value) => password = value,
          decoration: const InputDecoration(labelText: 'Senha do responsável'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, password.trim()),
            child: const Text('Confirmar pausa'),
          ),
        ],
      ),
    );
    if (!mounted || submitted == null || submitted.isEmpty) return;
    final token = GuardianApi.deviceToken;
    setState(() => _busy = true);
    try {
      await GuardianApi.confirmProtectionControl(submitted);
      if (mounted && token == GuardianApi.deviceToken) await _action('stop');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Não foi possível confirmar a senha. A análise continua ativa.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(String method, [Map<String, Object?>? arguments]) async {
    setState(() => _busy = true);
    try {
      final result = await NotificationSettings._channel.invokeMethod<Object?>(
        method,
        arguments,
      );
      if (result == false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confira as permissões e tente ativar novamente.'),
          ),
        );
      }
      await _refresh();
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O Android não concluiu esta ação.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!NotificationSettings._supported) return const SizedBox.shrink();
    final activeSources =
        (_status['sources'] as List?)?.cast<String>() ?? const <String>[];
    final active = activeSources.isNotEmpty;
    final access = _status['access'] == true;
    final connected = _status['connected'] == true;
    final indicator = _status['indicatorAllowed'] == true;
    final paired = GuardianApi.deviceToken != null;
    final approved =
        _reviewedToken == GuardianApi.deviceToken ? _approvedSources : null;
    final visibleSources =
        active ? activeSources : approved ?? const <String>[];

    return ExpansionTile(
      key: const PageStorageKey('notification-protection'),
      title: Text(
        active
            ? 'Proteção de notificações ativa'
            : 'Proteção de notificações pausada',
      ),
      subtitle: Text(
        active
            ? 'Alertas automáticos para seu responsável'
            : 'Somente com sua autorização',
      ),
      children: [
        const Text(
          'O Android dá ao Guardian acesso às notificações. O Guardian lê apenas '
          'prévias de mensagens dos aplicativos escolhidos no Guardian Pais. A análise '
          'acontece neste aparelho. Se houver sinal de risco, o responsável '
          'vinculado recebe automaticamente a categoria, o nível de atenção e o '
          'horário associados ao seu perfil. O texto da mensagem fica fora do alerta. '
          'A pausa no app exige a senha do responsável. O Android controla o acesso às notificações.',
        ),
        for (final packageName in visibleSources)
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: Text(_sources[packageName] ?? packageName),
          ),
        if (_unavailable)
          const Text('Controles indisponíveis neste aparelho.')
        else if (active)
          FilledButton(
            onPressed: _busy ? null : _confirmPause,
            child: const Text('Pausar análise'),
          )
        else ...[
          if (paired)
            TextButton(
              onPressed: _busy ? null : () => _loadApproved(),
              child: const Text('Consultar aplicativos autorizados'),
            ),
          if (paired && approved?.isEmpty == true)
            const Text(
                'Peça ao responsável para configurar os aplicativos no Guardian Pais.'),
          if (approved?.isNotEmpty == true)
            CheckboxListTile(
              title: const Text(
                'Li com meu responsável e concordamos em ativar os alertas automáticos.',
              ),
              value: _agreed,
              onChanged: (checked) => setState(() => _agreed = checked == true),
            ),
          if (!paired) const Text('Vincule seu responsável antes de ativar.'),
          if (access && !connected)
            const Text('Aguardando o serviço do Android.'),
          if (!access)
            TextButton(
              onPressed: !_agreed || _busy ? null : () => _action('access'),
              child: const Text('Abrir acesso a notificações no Android'),
            ),
          if (!indicator)
            TextButton(
              onPressed: !_agreed || _busy
                  ? null
                  : () => _action('indicatorPermission'),
              child: const Text('Permitir aviso de proteção ativa'),
            ),
          FilledButton(
            onPressed: !_agreed ||
                    !paired ||
                    !access ||
                    !indicator ||
                    !connected ||
                    approved?.isNotEmpty != true ||
                    _busy
                ? null
                : () => _loadApproved(activate: true),
            child: const Text('Ativar alertas automáticos'),
          ),
        ],
      ],
    );
  }
}
