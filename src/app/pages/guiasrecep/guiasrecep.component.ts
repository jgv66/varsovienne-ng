import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services/login.service';
import { StockService } from '../../services/stock.service';

interface Documento {
  tipo: string;
  bodega: string;
  destino: string;
  auxiliar: string;
  numero: number;
  folio: string;   // trabajo con string pero se grama como numero
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
  codigo: string;
  descripcion: string;
  unidadMed: string;
  cantidad: string;
  netoUnitario: number;
  subTotal: number;
}

@Component({
  selector: 'app-guiasrecep',
  templateUrl: './guiasrecep.component.html',
  styles: []
})
export class GuiasrecepComponent implements OnInit {

  folio: number;
  nrointerno: number;
  destino: string;
  //
  causales = [];
  cargando = false;
  leyendo = false;
  totalItemes = 0;
  bodegas: any;
  destinos: any;
  auxiliares: any;
  deta: Array<Detalle> = [];
  enca: Documento;

  constructor( private login: LoginService,
               private stockSS: StockService) { }

  ngOnInit() {
    this.inicializar();
  }

  inicializar() {
    this.deta = [];
    this.enca = { tipo: 'E',
                  bodega: '',
                  destino: '',
                  auxiliar: '',
                  numero: undefined,
                  folio: undefined,   // trabajo con string pero se grama como numero
                  codigoSII: 0,
                  electronico: false,
                  tipoServSII: 0,  // consumo interno = 3
                  concepto: '03',
                  descConcepto: 'Traslado entre bodegas',
                  fecha: new Date(),
                  glosa: 'Traslado entre bodegas',
                  ccosto: undefined,
                  descCCosto: '',
                  usuario: this.login.usuario.id,
                  vendedor: '',
                  neto: 0,
                  iva: 0,
                  bruto: 0 };
    this.recalculaTotal();
  }

  ValidarRecepcion() {
    //
    console.log(this.folio);
    console.log(this.nrointerno);
    //
    this.leyendo = true;
    //
    this.stockSS.retrieveTraslado( this.destino, 'S', this.folio, this.nrointerno )
        .subscribe( (resultado: any) => {
          //
          console.log('resultado ', resultado.datos );
          //
        });
  }

  actualizarItemes( event ) {
    // console.log(event);
    this.deta.push( { codigo: event.CodProd,
                      descripcion: event.DesProd,
                      unidadMed: event.unidadMed,
                      cantidad: event.cantidad,
                      netoUnitario: event.netoUnitario,
                      subTotal: Math.round( event.cantidad * event.netoUnitario )
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

  recalculaTotal() {
    this.totalItemes = 0;
    this.deta.forEach(element => {
      this.totalItemes += element.subTotal;
    });
  }

}
