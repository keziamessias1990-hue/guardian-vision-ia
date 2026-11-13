import { Injectable } from '@nestjs/common';

export type AlertCategory =
  | 'secret-sharing'
  | 'platform-change'
  | 'personal-data'
  | 'general-risk';

export type AlertSeverity = 'low' | 'medium' | 'high';

export interface AlertPayload {
  childId: string;
  category: AlertCategory;
  severity: AlertSeverity;
  summary: string;
  source?: string;
}

export interface AlertRecord extends AlertPayload {
  id: string;
  occurredAt: string;
  confirmationState: 'pending' | 'confirmed' | 'dismissed';
}

@Injectable()
export class AlertsService {
  private readonly alerts: AlertRecord[] = [
    {
      id: 'alert-001',
      childId: 'child-1',
      category: 'secret-sharing',
      severity: 'medium',
      summary: 'Discussão com pedido de segredo e mudança para outro aplicativo.',
      source: 'guardian_kids',
      occurredAt: '2026-11-12T09:00:00.000Z',
      confirmationState: 'pending',
    },
    {
      id: 'alert-002',
      childId: 'child-2',
      category: 'personal-data',
      severity: 'high',
      summary: 'Pedido de dados pessoais e endereço em conversa suspeita.',
      source: 'guardian_kids',
      occurredAt: '2026-11-12T09:15:00.000Z',
      confirmationState: 'confirmed',
    },
  ];

  findAll(): AlertRecord[] {
    return [...this.alerts].reverse();
  }

  create(payload: AlertPayload): AlertRecord {
    const record: AlertRecord = {
      id: `alert-${Date.now()}`,
      childId: payload.childId,
      category: payload.category,
      severity: payload.severity,
      summary: payload.summary,
      source: payload.source ?? 'guardian_kids',
      occurredAt: new Date().toISOString(),
      confirmationState: 'pending',
    };

    this.alerts.push(record);
    return record;
  }
}
