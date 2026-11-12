import { Injectable, UnauthorizedException } from '@nestjs/common';
import { mockParents } from '../mock-data';
import { LoginRequestDto, LoginResponseDto } from '../guardian.types';

@Injectable()
export class AuthService {
  login({ email }: LoginRequestDto): LoginResponseDto {
    const parent = mockParents.find((item) => item.email === email);

    if (!parent) {
      throw new UnauthorizedException('Credenciais inválidas para o ambiente de demonstração.');
    }

    return {
      token: `demo-token-${parent.id}`,
      parent,
    };
  }
}
