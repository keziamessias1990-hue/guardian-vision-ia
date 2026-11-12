import { Body, Controller, Post } from '@nestjs/common';
import { LoginRequestDto, LoginResponseDto } from '../guardian.types';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  login(@Body() body: LoginRequestDto): LoginResponseDto {
    return this.authService.login(body);
  }
}
