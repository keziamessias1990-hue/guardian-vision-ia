#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const { spawn, spawnSync } = require('node:child_process');
const readline = require('node:readline');
const { setTimeout: delay } = require('node:timers/promises');

const root = path.resolve(__dirname, '..');
const backend = path.join(root, 'backend');
const dataRoot = path.join(backend, 'data', 'execucoes-android');
const windows = process.platform === 'win32';
const fixturePackage = 'com.example.guardian_notification_fixture';
const account = {
  email: 'responsavel.demo@guardian.test',
  password: 'GuardianDemo2026Seguro',
};
const servers = new Set();
let runDir;
let menu;
let lock;

function say(message) {
  process.stdout.write(`\n${message}\n`);
}

function locate(name) {
  if (name && fs.existsSync(name) && fs.statSync(name).isFile()) return path.resolve(name);
  if (!name) return undefined;
  const result = spawnSync(windows ? 'where.exe' : 'which', [name], { encoding: 'utf8' });
  const paths = (result.stdout ?? '').trim().split(/\r?\n/);
  return windows ? paths.find(file => /\.(?:exe|bat|cmd)$/i.test(file)) : paths[0] || undefined;
}

function commandLine(executable, args) {
  if (!windows || !/\.(?:bat|cmd)$/i.test(executable)) return [executable, args, {}];
  // Flutter, npm and the Android SDK publish Windows launchers as batch files.
  const quoted = [executable, ...args].map(value => {
    if (/["%\r\n]/.test(value)) throw new Error('A ferramenta está em um caminho incompatível com o cmd.exe.');
    return `"${value}"`;
  }).join(' ');
  return [
    process.env.ComSpec || 'cmd.exe',
    ['/d', '/v:off', '/s', '/c', `"${quoted}"`],
    { windowsVerbatimArguments: true },
  ];
}

function run(executable, args, options = {}) {
  const { cwd = root, env = process.env, capture = false, binary = false,
    timeout = 600_000, allowFailure = false } = options;
  const [file, argv, platform] = commandLine(executable, args);
  const result = spawnSync(file, argv, {
    ...platform, cwd, env, timeout, stdio: ['ignore', capture ? 'pipe' : 'inherit', capture ? 'pipe' : 'inherit'],
    ...(binary ? {} : { encoding: 'utf8' }),
  });
  if (result.status !== 0 && !allowFailure) {
    throw new Error(result.error?.message || (capture && String(result.stderr).trim()) ||
      `${path.basename(executable)} falhou (código ${result.status ?? result.signal ?? 'indisponível'}).`);
  }
  return result;
}

function sdkTools() {
  const sdk = [process.env.ANDROID_HOME, process.env.ANDROID_SDK_ROOT,
    process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk'),
    path.join(os.homedir(), 'Library', 'Android', 'sdk'),
    path.join(os.homedir(), 'Android', 'Sdk'),
  ].find(candidate => candidate && fs.existsSync(candidate));
  const adb = locate(sdk && path.join(sdk, 'platform-tools', windows ? 'adb.exe' : 'adb')) ?? locate('adb');
  if (!adb) throw new Error('Instale Android SDK Platform-Tools pelo Android Studio.');
  return { sdk: sdk ?? path.dirname(path.dirname(adb)), adb };
}

function adbTools(adb) {
  function call(args, options = {}) {
    try {
      return run(adb, args, { timeout: 20_000, ...options });
    } catch (error) {
      const command = args[0] === '-s' ? args.slice(2) : args;
      throw new Error(`Android (${command.slice(0, 3).join(' ')}): ${error.message}`);
    }
  }
  function devices() {
    const result = call(['devices'], { capture: true, timeout: 8_000 });
    return [...result.stdout.matchAll(/^(emulator-\d+)\s+device\b/gm)].map(match => match[1]);
  }
  async function boot(sdk) {
    let serial = process.env.GUARDIAN_EMULATOR;
    if (serial && !/^emulator-\d+$/.test(serial)) throw new Error('GUARDIAN_EMULATOR precisa apontar para um emulador Android.');
    const open = devices();
    if (!serial && open.length > 1) throw new Error('Deixe apenas o emulador desejado aberto ou defina GUARDIAN_EMULATOR.');
    serial ??= open[0];
    if (!serial) {
      const emulator = locate(path.join(sdk, 'emulator', windows ? 'emulator.exe' : 'emulator'));
      if (!emulator) throw new Error('Abra um emulador no Device Manager do Android Studio.');
      const avds = callToolList(emulator);
      const avd = process.env.GUARDIAN_AVD ?? (avds.length === 1 ? avds[0] : undefined);
      if (!avd) throw new Error('Abra ou crie um emulador no Device Manager. Se houver vários, abra o desejado.');
      const log = fs.openSync(path.join(runDir, 'emulador.log'), 'a');
      const emulatorProcess = spawn(emulator, ['-avd', avd], { detached: true, stdio: ['ignore', log, log] });
      emulatorProcess.on('error', error => console.error(error.message));
      emulatorProcess.unref();
      fs.closeSync(log);
    }
    say('Aguardando o emulador Android…');
    const end = Date.now() + 150_000;
    while (Date.now() < end) {
      serial ??= devices()[0];
      if (serial && call(['-s', serial, 'shell', 'getprop', 'sys.boot_completed'],
        { capture: true, timeout: 3_000, allowFailure: true }).stdout?.trim() === '1') {
        const abi = call(['-s', serial, 'shell', 'getprop', 'ro.product.cpu.abi'], { capture: true }).stdout.trim();
        const target = { 'arm64-v8a': 'android-arm64', x86_64: 'android-x64' }[abi];
        if (!target) throw new Error(`Arquitetura Android não suportada neste roteiro: ${abi}.`);
        return { serial, target };
      }
      await delay(2_000);
    }
    throw new Error('O Android não terminou de iniciar. Confira o emulador no Android Studio.');
  }
  return { call, boot };
}

function callToolList(emulator) {
  return run(emulator, ['-list-avds'], { capture: true, timeout: 8_000 }).stdout.split(/\r?\n/).filter(Boolean);
}

async function startApi(name, file, fixture = false) {
  const portFile = path.join(runDir, `${name}.port`);
  const log = path.join(runDir, `${name}.log`);
  const fd = fs.openSync(log, 'a');
  const child = spawn(process.execPath, ['-e', `
    const { writeFileSync } = require('node:fs');
    const { NestFactory } = require('@nestjs/core');
    const { AppModule } = require('./dist/app.module');
    (async () => {
      const api = await NestFactory.create(AppModule);
      api.setGlobalPrefix('api');
      api.enableShutdownHooks();
      await api.listen(0, '127.0.0.1');
      writeFileSync(process.env.GUARDIAN_PORT_FILE, String(api.getHttpServer().address().port));
    })().catch(error => { console.error(error); process.exit(1); });
  `], {
    cwd: backend, env: { ...process.env, GUARDIAN_PORT_FILE: portFile,
      GUARDIAN_DATA_FILE: file, GUARDIAN_TEST_FIXTURE: fixture ? '1' : '0' },
    stdio: ['ignore', fd, fd],
  });
  fs.closeSync(fd);
  servers.add(child);
  child.on('exit', () => servers.delete(child));
  let failure;
  child.on('error', error => { failure = error; servers.delete(child); });
  const end = Date.now() + 30_000;
  while (Date.now() < end && !failure && child.exitCode === null) {
    if (fs.existsSync(portFile)) {
      const port = fs.readFileSync(portFile, 'utf8');
      try {
        const response = await fetch(`http://127.0.0.1:${port}/api/health`, { signal: AbortSignal.timeout(2_000) });
        if (response.ok) return { child, port, url: `http://127.0.0.1:${port}/api` };
      } catch (_) { /* Nest may still be binding. */ }
    }
    await delay(400);
  }
  throw new Error(`A API não iniciou. Consulte ${log}.`);
}

async function api(url, endpoint, { body, token, expected = 200 } = {}) {
  const response = await fetch(url + endpoint, {
    method: body === undefined ? 'GET' : 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(8_000),
  });
  if (response.status !== expected) throw new Error(`${endpoint} retornou HTTP ${response.status} (esperado ${expected}).`);
  return response.json();
}

async function seedAccount(url) {
  const response = await fetch(url + '/auth/register', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(account), signal: AbortSignal.timeout(8_000),
  });
  if (response.status === 201) return;
  const session = await api(url, '/auth/login', { body: account, expected: 201 });
  await api(url, '/auth/logout', { body: {}, token: session.accessToken, expected: 201 });
}

async function testSuites(npm, flutter) {
  const hash = require('node:crypto').createHash('sha256').update(fs.readFileSync(path.join(backend, 'package-lock.json'))).digest('hex');
  const cache = path.join(backend, 'node_modules', '.guardian-run-lock');
  const key = `${process.version}:${hash}`;
  if (!fs.existsSync(cache) || fs.readFileSync(cache, 'utf8') !== key) {
    run(npm, ['ci', '--include=dev', '--no-audit', '--no-fund'], { cwd: backend });
    fs.writeFileSync(cache, key);
  }
  run(npm, ['run', 'build'], { cwd: backend });
  run(npm, ['test'], { cwd: backend });
  const integration = await startApi('integracao', path.join(runDir, 'integracao.json'));
  try {
    const copy = path.join(runDir, 'scripts-integration.cjs');
    fs.copyFileSync(path.join(backend, 'scripts-integration.cjs'), copy);
    run(process.execPath, [copy], { env: { ...process.env, GUARDIAN_TEST_URL: integration.url } });
  } finally {
    integration.child.kill();
  }
  for (const app of ['guardian_pais', 'guardian_kids']) {
    const cwd = path.join(root, 'apps', app);
    const cached = run(flutter, ['pub', 'get', '--offline'], { cwd, allowFailure: true });
    if (cached.status !== 0) run(flutter, ['pub', 'get'], { cwd });
    run(flutter, ['test', '--no-pub'], { cwd });
  }
}

function stop() {
  menu?.close();
  for (const child of servers) child.kill();
  if (lock) {
    const currentLock = lock;
    lock = undefined;
    try { fs.rmdirSync(currentLock); } catch (_) { /* Keeps a conflicting run intact. */ }
  }
}

async function main() {
  const [option, extra] = process.argv.slice(2);
  if (option === '--help' || option === '-h') {
    say('node scripts/testar-guardian.cjs [--e2e | --somente-testes]');
    return;
  }
  if (extra || (option && !['--e2e', '--somente-testes'].includes(option))) {
    throw new Error('Use sem opções, --e2e ou --somente-testes.');
  }
  if (Number(process.versions.node.split('.')[0]) < 20) throw new Error('Instale Node.js 22 ou posterior.');
  const npm = locate(windows ? 'npm.cmd' : 'npm');
  const flutter = locate(process.env.FLUTTER_BIN) || locate(windows ? 'flutter.bat' : 'flutter') ||
    locate(path.join(os.homedir(), 'flutter', 'bin', windows ? 'flutter.bat' : 'flutter'));
  if (!npm || !flutter) throw new Error('Instale Node.js com npm e Flutter e abra um novo Terminal.');
  fs.mkdirSync(dataRoot, { recursive: true });
  const lockPath = path.join(dataRoot, '.em-uso');
  try { fs.mkdirSync(lockPath); } catch (_) { throw new Error('Já há uma execução nesta pasta. Encerre a anterior.'); }
  lock = lockPath;
  process.once('exit', stop);
  for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => process.exit(0));
  runDir = fs.mkdtempSync(path.join(dataRoot, 'execucao-'));
  const git = locate('git');
  const commit = git && run(git, ['rev-parse', '--short', 'HEAD'], { capture: true, allowFailure: true }).stdout;
  if (commit?.trim()) say(`Versão local em teste: ${commit.trim()}`);

  say('Rodando testes do backend e dos dois apps…');
  await testSuites(npm, flutter);
  if (option === '--somente-testes') return;
  const { sdk, adb } = sdkTools();
  const device = adbTools(adb);
  const { serial, target } = await device.boot(sdk);
  const send = (args, options) => device.call(['-s', serial, ...args], options);
  const e2e = option === '--e2e';
  const suffix = e2e ? 'e2e' : 'teste';
  const running = await startApi('api', e2e ? path.join(runDir, 'familia.json') : path.join(dataRoot, 'familia.json'), e2e);
  await seedAccount(running.url);
  const component = app => `com.example.${app}.${suffix}/com.example.${app}.MainActivity`;
  function open(app) {
    const result = send(['shell', 'am', 'start', '-W', '-n', component(app)], { capture: true, timeout: 60_000 });
    if (!/^Status: ok\b/m.test(result.stdout)) throw new Error(`Não foi possível abrir ${app}.`);
  }
  for (const app of ['guardian_pais', 'guardian_kids']) {
    say(`Preparando ${app} no Android…`);
    const cwd = path.join(root, 'apps', app);
    run(flutter, ['build', 'apk', '--debug', '--no-pub', '--target-platform', target,
      `--dart-define=GUARDIAN_API_URL=http://10.0.2.2:${running.port}/api`,
      ...(e2e ? ['--dart-define=GUARDIAN_ENABLE_NOTIFICATION_FIXTURE=true'] : []),
    ], {
      cwd, env: { ...process.env, ANDROID_HOME: sdk, ORG_GRADLE_PROJECT_guardianTestSuffix: suffix },
    });
    send(['install', '--no-streaming', '-r', path.join(cwd, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk')], { timeout: 120_000 });
    if (e2e) send(['shell', 'pm', 'clear', `com.example.${app}.e2e`]);
    open(app);
  }
  if (e2e) {
    const { testAndroidFlow } = require('./guardian-android-e2e.cjs');
    await testAndroidFlow({ root, sdk, runDir, account, running, fixturePackage, windows, locate, run, send, open, api, say });
    return;
  }

  say(`Os apps estão prontos no emulador. A API permanece ligada enquanto este Terminal estiver aberto.
Conta fictícia no Pais: ${account.email}
Senha de teste: ${account.password}

No Pais: crie um perfil em Filhos, configure Autorizações e gere um código.
No Kids: cole o código e ative a análise em Proteção. Use --e2e para validar o
fluxo de alerta automaticamente com notificações fictícias.`);
  say(`API de teste: ${running.url}/health`);
  menu = readline.createInterface({ input: process.stdin, output: process.stdout });
  running.child.once('exit', () => menu.close());
  const prompt = () => process.stdout.write('\n[1] Abrir Pais  [2] Abrir Kids  [q] Encerrar API: ');
  prompt();
  for await (const line of menu) {
    const answer = line.trim().toLowerCase();
    if (answer === 'q' || running.child.exitCode !== null) break;
    if (answer === '1' || answer === '2') open(answer === '1' ? 'guardian_pais' : 'guardian_kids');
    prompt();
  }
  if (running.child.exitCode !== null) throw new Error('A API foi interrompida. Consulte api.log.');

}

main().catch(error => {
  console.error(`\n${error.message}`);
  process.exitCode = 1;
}).finally(() => {
  stop();
  if (runDir) say(`Relatórios desta execução: ${runDir}`);
});
