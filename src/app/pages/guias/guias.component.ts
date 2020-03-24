import { Component, OnInit } from '@angular/core';
import { Router, ActivatedRoute } from '@angular/router';
import { LoginService } from '../../services/login.service';
import { StockService } from '../../services/stock.service';
import { FileSaverService } from 'ngx-filesaver';
import { map } from 'rxjs/operators';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';

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
  selector: 'app-guias',
  templateUrl: './guias.component.html',
  styles: []
})
export class GuiasComponent implements OnInit {

  causales = [];
  cargando = false;
  grabando = false;
  totalItemes = 0;
  bodegas: any;
  destinos: any;
  auxiliares: any;
  tipoGuia = '';
  deta: Array<Detalle> = [];
  enca: Documento;

  constructor( private login: LoginService,
               private router: Router,
               private stockSS: StockService,
               private file: FileSaverService,
               private params: ActivatedRoute ) {
    this.tipoGuia = this.params.snapshot.paramMap.get('dev');
  }

  ngOnInit() {
    if ( !this.login.usuario ) {
      this.router.navigate(['/login']);
    }
    this.bodegas  = this.login.localesPermitidos;
    if ( this.login.usuario.supervisor === true ) {
      this.destinos = this.login.todoLocal;
    } else {
      this.destinos = [];
      for (const fila of this.login.todoLocal) {
        if ( fila.CodBode === '9' ) {
          this.destinos.push( fila );
        }
      }
    }
    //
    this.stockSS.retieveAuxiliares()
        .pipe(
            map( (data: any) => {
              if ( this.login.usuario.supervisor === true ) {
                return data;
              } else {
                return { datos: [ {CodAux: '81013400', NomAux: 'BOMBONES VARSOVIENNE S.A.'} ] };
              }
            })
        )
        .subscribe( (data: any) => {
            this.auxiliares = data.datos;
        });
    this.inicializar();
  }

  inicializar() {
    this.deta = [];
    this.enca = { tipo: 'S',
                  bodega: '',
                  destino: '',
                  auxiliar: '',
                  numero: undefined,
                  folio: undefined,   // trabajo con string pero se grama como numero
                  codigoSII: 0,
                  electronico: true,
                  tipoServSII: 0,  // consumo interno = 3
                  concepto: '06',
                  descConcepto: 'Traslado entre locales',
                  fecha: new Date(),
                  glosa: 'Traslado entre locales',
                  ccosto: undefined,
                  descCCosto: '',
                  usuario: this.login.usuario.id,
                  vendedor: '',
                  neto: 0,
                  iva: 0,
                  bruto: 0 };
    this.recalculaTotal();
  }

  ValidarConsumo() {
    this.grabando = true;
    //
    this.enca.neto  = Math.round( this.totalItemes );
    this.enca.iva   = Math.round( this.totalItemes * 0.19 );
    this.enca.bruto = Math.round( this.enca.iva + this.enca.neto );
    // documento electronico?
    this.enca.codigoSII = ( this.enca.electronico ) ? 52 : 50 ;
    //
    if ( this.deta.length === 0 ) {
      this.grabando = false;
      Swal.fire('Detalle de la guía no puede estar vacío');
    } else if ( this.enca.bodega === '' ) {
      this.grabando = false;
      Swal.fire('Bodega Origen no puede estar vacía');
    } else if ( this.enca.destino === '' ) {
      this.grabando = false;
      Swal.fire('Bodega Destino no puede estar vacía');
    } else if ( this.enca.auxiliar === '' ) {
      this.grabando = false;
      Swal.fire('Auxiliar de Destino del no puede estar vacío');
    } else if ( this.enca.fecha === undefined ) {
      this.grabando = false;
      Swal.fire('Fecha no puede estar vacía');
    } else {
      //
      this.enca.folio  = '';
      this.enca.numero = 0;
      //
      this.stockSS.grabarGuiaDeTraslado( this.enca, this.deta )
          .subscribe( (data: any) => {
              //
              this.grabando = false;
              if ( data.resultado === 'ok' ) {
                //
                this.descargaArchivo( data.datos[0].nroint, data.datos[0].folio );
                //
                Swal.fire({
                  icon: 'success',
                  title: 'FOLIO: ' + data.datos[0].folio,
                  text: 'Guía de Traslado fue grabada con éxito',
                  footer: '<a href>Nro.Interno Softlland: ' + data.datos[0].nroint + ' </a>'
                });                
                //
                this.inicializar();
              } else {
                Swal.fire({
                  icon: 'error',
                  title: 'Cuidado...',
                  text: 'La Guía de Traslado no fue grabada!',
                  footer: '<a href>' + data.datos + '</a>'
                });
              }
          });
      }
  }
  descargaArchivo( nroint: number, folio: number ) {
    //
    /*  http://www.dcmembers.com/skrommel/download/moveout/   */
    //
    let lista = '';
    const fileName =  'GDV_' + folio.toString() + '-' + nroint.toString() + '.txt';
    //
    this.stockSS.G2Print( nroint, folio )
        .pipe(
          map( (data: any) => {
            //
            for (const fila of data.datos) {
              lista += fila.dato + '\n';
            }
            return lista;
            //
          })
        )
        .subscribe( (data: any) => {
            //
            this.file.saveText( data, fileName );
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

  rescataCC() {
    //
    this.stockSS.retieveCenCosto( this.enca.bodega )
        .subscribe( (data: any) => {
          try {
            this.enca.ccosto     = data.datos[0].CodiCC;
            this.enca.descCCosto = data.datos[0].DescCC;
            this.enca.vendedor   = data.datos[0].VenCod;
          } catch (error) {
            this.enca.ccosto     = undefined;
            this.enca.descCCosto = '';
            this.enca.vendedor   = undefined;
          }
        });
  }

  recalculaTotal() {
    this.totalItemes = 0;
    this.deta.forEach(element => {
      this.totalItemes += element.subTotal;
    });
  }

}
