import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services/login.service';
import { StockService } from '../../services/stock.service';

@Component({
  selector: 'app-guiasci',
  templateUrl: './guiasci.component.html',
  styles: []
})
export class GuiasciComponent implements OnInit {

  causales = [ { tipo: 'Degustacion'},
               { tipo: 'Evento'},
               { tipo: 'Regalo'},
               { tipo: 'Muestras'},
               { tipo: 'Otros'},
               { tipo: 'Compensación Cliente'},
               { tipo: 'Reuniones'}
              ]

  cargando = false;
  bodegas: any;
  deta: Array<Detalle> = [];

  enca: Documento;

  constructor( private login: LoginService,
               private stockSS: StockService ) {
  }

  ngOnInit() {
    this.bodegas = this.login.localesPermitidos;
    console.log(this.bodegas);
    this.stockSS.retieveCausales()
        .subscribe( (data: any) => {
          this.causales = data.datos;
        });
    this.inicializar();
  }

  inicializar() {
    this.enca = { bodega: '',
                  numero: undefined,
                  folio: undefined,   // trabajo con string pero se grama como numero
                  codigoSII: undefined,
                  electronico: false,
                  tipoServSII: undefined,  // consumo interno = 3
                  concepto: '07',
                  descConcepto: '',
                  fecha: new Date(),
                  glosa: 'Consumo Interno',
                  ccosto: undefined,
                  descCCosto: '',
                  usuario: undefined,
                  neto: 0,
                  iva: 0,
                  bruto: 0 };
  }

  ValidarConsumo() {}
}

interface Documento {
  bodega: string;
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