import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { LoginService } from '../services/login.service';
import { map, retry } from 'rxjs/operators';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';

declare function init_plugins();

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnInit {

  cargando = false;
  email = '';
  code = '';

  constructor( public router: Router,
               private loginService: LoginService) { }

  ngOnInit() {
    init_plugins();
  }

  ingresar() {
    console.log('ingresando....');
  }

  doLogin() {
    this.cargando = true;
    this.loginService.login( this.email, this.code )
    .pipe(
        retry( 2 ),
        map( (data: any) => data.datos[0] )
    )
    .subscribe(
        data => { // console.log( 'resp', data );
                  try {
                    if ( data.id ) {
                      this.loginService.put( data );
                      this.router.navigate(['/dashboard']);
                    }
                  } catch (error) {
                    Swal.fire({
                      icon: 'error',
                      title: 'Oops...',
                      text: 'Email/Password no coinciden',
                      footer: '<a href>Corrija y reintente</a>'
                    });
                  }
                },
            err  => console.log( 'Err', err ),
            ()   => { this.cargando = false; }
    );
  }

/*
    .subscribe(
      data => {
        this.cargando = false;
        if ( data['resultado'] === 'ok' && data['datos'].length > 0 ) {
          this.loginService.put( data['datos'].nombre );
          console.log('logeado');
          this.router.navigate(['/main/home']);
        } else {
          alert( 'Usuario/Clave no coinciden. Reintente.' );
        }
      },
      err => {
        console.log('no logueado');
        this.cargando = false;
        console.error(err);
      }
    );
*/

}
