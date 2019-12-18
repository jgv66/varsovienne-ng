import { Component, OnInit } from '@angular/core';
import { LoginService } from '../../services/login.service';
import { StockService } from '../../services/stock.service';

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
    this.leyendo = true;
    //
    this.stockSS.retrieveTraslado( this.destino, 'S', this.folio, this.nrointerno )
        .subscribe( (resultado: any) => {
          //
          const reg = resultado.datos[0];
          this.enca = reg;
          //
          this.detalleTraslado();
          //
        });
  }
  detalleTraslado() {
    this.stockSS.retrieveDetalle( this.enca.id )
        .subscribe( (resultado: any) => {
          //
          this.deta = resultado.datos;
          this.leyendo = false;
          this.recalculaTotal();
          //
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

  recalculaTotal() {
    let aceptados = 0;
    this.totalItemes = 0;
    this.deta.forEach(element => {
      this.totalItemes += element.subTotal;
      aceptados += (element.aceptado)
    });
  }

}
