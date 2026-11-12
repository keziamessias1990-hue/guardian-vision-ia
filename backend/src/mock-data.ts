import { ChildRecord, ParentRecord, RiskAlertRecord } from './guardian.types';

export const mockParents: ParentRecord[] = [
  {
    id: 'parent-1',
    name: 'Mãe responsável',
    email: 'mae@guardianvision.local',
    createdAt: new Date().toISOString(),
  },
];

export const mockChildren: ChildRecord[] = [
  {
    id: 'child-1',
    parentId: 'parent-1',
    name: 'Ana',
    ageGroup: '10-12',
    status: 'pending',
    createdAt: new Date().toISOString(),
  },
];

export const mockAlerts: RiskAlertRecord[] = [
  {
    id: 'alert-1',
    childId: 'child-1',
    category: 'secret-sharing',
    severity: 'medium',
    source: 'demo',
    summary: 'Pedido de segredo e mudança para outra plataforma.',
    occurredAt: new Date().toISOString(),
    confirmationState: 'pending',
  },
];
