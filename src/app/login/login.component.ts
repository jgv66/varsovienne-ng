import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { LoginService } from '../services/login.service';
import { StockService } from '../services/stock.service';
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
  yaEstoy = false;

  constructor( public router: Router,
               public stockSS: StockService,
               private loginService: LoginService) { }

  ngOnInit() {
    init_plugins();
  }

  ingresar() {
    console.log('ingresando....');
  }

  doLogin() {
    if ( !this.yaEstoy ) {
      this.yaEstoy = true;
      this.cargando = true;
      this.loginService.login( this.email, this.code )
      .pipe(
          retry( 2 ),
          map( (data: any) => data.datos[0] )
      )
      .subscribe(
          data => { try {
                      if ( data.id ) {
                        this.loginService.put( data );  /* esta accion gatilla el relleno de datos */
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
      this.yaEstoy = false;
    }
  }

}
