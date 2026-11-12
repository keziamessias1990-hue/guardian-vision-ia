import { AlertsController } from './alerts.controller';

describe('AlertsController', () => {
  it('lista alertas do ambiente de demonstração', () => {
    const controller = new AlertsController();

    expect(controller.list()).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          category: 'secret-sharing',
        }),
      ]),
    );
  });

  it('cria um alerta mínimo sem texto bruto', () => {
    const controller = new AlertsController();

    const result = controller.create({
      childId: 'child-1',
      category: 'platform-change',
      severity: 'medium',
      summary: 'Mudança para outra plataforma',
    });

    expect(result).toMatchObject({
      childId: 'child-1',
      category: 'platform-change',
      severity: 'medium',
      source: 'demo',
      confirmationState: 'pending',
    });
  });
});
