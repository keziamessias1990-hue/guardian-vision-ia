import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CreateAlertDto, RiskAlertRecord } from '../guardian.types';
import { mockAlerts } from '../mock-data';

@Controller('alerts')
export class AlertsController {
  @Get()
  list(): RiskAlertRecord[] {
    return mockAlerts;
  }

  @Get(':id')
  detail(@Param('id') id: string): RiskAlertRecord | undefined {
    return mockAlerts.find((alert) => alert.id === id);
  }

  @Post()
  create(@Body() body: CreateAlertDto): RiskAlertRecord {
    const alert: RiskAlertRecord = {
      id: `alert-${Date.now()}`,
      childId: body.childId,
      category: body.category,
      severity: body.severity,
      source: body.source ?? 'demo',
      summary: body.summary ?? 'Alerta gerado pela demonstração local.',
      occurredAt: new Date().toISOString(),
      confirmationState: 'pending',
    };

    mockAlerts.push(alert);
    return alert;
  }
}
