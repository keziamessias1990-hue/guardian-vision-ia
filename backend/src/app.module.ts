import { Module } from '@nestjs/common';
import { AlertsController } from './alerts/alerts.controller';
import { AlertsService } from './alerts/alerts.service';
import { ChildrenController } from './children/children.controller';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';

@Module({
  controllers: [HealthController, ChildrenController, AlertsController],
  providers: [HealthService, AlertsService],
})
export class AppModule {}
