import { ParentsController } from './parents.controller';

describe('ParentsController', () => {
  it('lista responsáveis cadastrados', () => {
    const controller = new ParentsController();

    expect(controller.list()).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          email: 'mae@guardianvision.local',
        }),
      ]),
    );
  });

  it('cria um novo responsável', () => {
    const controller = new ParentsController();

    const result = controller.create({
      name: 'Pai responsável',
      email: 'pai@guardianvision.local',
    });

    expect(result).toMatchObject({
      name: 'Pai responsável',
      email: 'pai@guardianvision.local',
    });
  });
});
