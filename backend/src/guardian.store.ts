import { BadRequestException, ForbiddenException, HttpException, Injectable, UnauthorizedException } from '@nestjs/common';
import { randomBytes, randomInt, randomUUID, createHash, pbkdf2Sync, timingSafeEqual } from 'crypto';
import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'fs';
import { dirname, resolve } from 'path';

type Parent = { id: string; email: string; passwordHash: string; salt: string };
type ProtectionReport = { status: 'active' | 'paused'; reportedAt: string; revision: number };
type Child = { protectionSources?: string[]; protectionRevision?: number; protectionReport?: ProtectionReport; id: string; parentId: string; name: string; ageGroup: string; status: 'pending' | 'linked'; createdAt: string };
type Pair = { childId: string; parentId: string; hash: string; expiresAt: number; used: boolean };
type Session = { parentId: string; hash: string; expiresAt: number };
type Device = { childId: string; hash: string; createdAt: string; revoked: boolean };
type Alert = { id: string; childId: string; category: string; severity: string; occurredAt: string; confirmationState: string; source: string; contested: boolean };
type State = { parents: Parent[]; children: Child[]; pairings: Pair[]; sessions: Session[]; devices: Device[]; alerts: Alert[] };
const empty = (): State => ({ parents: [], children: [], pairings: [], sessions: [], devices: [], alerts: [] });
const allowed = (value: unknown, keys: string[]) => {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).some(k => !keys.includes(k))) throw new BadRequestException('Campos inválidos ou não permitidos');
};
const requireText = (v: unknown, max = 120): string => {
  if (typeof v !== 'string' || !v.trim() || v.length > max) throw new BadRequestException('Texto inválido');
  return v.trim();
};
const hash = (v: string) => createHash('sha256').update(v).digest('hex');
const protectionSources = new Set([
  'com.whatsapp', 'com.discord', 'org.telegram.messenger', 'com.roblox.client',
]);
const pairingAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
const shortPairingCode = () => Array.from(
  { length: 8 }, () => pairingAlphabet[randomInt(pairingAlphabet.length)],
).join('');
const token = () => randomBytes(32).toString('base64url');
@Injectable()
export class GuardianStore {
  private readonly path = resolve(process.env.GUARDIAN_DATA_FILE ?? './data/guardian-dev.json');
  private state: State;
  private readonly controlAttempts = new Map<string, { count: number; until: number }>();
  constructor() {
    this.state = existsSync(this.path) ? JSON.parse(readFileSync(this.path, 'utf8')) as State : empty();
  }
  private save() {
    mkdirSync(dirname(this.path), { recursive: true });
    const tmp = `${this.path}.${process.pid}.tmp`;
    writeFileSync(tmp, JSON.stringify(this.state, null, 2), { mode: 0o600 });
    renameSync(tmp, this.path);
  }
  register(body: any) {
    allowed(body, ['email', 'password']);
    const email = requireText(body.email).toLowerCase();
    const password = requireText(body.password, 256);
    if (!/^\S+@\S+\.\S+$/.test(email) || password.length < 12) throw new BadRequestException('Email inválido ou senha com menos de 12 caracteres');
    if (this.state.parents.some(p => p.email === email)) throw new BadRequestException('Conta já cadastrada');
    const salt = randomBytes(16).toString('hex');
    const parent = { id: randomUUID(), email, salt, passwordHash: pbkdf2Sync(password, salt, 210000, 32, 'sha256').toString('hex') };
    this.state.parents.push(parent); this.save(); return { id: parent.id, email };
  }
  login(body: any) {
    allowed(body, ['email', 'password']);
    const email = requireText(body.email).toLowerCase(); const password = requireText(body.password, 256);
    const parent = this.state.parents.find(p => p.email === email);
    if (!parent) throw new UnauthorizedException('Credenciais inválidas');
    this.verifyPassword(parent, password);
    const accessToken = token();
    this.state.sessions.push({ parentId: parent.id, hash: hash(accessToken), expiresAt: Date.now() + 12 * 60 * 60 * 1000 });
    this.save(); return { accessToken, expiresInSeconds: 43200 };
  }
  private verifyPassword(parent: Parent, password: string) {
    const calculated = pbkdf2Sync(password, parent.salt, 210000, 32, 'sha256');
    if (!timingSafeEqual(calculated, Buffer.from(parent.passwordHash, 'hex'))) throw new UnauthorizedException('Credenciais inválidas');
  }
  profile(authorization?: string) {
    const id = this.parent(authorization);
    const parent = this.state.parents.find(p => p.id === id);
    if (!parent) throw new UnauthorizedException('Sessão de responsável inválida');
    return { id: parent.id, email: parent.email };
  }
  confirmPassword(authorization: string | undefined, body: unknown) {
    const { id } = this.profile(authorization);
    allowed(body, ['password']);
    const password = requireText((body as { password?: unknown }).password, 256);
    this.verifyPassword(this.state.parents.find(parent => parent.id === id)!, password);
    return { confirmed: true };
  }
  logout(authorization?: string) {
    const bearer = authorization?.match(/^Bearer (\S+)$/)?.[1];
    // Valida a sessão antes de removê-la. Sem isso um token inválido pareceria sair com sucesso.
    this.parent(authorization);
    const digest = hash(bearer!);
    this.state.sessions = this.state.sessions.filter(s => s.hash !== digest);
    this.save();
    return { loggedOut: true };
  }
  parent(authorization?: string) {
    const t = authorization?.match(/^Bearer (\S+)$/)?.[1];
    const session = t && this.state.sessions.find(s => s.hash === hash(t) && s.expiresAt > Date.now());
    if (!session) throw new UnauthorizedException('Sessão de responsável inválida');
    return session.parentId;
  }
  children(parentId: string) { return this.state.children.filter(c => c.parentId === parentId); }
  addChild(parentId: string, body: any) {
    allowed(body, ['name', 'ageGroup']);
    const name = requireText(body.name, 80); const ageGroup = requireText(body.ageGroup, 20);
    const child: Child = { id: randomUUID(), parentId, name, ageGroup, status: 'pending', createdAt: new Date().toISOString() };
    this.state.children.push(child); this.save(); return child;
  }
  private owned(parentId: string, childId: string) {
    const child = this.state.children.find(c => c.id === childId && c.parentId === parentId);
    if (!child) throw new ForbiddenException('Criança não pertence à família');
    return child;
  }
  setProtectionSources(parentId: string, childId: string, body: unknown) {
    const child = this.owned(parentId, childId);
    allowed(body, ['sources']);
    const sources = (body as { sources?: unknown }).sources;
    if (!Array.isArray(sources) || sources.length > protectionSources.size ||
        sources.some(source => typeof source !== 'string' || !protectionSources.has(source))) {
      throw new BadRequestException('Aplicativos de proteção inválidos');
    }
    const nextSources = [...new Set(sources)].sort();
    const previous = [...(child.protectionSources ?? [])].sort();
    if (JSON.stringify(previous) !== JSON.stringify(nextSources)) {
      child.protectionRevision = (child.protectionRevision ?? 0) + 1;
    }
    child.protectionSources = nextSources;
    this.save();
    return { sources: child.protectionSources };
  }
  private linkedDeviceChild(authorization?: string) {
    const token = authorization?.match(/^Bearer (\S+)$/)?.[1];
    const device = token && this.state.devices.find(d => d.hash === hash(token) && !d.revoked);
    const child = device && this.state.children.find(c => c.id === device.childId && c.status === 'linked');
    if (!child) throw new UnauthorizedException('Dispositivo não vinculado');
    return child;
  }
  deviceProtection(authorization?: string) {
    const child = this.linkedDeviceChild(authorization);
    return { sources: child.protectionSources ?? [], revision: child.protectionRevision ?? 0 };
  }
  reportProtection(authorization: string | undefined, body: unknown) {
    const child = this.linkedDeviceChild(authorization);
    allowed(body, ['status', 'revision']);
    const report = body as { status?: unknown; revision?: unknown };
    if ((report.status !== 'active' && report.status !== 'paused') ||
        typeof report.revision !== 'number' || !Number.isSafeInteger(report.revision)) {
      throw new BadRequestException('Estado da proteção inválido');
    }
    if (report.revision !== (child.protectionRevision ?? 0) ||
        (report.status === 'active' && !child.protectionSources?.length)) {
      throw new HttpException('Configuração da proteção alterada', 409);
    }
    child.protectionReport = {
      status: report.status, revision: report.revision, reportedAt: new Date().toISOString(),
    };
    this.save();
    return { reportedAt: child.protectionReport.reportedAt };

  }
  confirmDeviceControl(authorization: string | undefined, body: unknown) {
    const child = this.linkedDeviceChild(authorization);
    allowed(body, ['password']);
    const password = requireText((body as { password?: unknown }).password, 256);
    const now = Date.now();
    const existing = this.controlAttempts.get(child.parentId);
    const attempt = existing && existing.until > now ? existing : { count: 0, until: now + 60_000 };
    if (attempt.count >= 5) throw new HttpException('Aguarde antes de tentar novamente', 429);
    this.controlAttempts.set(child.parentId, { ...attempt, count: attempt.count + 1 });
    const parent = this.state.parents.find(parent => parent.id === child.parentId);
    if (!parent) throw new UnauthorizedException('Responsável inválido');
    this.verifyPassword(parent, password);
    this.controlAttempts.delete(child.parentId);
    return { confirmed: true };
  }
  createPair(parentId: string, childId: string) {
    const child = this.owned(parentId, childId);
    if (child.status === 'linked') throw new BadRequestException('Dispositivo já vinculado');
    this.state.pairings = this.state.pairings.filter(p => p.childId !== childId);
    const now = Date.now();
    const activeHashes = new Set(this.state.pairings.filter(p => !p.used && p.expiresAt > now).map(p => p.hash));
    let code: string;
    do { code = shortPairingCode(); } while (activeHashes.has(hash(code)));
    const pairingCode = `${code.slice(0, 4)}-${code.slice(4)}`;
    const expiresAt = now + 5 * 60 * 1000;
    this.state.pairings.push({ parentId, childId, hash: hash(code), expiresAt, used: false });
    this.save(); return { pairingCode, expiresAt: new Date(expiresAt).toISOString(), childId };
  }
  confirmPair(body: any) {
    allowed(body, ['pairingCode']);
    const submitted = requireText(body.pairingCode, 100);
    const compact = submitted.replace(/[-\s]/g, '').toUpperCase();
    const digest = hash(compact.length === 8 ? compact : submitted);
    const now = Date.now();
    const pairing = this.state.pairings.find(p => p.hash === digest && !p.used && p.expiresAt > now);
    if (!pairing) throw new UnauthorizedException('Código expirado, inválido ou utilizado');
    pairing.used = true;
    const deviceToken = token();
    this.state.devices.push({ childId: pairing.childId, hash: hash(deviceToken), createdAt: new Date().toISOString(), revoked: false });
    const child = this.state.children.find(c => c.id === pairing.childId)!; child.status = 'linked';
    this.save(); return { childId: pairing.childId, deviceToken };
  }
  revoke(parentId: string, childId: string) {
    const child = this.owned(parentId, childId);
    for (const d of this.state.devices) if (d.childId === childId) d.revoked = true;
    this.state.pairings = this.state.pairings.filter(p => p.childId !== childId);
    child.status = 'pending'; delete child.protectionReport; this.save(); return { revoked: true };
  }
  createAlert(authorization: string | undefined, body: any) {
    allowed(body, ['childId', 'category', 'severity', 'occurredAt', 'confirmationState', 'source']);
    const childId = requireText(body.childId);
    const deviceToken = authorization?.match(/^Bearer (\S+)$/)?.[1];
    const device = deviceToken && this.state.devices.find(d => d.hash === hash(deviceToken) && !d.revoked && d.childId === childId);
    if (!device) throw new UnauthorizedException('Dispositivo não vinculado');
    if (!['secret-sharing', 'platform-change', 'personal-data', 'general-risk'].includes(body.category) ||
      !['low', 'medium', 'high'].includes(body.severity) || body.confirmationState !== 'pending' || !['guardian-kids-local', 'guardian-kids-notification'].includes(body.source)) throw new BadRequestException('Categoria, severidade, origem ou estado inválido');
    const occurredAt = requireText(body.occurredAt, 50);
    if (!Number.isFinite(Date.parse(occurredAt)) || Math.abs(Date.now() - Date.parse(occurredAt)) > 24 * 60 * 60 * 1000) throw new BadRequestException('Horário inválido');
    const alert: Alert = { id: randomUUID(), childId, category: body.category, severity: body.severity, occurredAt, confirmationState: 'pending', source: body.source, contested: false };
    this.state.alerts.push(alert); this.save(); return alert;
  }
  alerts(parentId: string) {
    const ids = new Set(this.children(parentId).map(c => c.id));
    return this.state.alerts.filter(a => ids.has(a.childId)).reverse();
  }
  contest(parentId: string, alertId: string) {
    const alert = this.state.alerts.find(a => a.id === alertId);
    if (!alert || !this.state.children.some(c => c.id === alert.childId && c.parentId === parentId)) throw new ForbiddenException('Alerta fora da família');
    alert.contested = true; this.save(); return alert;
  }
}
