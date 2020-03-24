import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class SettingsService {

  ajustes: Ajustes = {
    temaUrl: 'assets/css/colors/default.css',
    tema: 'default'
  };

  constructor() {
    this.cargarAjustes();
  }
  cargarAjustes() {
    // existe la variable?
    if ( localStorage.getItem( 'ajustes' ) ) {
      this.ajustes = JSON.parse( localStorage.getItem( 'ajustes' ) );
      this.aplicarTema( this.ajustes.tema );
    } else {
      this.aplicarTema( this.ajustes.tema );
    }
  }

  guardarAjustes() {
    localStorage.setItem( 'ajustes', JSON.stringify( this.ajustes ) );
  }

  aplicarTema( tema: string ) {

    const url = `assets/css/colors/${ tema }.css`;
    document.getElementById('tema').setAttribute('href', url );
    //
    this.ajustes.tema    = tema;
    this.ajustes.temaUrl = url;

    this.guardarAjustes();
    //
  }

}

interface Ajustes {
  temaUrl: string;
  tema: string;
}
