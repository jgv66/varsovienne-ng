import { environment } from '../../environments/environment';
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class LoginService {

  API_URL: string;
  usuario = undefined;
  localesPermitidos: [];
  todoLocal: [];

  constructor(private http: HttpClient) {
    this.API_URL = environment.API_URL;
  }

  login(email: string, code: string) {
    const xUrl = this.API_URL + '/login' ;
    return this.http.post( xUrl, { email, code } );
  }

  put( user ) {
    this.usuario = user;
    this.locales();
  }

  locales() {
    const xUrl = this.API_URL + '/localesxusario' ;
    this.http.post( xUrl, { id: this.usuario.id } )
        .subscribe(
          (data: any) => {
              try {
                this.localesPermitidos = ( data.datos.length > 0 ) ? data.datos : [];
                // console.log('permitidos', this.localesPermitidos);
                this.todosLosLocales();
              } catch (error) {
                this.localesPermitidos = [];
              }
          },
          err  => console.log( 'Err', err )
        );
  }

  todosLosLocales() {
    const xUrl = this.API_URL + '/locales' ;
    this.http.post( xUrl, { id: this.usuario.id }  )
        .subscribe(
          (data: any) => {
              try {
                this.todoLocal = ( data.datos.length > 0 ) ? data.datos : [];
                // console.log('todos', this.todoLocal);
              } catch (error) {
                this.todoLocal = [];
              }
          },
          err  => console.log( 'Err', err )
        );
  }

}
