import { ChildrenController } from './children.controller';

describe('ChildrenController', () => {
  it('lista crianças cadastradas', () => {
    const controller = new ChildrenController();

    expect(controller.list()).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          name: 'Ana',
        }),
      ]),
    );
  });

  it('cria uma nova criança', () => {
    const controller = new ChildrenController();

    const result = controller.create({
      parentId: 'parent-1',
      name: 'Pedro',
      ageGroup: '7-9',
    });

    expect(result).toMatchObject({
      parentId: 'parent-1',
      name: 'Pedro',
      ageGroup: '7-9',
      status: 'pending',
    });
  });
});
