import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { LoginService } from '../../services/login.service';
import { StockService } from '../../services/stock.service';
import { map } from 'rxjs/operators';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';
// import * as printJS from 'print-js';

@Component({
  selector: 'app-iguiasc',
  templateUrl: './iguiasc.component.html',
  styles: []
})
export class IguiascComponent implements OnInit {

  cargando = false;
  girar = false;
  bodegas: any;
  bodega = '';
  guias = [];
  fechaini = new Date();
  fechafin = new Date();
  tipoDoc = ''; /* 0=todos, 1=consumo, 2=traslado, 3=recepcion */
  documentos = [  {tipo: '07', nombre: 'Guías de Consumo Interno'},
                  {tipo: '06', nombre: 'Guias de Traslado entre Locales'},
                  {tipo: '03', nombre: 'Guias de Recepción'}
               ];

  constructor( private login: LoginService,
               private router: Router,
               private stockSS: StockService ) {
  }

  ngOnInit() {
    if ( !this.login.usuario ) {
      this.router.navigate(['/login']);
    }
    this.bodegas = this.login.localesPermitidos;
  }

  limpiaLista() {
    this.guias = [];
  }

  consultar() {
    //
    this.cargando = true;
    //
    if ( this.bodega === '' ) {
      this.cargando = false;
      Swal.fire('Bodega/Local no puede estar vacío');
    } else if ( this.tipoDoc === '' ) {
      this.cargando = false;
      Swal.fire('Tipo de documento no puede estar vacío');
    } else {
    //
      this.stockSS.retrieveGuias( this.bodega, this.tipoDoc, this.fechaini, this.fechafin )
        .subscribe( (data: any) => {
            this.cargando = false;
            //
            if ( data.resultado === 'ok' ) {
              this.guias = data.datos;
            } else {
              Swal.fire('Sin datos para desplegar. Corrija fechas o tipo de documento y vuelva a intentarlo.');
            }
          });
    //
    }
  }

  imprimir( data ) {
    data.spinn = true;
    this.stockSS.imprimirGuia( data.tipo, data.folio, data.nroint )
      .pipe( map( (resp: any) => resp.datos ) )
      .subscribe( (pdf: any) => {
          setTimeout( () => {
              data.spinn = false;
              window.open( 'https://api.varsovienne.kinetik.cl/static/pdf/' + pdf );
          }, 600);
      });
  }

}

