'use strict';

const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { setTimeout: delay } = require('node:timers/promises');

const fixtureName = 'Emissor de teste';
const childName = 'Perfil ficticio E2E';
const riskText = 'Não conte para seus pais. Vamos conversar no Discord.';

function versions(directory, pattern) {
  return fs.readdirSync(directory, { withFileTypes: true })
    .filter(entry => entry.isDirectory() && pattern.test(entry.name))
    .map(entry => entry.name).sort((a, b) => b.localeCompare(a, 'en', { numeric: true }));
}

function buildFixture({ root, sdk, runDir, fixturePackage, windows, locate, run }) {
  const sdkTools = path.join(sdk, 'build-tools');
  const toolVersion = versions(sdkTools, /^\d+\.\d+\.\d+$/)[0];
  const platformDir = path.join(sdk, 'platforms');
  const android = versions(platformDir, /^android-\d+$/)
    .map(platform => path.join(platformDir, platform, 'android.jar'))
    .find(file => fs.existsSync(file));
  if (!toolVersion || !android) throw new Error('Instale uma plataforma Android e Android SDK Build-Tools pelo Android Studio.');
  const buildTools = path.join(sdkTools, toolVersion);
  const androidTool = (name, batch = false) => locate(path.join(buildTools, name + (windows ? batch ? '.bat' : '.exe' : '')));
  const jdk = [
    process.env.JAVA_HOME,
    windows && path.join(process.env.ProgramFiles || 'C:\\Program Files', 'Android', 'Android Studio', 'jbr'),
    '/Applications/Android Studio.app/Contents/jbr/Contents/Home',
    '/opt/android-studio/jbr',
  ].find(home => home && locate(path.join(home, 'bin', windows ? 'javac.exe' : 'javac')));
  const javaTool = name => jdk ? locate(path.join(jdk, 'bin', name + (windows ? '.exe' : ''))) : locate(name);
  const javac = javaTool('javac');
  const jar = javaTool('jar');
  const keytool = javaTool('keytool');
  const aapt2 = androidTool('aapt2');
  const d8 = androidTool('d8', true);
  const zipalign = androidTool('zipalign');
  const apksigner = androidTool('apksigner', true);
  if ([javac, jar, keytool, aapt2, d8, zipalign, apksigner].some(tool => !tool)) {
    throw new Error('O teste E2E exige Java JDK (o do Android Studio serve) e Android SDK Build-Tools.');
  }
  const source = path.join(root, 'scripts', 'android-fixture');
  const classes = path.join(runDir, 'fixture-classes');
  const dex = path.join(runDir, 'fixture-dex');
  fs.mkdirSync(classes); fs.mkdirSync(dex);
  const env = { ...process.env, ...(jdk ? { JAVA_HOME: jdk, PATH: `${path.join(jdk, 'bin')}${path.delimiter}${process.env.PATH ?? ''}` } : {}) };
  const invoke = (command, args) => run(command, args, { env, timeout: 60_000 });
  invoke(javac, ['--release', '8', '-cp', android, '-d', classes, path.join(source, 'ProbeActivity.java')]);
  invoke(d8, ['--min-api', '26', '--lib', android, '--output', dex,
    path.join(classes, ...fixturePackage.split('.'), 'ProbeActivity.class')]);
  const unsigned = path.join(runDir, 'fixture-unsigned.apk');
  const aligned = path.join(runDir, 'fixture-aligned.apk');
  const output = path.join(runDir, 'fixture.apk');
  invoke(aapt2, ['link', '-o', unsigned, '-I', android, '--manifest', path.join(source, 'AndroidManifest.xml')]);
  invoke(jar, ['uf', unsigned, '-C', dex, 'classes.dex']);
  invoke(zipalign, ['-f', '4', unsigned, aligned]);
  const keystore = path.join(path.dirname(runDir), 'fixture-test.p12');
  if (!fs.existsSync(keystore)) invoke(keytool, ['-genkeypair', '-keystore', keystore,
    '-storepass', 'guardian-fixture', '-keypass', 'guardian-fixture', '-alias', 'fixture',
    '-keyalg', 'RSA', '-validity', '3650', '-dname', 'CN=Guardian test fixture']);
  invoke(apksigner, ['sign', '--ks', keystore, '--ks-pass', 'pass:guardian-fixture', '--out', output, aligned]);
  return output;
}

