import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services/login.service';
import { StockService } from '../../services/stock.service';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';

interface Documento {
  tipo: string;
  bodega: string;
  numero: number;
  folio: string;   // trabajo con string pero se grama como numero
  codigoSII: number;
  electronico: boolean;
  tipoServSII: number;  // consumo interno = 3
  concepto: string;
  descConcepto: string;
  causal: string;
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
  codigo: string;
  descripcion: string;
  unidadMed: string;
  cantidad: string;
  netoUnitario: number;
  subTotal: number;
}

@Component({
  selector: 'app-guiasci',
  templateUrl: './guiasci.component.html',
  styles: []
})
export class GuiasciComponent implements OnInit {

  causales = [];
  cargando = false;
  grabando = false;
  totalItemes = 0;
  bodegas: any;
  deta: Array<Detalle> = [];
  enca: Documento;

  constructor( private login: LoginService,
               private stockSS: StockService ) {
  }

  ngOnInit() {
    // console.log(this.login.usuario);
    this.bodegas = this.login.localesPermitidos;
    // console.log(this.bodegas);
    this.stockSS.retieveCausales()
        .subscribe( (data: any) => {
          this.causales = data.datos;
        });
    this.inicializar();
  }

  inicializar() {
    this.enca = { tipo: 'S',
                  bodega: '',
                  numero: undefined,
                  folio: undefined,   // trabajo con string pero se grama como numero
                  codigoSII: 0,
                  electronico: false,
                  tipoServSII: 0,  // consumo interno = 3
                  concepto: '07',
                  descConcepto: 'Consumo Interno',
                  causal:  '',
                  fecha: new Date(),
                  glosa: 'Consumo Interno',
                  ccosto: undefined,
                  descCCosto: '',
                  usuario: this.login.usuario.id,
                  vendedor: '',
                  neto: 0,
                  iva: 0,
                  bruto: 0 };
  }

  ValidarConsumo() {
    this.grabando = true;
    //
    this.enca.neto  = Math.round( this.totalItemes );
    this.enca.iva   = Math.round( this.totalItemes * 0.19 );
    this.enca.bruto = Math.round( this.enca.iva + this.enca.neto );
    //
    if ( this.deta.length === 0 ) {
      this.grabando = false;
      Swal.fire('Detalle de la guía no puede estar vacío');
    } else if ( this.enca.bodega === '' ) {
      this.grabando = false;
      Swal.fire('Bodega no puede estar vacía');
    } else if ( this.enca.causal === '' ) {
      this.grabando = false;
      Swal.fire('Causal no puede estar vacía');
    } else if ( this.enca.fecha === undefined ) {
      this.grabando = false;
      Swal.fire('Fecha no puede estar vacía');
    } else {
      //
      this.stockSS.getFolio( this.enca.tipo, this.enca.concepto, this.enca.bodega )
          .subscribe( (folio: any) => {
            //
            console.log('luego de solicitar FOLIOS ',folio);
            //
            this.enca.folio  = folio.datos[0].Folio  + 1;
            this.enca.numero = folio.datos[0].NroInt + 1;
            //
            this.stockSS.grabarGuiaDeConsumo( this.enca, this.deta )
                .subscribe( (data: any) => {
                    //
                    console.log('RESPUESTA -> ', data);
                    //
                    this.grabando = false;
                    if ( data.resultado === 'ok' ) {
                      Swal.fire('La guía de consumo fue grabada con éxito');
                    } else {
                      Swal.fire({
                        icon: 'error',
                        title: 'Cuidado...',
                        text: 'La Guía de Consumo no fue grabada!',
                        footer: '<a href>' + data.datos + '</a>'
                      });
                    }
                });
          });
          //
      }
  }

  actualizarItemes( event ) {
    // console.log(event);
    this.deta.push( { codigo: event.CodProd,
                      descripcion: event.DesProd,
                      unidadMed: event.unidadMed,
                      cantidad: event.cantidad,
                      netoUnitario: event.netoUnitario,
                      subTotal: event.cantidad * event.netoUnitario
                    }
                  );
    this.recalculaTotal();
  }

  quitarCodigo( det: any ) {
    let index = 0;
    this.deta.forEach(element => {
      if ( element.codigo === det.codigo ) {
        this.deta.splice(index, 1);
        this.recalculaTotal();
        return;
      }
      index += 1;
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

}

