import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  it('retorna token para um responsável válido', () => {
    const service = new AuthService();

    expect(service.login({ email: 'mae@guardianvision.local' })).toMatchObject({
      token: expect.any(String),
      parent: expect.objectContaining({
        email: 'mae@guardianvision.local',
      }),
    });
  });

  it('lança erro para email inexistente', () => {
    const service = new AuthService();

    expect(() => service.login({ email: 'inexistente@guardianvision.local' })).toThrow(UnauthorizedException);
  });
});
