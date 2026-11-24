import { Module } from '@nestjs/common';
import { GuardianController } from './guardian.controller';
import { GuardianStore } from './guardian.store';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';
@Module({ controllers: [HealthController, GuardianController], providers: [HealthService, GuardianStore] })
export class AppModule {}