function decode(value) {
  return value.replace(/&(?:#x([0-9a-f]+)|#(\d+)|(amp|lt|gt|quot|apos));/gi,
    (_, hex, decimal, name) => hex ? String.fromCodePoint(parseInt(hex, 16)) :
      decimal ? String.fromCodePoint(Number(decimal)) :
      { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'" }[name]);
}

function makeUi(send) {
  const xmlPath = '/sdcard/guardian-e2e-ui.xml';
  const shell = (...args) => send(['shell', ...args.map(String)], { capture: true }).stdout.trim();
  const screen = shell('wm', 'size').match(/(\d+)x(\d+)/g)?.at(-1)?.split('x').map(Number);
  if (!screen) throw new Error('Não foi possível medir a tela do emulador.');
  const [width, height] = screen;

  function nodes() {
    const dumped = send(['shell', 'uiautomator', 'dump', xmlPath],
      { capture: true, timeout: 12_000, allowFailure: true });
    if (dumped.status !== 0 || !dumped.stdout?.includes(xmlPath)) return [];
    return Array.from(send(['exec-out', 'cat', xmlPath], { capture: true }).stdout.matchAll(/<node\s+([^>]+)>/g),
      match => {
        const fields = Object.fromEntries([...match[1].matchAll(/([\w-]+)="([^"]*)"/g)]
          .map(([, name, value]) => [name, decode(value)]));
        return { label: fields.text || fields['content-desc'] || '', ...fields };
      });
  }

  const find = (text, exact = false) => nodes().find(node =>
    exact ? node.label === text : node.label.toLowerCase().includes(text.toLowerCase()));

  async function until(action, label, seconds = 35) {
    const end = Date.now() + seconds * 1000;
    while (Date.now() < end) {
      const result = await action();
      if (result) return result;
      await delay(700);
    }
    throw new Error(`Resultado esperado não encontrado: ${label}.`);
  }

  async function click(node) {
    const [left, top, right, bottom] = node.bounds.match(/\d+/g).map(Number);
    shell('input', 'tap', Math.round((left + right) / 2), Math.round((top + bottom) / 2));
    await delay(350);
  }

  async function tap(text, exact = false) {
    await click(await until(() => find(text, exact), text));
  }

  async function reveal(text) {
    for (let attempt = 0; attempt < 5; attempt++) {
      const element = find(text, true);
      if (element) return click(element);
      shell('input', 'swipe', Math.round(width / 2), Math.round(height * .77),
        Math.round(width / 2), Math.round(height * .46), 330);
      await delay(350);
    }
    throw new Error(`Controle fora da tela: ${text}.`);
  }

  async function enter(index, text) {
    const field = await until(() => nodes().filter(node => node.class === 'android.widget.EditText')[index], 'campo de texto');
    await click(field);
    if (!/^[a-z0-9@. -]+$/i.test(text)) throw new Error('O texto de teste contém caracteres não suportados.');
    shell('input', 'text', text.replace(/ /g, '%s'));
    await delay(250);
  }

  async function hideKeyboard() {
    // Avoid closing the Flutter dialog if Android used a hardware keyboard.
    const result = send(['shell', 'dumpsys', 'input_method'],
      { capture: true, timeout: 6_000, allowFailure: true });
    if (/mInputShown=true|mIsInputViewShown=true/.test(result.stdout ?? '')) {
      shell('input', 'keyevent', '4');
      await delay(350);
    }
  }

  async function menu() {
    const button = await until(() => nodes().find(node => {
      const bounds = node.bounds?.match(/\d+/g)?.map(Number);
      return node.class === 'android.widget.Button' && bounds && bounds[0] < width * .04 &&
        bounds[1] < height * .12;
    }), 'menu lateral');
    await click(button);
  }

  async function tab(name) {
    const tab = await until(() => nodes().find(node =>
      node.class === 'android.widget.Button' && node.label.startsWith(name) && /tab/i.test(node.label)), name);
    await click(tab);
  }

  return { shell, find, until, tap, reveal, enter, hideKeyboard, menu, tab };
}

async function testAndroidFlow(context) {
  const { send, open, api, account, running, runDir, fixturePackage, say } = context;
  const fixture = buildFixture(context);
  send(['install', '--no-streaming', '-r', fixture], { timeout: 120_000 });
  const ui = makeUi(send);
  const kids = 'com.example.guardian_kids.e2e';
  const listener = `${kids}/com.example.guardian_kids.GuardianNotificationListener`;
  const notificationPermission = 'android.permission.POST_NOTIFICATIONS';
  const evidence = [];
  function capture(name) {
    const data = send(['exec-out', 'screencap', '-p'], { capture: true, binary: true }).stdout;
    if (!data?.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex'))) {
      throw new Error('O emulador não devolveu uma captura PNG válida.');
    }
    fs.writeFileSync(path.join(runDir, name), data);
  }

  let token;
  try {
    for (const app of [kids, fixturePackage]) {
      send(['shell', 'pm', 'grant', app, notificationPermission]);
    }
    send(['shell', 'cmd', 'notification', 'allow_listener', listener, '0']);
    await ui.until(() => ui.shell('settings', 'get', 'secure', 'enabled_notification_listeners').includes(listener),
      'permissão de notificações da instalação E2E', 12);

    const login = await api(running.url, '/auth/login', { body: account, expected: 201 });
    token = login.accessToken;
    say('E2E · Cadastrando um perfil fictício na interface do Pais…');
    open('guardian_pais');
    await ui.tap('Acessar conta', true);
    await ui.enter(0, account.email);
    await ui.enter(1, account.password);
    await ui.hideKeyboard();
    await ui.tap('Entrar', true);
    await ui.until(() => ui.find('API conectada'), 'sessão do responsável');
    await ui.tab('Filhos');
    await ui.tap('Adicionar criança', true);
    await ui.enter(0, childName);
    await ui.hideKeyboard();
    await ui.tap('Criar', true);
    await ui.until(() => ui.find(childName), 'perfil cadastrado no Pais');
    const child = (await api(running.url, '/children', { token })).find(item => item.name === childName);
    if (!child) throw new Error('O perfil cadastrado não chegou à API.');
    evidence.push('Cadastro na interface persistiu na API.');
    capture('01-perfil.png');

    await ui.menu();
    await ui.tap('Autorizações', true);
    await ui.tap(childName);
    await ui.tap(fixtureName, true);
    await ui.tap('Salvar proteção', true);
    await ui.tap('Gerar código de pareamento', true);
    const codeNode = await ui.until(() => {
      const node = ui.find('Código de pareamento', true);
      if (!node) return null;
      const xml = ui.shell('cat', '/sdcard/guardian-e2e-ui.xml');
      return xml.match(/\b[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{4}-[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{4}\b/)?.[0];
    }, 'código curto de pareamento');
    await ui.tap('Fechar', true);

    say('E2E · Pareando o Kids e ativando a proteção pela interface…');
    open('guardian_kids');
    await ui.tap('Parear', true);
    await ui.enter(0, codeNode);
    await ui.hideKeyboard();
    await ui.tap('Vincular', true);
    say('E2E · Código enviado pelo Kids…');
    await ui.until(() => ui.find('Dispositivo vinculado', true), 'pareamento do Kids');
    await ui.menu();
    await ui.tap('Proteção', true);
    await ui.tap('Proteção de notificações pausada');
    await ui.reveal('Consultar aplicativos autorizados');
    await ui.tap('Li com meu responsável');
    await ui.reveal('Ativar alertas automáticos');
    await ui.until(() => ui.find('Proteção de notificações ativa'), 'proteção ativa');
    evidence.push('Pareamento curto e ativação confirmados pelo Android.');
    capture('02-kids-ativo.png');

    async function post(risk) {
      await delay(500);
      ui.shell('am', 'start', '-W', '-n', `${fixturePackage}/.ProbeActivity`, '--ez', 'risk', String(risk));
    }
    const alerts = async () => (await api(running.url, '/alerts', { token })).filter(alert => alert.childId === child.id);
    await post(false);
    await delay(2_500);
    if ((await alerts()).length !== 0) throw new Error('A notificação neutra gerou um alerta inesperado.');
    await post(true);
    const received = await ui.until(async () => (await alerts())[0], 'alerta externo na API');
    if (received.source !== 'guardian-kids-notification' || received.category !== 'secret-sharing' ||
        received.severity !== 'high' || (await alerts()).length !== 1 ||
        Object.keys(received).sort().join(',') !== 'category,childId,confirmationState,contested,id,occurredAt,severity,source' ||
        JSON.stringify(received).includes(riskText)) {
      throw new Error('O alerta diverge do contrato de categoria, gravidade ou privacidade.');
    }
    evidence.push('Notificação neutra sem alerta. Notificação de risco gerou exatamente um alerta mínimo.');

    open('guardian_pais');
    await ui.tab('Alertas');
    await ui.until(() => ui.find('Notificação analisada pelo Guardian Kids'), 'alerta do agente na interface do Pais');
    await ui.until(() => ui.find(childName), 'perfil associado ao alerta');
    capture('03-alerta-no-pais.png');
    evidence.push('O Guardian Pais exibiu o alerta do agente no perfil correto.');
    fs.writeFileSync(path.join(runDir, 'resultado-e2e.json'), JSON.stringify({ result: 'PASS', checks: evidence }, null, 2));
    say('E2E concluído: cadastro, pareamento, proteção, alerta mínimo e painel do Pais.');
  } finally {
    // Always stop the isolated agent and release the Android permission used by the fixture run.
    if (token) await api(running.url, '/auth/logout', { body: {}, token, expected: 201 }).catch(() => {});
    send(['shell', 'cmd', 'notification', 'disallow_listener', listener, '0'], { allowFailure: true });
    send(['shell', 'am', 'force-stop', kids], { allowFailure: true });
  }
}

module.exports = { testAndroidFlow };
