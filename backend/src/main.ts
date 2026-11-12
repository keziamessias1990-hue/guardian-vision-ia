import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');

  const requestedPort = Number(process.env.PORT ?? 3000);
  const portsToTry = Array.from(new Set([requestedPort, 3001, 3002, 3003, 3004, 3010]));

  for (const port of portsToTry) {
    try {
      await app.listen(port);
      console.log(`API iniciada em http://localhost:${port}/api`);
      return;
    } catch (error) {
      const err = error as NodeJS.ErrnoException;
      if (err.code !== 'EADDRINUSE') {
        throw error;
      }
      console.warn(`Porta ${port} ocupada, tentando a próxima disponível...`);
    }
  }

  throw new Error('Nenhuma porta disponível para iniciar a API. Feche outro processo ou libere a porta 3000/3001.');
}

void bootstrap();
