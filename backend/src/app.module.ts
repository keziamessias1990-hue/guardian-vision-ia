import { Module } from '@nestjs/common';
import { AlertsController } from './alerts/alerts.controller';
import { AuthController } from './auth/auth.controller';
import { AuthService } from './auth/auth.service';
import { ChildrenController } from './children/children.controller';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';
import { ParentsController } from './parents/parents.controller';

@Module({
  controllers: [HealthController, ParentsController, ChildrenController, AlertsController, AuthController],
  providers: [HealthService, AuthService],
})
export class AppModule {}
