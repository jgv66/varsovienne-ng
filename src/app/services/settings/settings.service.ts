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

  guardarAjustes() {
    // console.log('guardado en localStrorage');
    localStorage.setItem( 'ajustes', JSON.stringify( this.ajustes ) );
  }

  cargarAjustes() {
    // existe la variable?
    if ( localStorage.getItem( 'ajustes' ) ) {
      this.ajustes = JSON.parse( localStorage.getItem( 'ajustes' ) );
      // console.log('cargando de ajustes');
      this.aplicarTema( this.ajustes.tema );
    } else {
      // console.log('valores por default');
      this.aplicarTema( this.ajustes.tema );
    }
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
