import { Injectable } from '@angular/core';
import { CanActivate } from '@angular/router';
import { LoginService } from '../login.service';

@Injectable()

export class LoginGuardGuard implements CanActivate {

  constructor( public login: LoginService) {}

  canActivate() {

    if ( this.login.estaLogeado ) {
      // console.log('paso por el loginGuard ');
      return true;
    } else {
      // console.log('bloqueado por el loginGuard ');
      return false;
    }

  }

}
