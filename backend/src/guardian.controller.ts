import { Body, Controller, Get, Headers, Param, Post } from '@nestjs/common';
import { GuardianStore } from './guardian.store';
@Controller()
export class GuardianController {
  constructor(private readonly store: GuardianStore) {}
  @Post('auth/register') register(@Body() b: any) { return this.store.register(b); }
  @Post('auth/login') login(@Body() b: any) { return this.store.login(b); }
  @Get('auth/me') profile(@Headers('authorization') auth?: string) { return this.store.profile(auth); }
  @Post('auth/confirm-password') confirmPassword(@Headers('authorization') auth: string, @Body() body: unknown) {
    return this.store.confirmPassword(auth, body);
  }
  @Post('auth/logout') logout(@Headers('authorization') auth?: string) { return this.store.logout(auth); }
  @Get('children') children(@Headers('authorization') auth?: string) { return this.store.children(this.store.parent(auth)); }
  @Post('children') addChild(@Headers('authorization') auth: string, @Body() b: any) { return this.store.addChild(this.store.parent(auth), b); }
  @Post('children/:id/protection') setProtection(@Headers('authorization') auth: string, @Param('id') id: string, @Body() body: unknown) {
    return this.store.setProtectionSources(this.store.parent(auth), id, body);
  }
  @Post('device/confirm-control') confirmDeviceControl(@Headers('authorization') auth: string, @Body() body: unknown) {
    return this.store.confirmDeviceControl(auth, body);
  }
  @Post('device/protection/status') reportProtection(@Headers('authorization') auth: string, @Body() body: unknown) {
    return this.store.reportProtection(auth, body);
  }
  @Get('device/protection') deviceProtection(@Headers('authorization') auth?: string) {
    return this.store.deviceProtection(auth);
  }
  @Post('children/:id/pairings') pair(@Headers('authorization') auth: string, @Param('id') id: string) { return this.store.createPair(this.store.parent(auth), id); }
  @Post('children/:id/revoke') revoke(@Headers('authorization') auth: string, @Param('id') id: string) { return this.store.revoke(this.store.parent(auth), id); }
  @Post('pairings/confirm') confirm(@Body() b: any) { return this.store.confirmPair(b); }
  @Get('alerts') alerts(@Headers('authorization') auth?: string) { return this.store.alerts(this.store.parent(auth)); }
  @Post('alerts') alert(@Headers('authorization') auth: string, @Body() b: any) { return this.store.createAlert(auth, b); }
  @Post('alerts/:id/contest') contest(@Headers('authorization') auth: string, @Param('id') id: string) { return this.store.contest(this.store.parent(auth), id); }
}
