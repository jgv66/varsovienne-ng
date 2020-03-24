import { environment } from '../../environments/environment';
import { Injectable, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';

@Injectable({
  providedIn: 'root'
})
export class LoginService implements OnInit {

  API_URL: string;
  usuario = undefined;
  localesPermitidos = [];
  todoLocal = [];
  causales = [];

  constructor(private http: HttpClient,
              private router: Router) {
    this.API_URL = environment.API_URL;
  }

  // tslint:disable-next-line: contextual-lifecycle
  ngOnInit() {
  }

  login(email: string, code: string) {
    const xUrl = this.API_URL + '/login' ;
    return this.http.post( xUrl, { email, code } );
  }

  logout() {
    this.usuario = undefined;
    this.router.navigate(['/login']);
  }


  estaLogeado() {
    return ( this.usuario === undefined ) ? false : true ;
  }

  put( user ) {
    this.usuario = user;
    this.locales();
  }

  locales() {
    // console.log('locxuser', this.usuario);
    const xUrl = this.API_URL + '/locxuser' ;
    this.http.post( xUrl, { id: this.usuario.id } )
        .subscribe(
          (data: any) => {
              try {
                this.localesPermitidos = ( data.datos.length > 0 ) ? data.datos : [];
                this.todosLosLocales();
              } catch (error) {
                this.localesPermitidos = [];
              }
          },
          (err) => {
            return console.log('Err', err);
          }
        );
  }

  todosLosLocales() {
    // console.log('todosLosLocales',this.usuario);
    const xUrl = this.API_URL + '/locales' ;
    this.http.post( xUrl, { id: this.usuario.id }  )
        .subscribe(
          (data: any) => {
              try {
                this.todoLocal = ( data.datos.length > 0 ) ? data.datos : [];
              } catch (error) {
                this.todoLocal = [];
              }
              this.Causales();

          },
          err  => console.log( 'Err', err )
        );
  }

  Causales() {
    const xUrl = this.API_URL + '/causaconsumo' ;
    this.http.post( xUrl, {} )
        .subscribe( (data: any) => {
          try {
            this.causales = ( data.datos.length > 0 ) ? data.datos : [];
          } catch (error) {
            this.causales = [];
          }
      });
  }

  retrieveUsuarios( nombre ) {
    const xUrl = this.API_URL + '/usuarios' ;
    const body = { nombre };
    return this.http.post( xUrl, body );
  }

  saveUser( id, nombre, email, pssw, xsoft, xsuper, admin ) {
    const xUrl = this.API_URL + '/grabarUsuarios' ;
    const body = { id, nombre, email, pssw, xsoft, xsuper, admin };
    return this.http.post( xUrl, body );
  }

  retrieveFolios( nombre ) {
    const xUrl = this.API_URL + '/folios' ;
    const body = { nombre };
    return this.http.post( xUrl, body );
  }

  saveFolio( bodega, folio, desde, hasta ) {
    const xUrl = this.API_URL + '/updateFolio' ;
    const body = { bodega, folio, desde, hasta };
    return this.http.post( xUrl, body );
  }

}
