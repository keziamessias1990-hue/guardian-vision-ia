import { HealthService } from './health.service';

describe('HealthService', () => {
  it('retorna o status da API', () => {
    expect(new HealthService().check()).toEqual({
      status: 'ok',
      service: 'guardian-api',
    });
  });
});
