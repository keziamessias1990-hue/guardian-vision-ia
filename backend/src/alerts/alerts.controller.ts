import { Body, Controller, Get, Post } from '@nestjs/common';
import { AlertPayload, AlertsService } from './alerts.service';

@Controller('alerts')
export class AlertsController {
  constructor(private readonly alertsService: AlertsService) {}

  @Get()
  findAll() {
    return this.alertsService.findAll();
  }

  @Post()
  create(@Body() payload: AlertPayload) {
    return this.alertsService.create(payload);
  }
}
