import { Component, OnInit } from '@angular/core';
import { Observable } from 'rxjs';
import { StockService } from '../../services/stock.service';

@Component({
  selector: 'app-stock',
  templateUrl: './stock.component.html',
  styleUrls: []
})
export class StockComponent implements OnInit {

  maxDate: Date = new Date();
  yearMonth: Date;
  locale = 'es';
  parsedYearMonth: string;
  cargando = false;
  retrievedData$: Observable<any>;
  stock: Array<any>;
  bodegas: Array<any>;
  bodega = '';
  conStock = false;
  sinStock = false;
  errorFiltros = false;

  constructor( private stockSS: StockService ) {}

  ngOnInit() {
    this.cargando = true;

    this.stockSS.retrieveBodegas()
      .subscribe( (resultado: any) => {
        this.bodegas = resultado.datos;
        this.cargando = false;
      });

  }

  consultaStock() {
    if ( this.conStock && this.sinStock ) {
      this.errorFiltros = true;
    } else {
      this.cargando = true;
      this.stockSS.retrieveStock( this.bodega, this.conStock )
          .subscribe( (resultado: any) => {
              this.stock = resultado.datos;
              this.cargando = false;
          });
    }
  }

  limpiaLista() {
    this.stock = [];
  }

}

