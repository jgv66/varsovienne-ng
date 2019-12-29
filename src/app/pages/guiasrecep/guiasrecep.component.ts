import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services/login.service';
import { StockService } from '../../services/stock.service';
import { Router } from '@angular/router';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';

interface Documento {
  id: number;
  tipo: string;
  bodega: string;
  destino: string;
  auxiliar: string;
  numero: number;
  folio: string;   // trabajo con string pero se grama como numero
  id_origen: number;
  codigoSII: number;
  electronico: boolean;
  tipoServSII: number;  // consumo interno = 3
  concepto: string;
  descConcepto: string;
  fecha: Date;
  glosa: string;
  ccosto: string;
  descCCosto: string;
  vendedor: string;
  usuario: string;
  neto: number;
  iva: number;
  bruto: number;
}
interface Detalle {
  id: number;
  id_padre: number;
  id_origen: number;
  codigo: string;
  descripcion: string;
  unidadMed: string;
  cantidad: number;
  cant_original: number;
  netoUnitario: number;
  subTotal: number;
  estado: number;
  aceptado: boolean;
}

@Component({
  selector: 'app-guiasrecep',
  templateUrl: './guiasrecep.component.html',
  styles: []
})
export class GuiasrecepComponent implements OnInit {
  //
  folio: number;
  nrointerno: number;
  destino: string;
  //
  todosAceptados = false;
  cargando = false;
  grabando = false;
  leyendo = false;
  totalItemes = 0;
  bodegas: any;
  destinos: any;
  auxiliares: any;
  deta: Array<Detalle> = [];
  enca: Documento;

  constructor( private login: LoginService,
               private router: Router,
               private stockSS: StockService) { }

  ngOnInit() {
    if ( !this.login.usuario ) {
      this.router.navigate(['/login']);
    }
    this.bodegas = this.login.localesPermitidos;
    this.inicializar();
  }

  inicializar() {
    this.todosAceptados = false;
    this.deta = [];
    this.enca = { id: 0,
                  tipo: 'E',
                  bodega: '',
                  destino: '',
                  auxiliar: '',
                  numero: undefined,
                  folio: undefined,   // trabajo con string pero se grama como numero
                  id_origen: undefined,
                  codigoSII: 0,
                  electronico: false,
                  tipoServSII: 0,  // consumo interno = 3
                  concepto: '03',
                  descConcepto: 'Recepción de Traslado',
                  fecha: new Date(),
                  glosa: 'Recepción de Traslado',
                  ccosto: undefined,
                  descCCosto: '',
                  usuario: this.login.usuario.id,
                  vendedor: '',
                  neto: 0,
                  iva: 0,
                  bruto: 0 };
    this.recalculaTotal();
  }

  validarRecepcion() {
    //
    let swap = '';
    this.leyendo = true;
    //
    this.stockSS.retrieveTraslado( this.destino, 'S', this.folio, this.nrointerno )
        .subscribe( (resultado: any) => {
          //
          // console.log(resultado);
          if ( resultado.resultado === 'ok' ) {
            //
            this.enca           = resultado.datos[0];
            this.enca.id_origen = this.enca.id;
            this.enca.tipo      = 'E';
            this.enca.concepto  = '03';
            this.enca.fecha     = new Date();
            //
            swap                = this.enca.bodega;
            this.enca.bodega    = this.enca.destino;
            this.enca.destino   = swap;
            //
            this.detalleTraslado();
            //
          } else {
            //
            this.leyendo = false;
            Swal.fire(
              'ATENCION',
              'La recepción indicada no existe o ya fue recepcionada. Corrija y reintente.',
              'error'
            );
            //
          }
          //
        });
  }
  detalleTraslado() {
    this.stockSS.retrieveDetalle( this.enca.id )
        .subscribe( (resultado: any) => {
          //
          this.deta = resultado.datos;
          this.leyendo = false;
          this.rescataCC( this.destino );
          this.recalculaTotal();
          //
        });
  }

  cambiaAcepta() {
    this.deta.forEach(element => {
        element.aceptado = true;
    });
  }
  aceptarItem( det ) {
    det.aceptado = true;
    det.subTotal = Math.round( det.cantidad * det.netoUnitario );
    this.recalculaTotal();
  }
  restituirItem( det ) {
    det.cantidad = det.cant_original;
  }
  modificarItem( det ) {
    det.estado = 2;
  }
  eliminarItem( det: any ) {
    //
    Swal.fire({
      title: 'Está seguro?',
      text: 'El ítem será eliminado de la lista!',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText: 'Sí, bórrelo!'
    }).then((result) => {
      if (result.value) {
        let index = 0;
        this.deta.forEach(element => {
          if ( element.codigo === det.codigo ) {
            this.deta.splice(index, 1);
            this.recalculaTotal();
          }
          index += 1;
        });
        Swal.fire(
          'Borrado!',
          'El ítem fue eliminado de la lista.',
          'success'
        );
      }
    });
  }

  rescataCC( pBodega ) {
    this.stockSS.retieveCenCosto( pBodega )
        .subscribe( (data: any) => {
          this.enca.ccosto     = data.datos[0].CodiCC;
          this.enca.descCCosto = data.datos[0].DescCC;
          this.enca.vendedor   = data.datos[0].VenCod;
        });
  }
  recalculaTotal() {
    this.totalItemes = 0;
    this.deta.forEach(element => {
      this.totalItemes += element.subTotal;
    });
  }

  grabarRecepcion() {
    this.todosAceptados = true;
    this.deta.forEach(element => {
      if ( !element.aceptado ) {
        this.todosAceptados = false;
      }
      // relaciona al registro origen
      element.id_origen = element.id;
    });
    if ( this.todosAceptados ) {
      //
      this.grabando = true;
      this.stockSS.getFolio( this.enca.tipo, this.enca.concepto, this.enca.bodega )
          .subscribe( (folio: any) => {
            //
            try {
              //
              this.enca.folio  = folio.datos[0].Folio  + 1;
              this.enca.numero = folio.datos[0].NroInt + 1;
              //
              this.stockSS.grabarGuiaDeRecepcion( this.enca, this.deta )
                  .subscribe( (data: any) => {
                      //
                      console.log('RESPUESTA -> ', data);
                      //
                      this.grabando = false;
                      if ( data.resultado === 'ok' ) {
                        Swal.fire({
                          icon: 'success',
                          title: 'FOLIO: ' + data.datos[0].folio,
                          text: 'Guía de Recepción fue grabada con éxito',
                          footer: '<a href>Nro.Interno Softland: ' + data.datos[0].nroint + ' </a>'
                        });
                        this.inicializar();
                      } else {
                        this.grabando = false;
                        Swal.fire({
                          icon: 'error',
                          title: 'Cuidado...',
                          text: 'La Guía de Recepción no fue grabada!',
                          footer: '<a href>' + data.datos + '</a>'
                        });
                      }
                  });
            } catch (error) {
                this.grabando = false;
                Swal.fire({
                  icon: 'error',
                  title: 'Cuidado...',
                  text: 'La Guía de Recepción no fue grabada',
                  footer: '<a href>' + error + '</a>'
                });
            }
            //
          });
          //
    } else {
      Swal.fire(
        'ATENCION',
        'Todos los ítemes deben estar aceptados para intentar la grabación.',
        'error'
      );
  }
  }
}
