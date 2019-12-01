import { Component, OnInit } from '@angular/core';
import { StockService } from '../../services/stock.service';

@Component({
  selector: 'app-stockp',
  templateUrl: './stockp.component.html',
  styles: []
})

export class StockpComponent implements OnInit {

  cargando = false;
  bodegas  = [];
  bodega = '';
  codigo = '';
  codigos  = [];

  abriendoDetalle: string;
  detalleAbierto: string;

  constructor( private stockSS: StockService) { }

  ngOnInit() {}

  buscarProductos() {
    this.cargando = true;
    this.stockSS.retrieveCodigos( this.codigo )
      .subscribe( (resultado: any) => {
        this.codigos = resultado.datos;
        this.cargando = false;
      });
  }

  stockxLocal( data ) {
    // console.log('detalleOnOff: ', data);

    const abrirDetalle = this.detalleAbierto !== data.CodProd;
    // console.log(this.detalleAbierto);
    if ( abrirDetalle ) {
      this.detalleAbierto = undefined;
      this.abriendoDetalle = data.CodProd;
      this.stockSS.retrieveStockxProd( data.CodProd )
          .subscribe( (stock: any) => {
              // console.log(stock);
              this.abriendoDetalle = undefined;
              data.abierto = true;
              data.stock = [];
              stock.datos.forEach(fila => {
                data.stock.push( fila );
              });
              this.detalleAbierto = data.CodProd;
            },
            err => {
              this.abriendoDetalle = undefined;
              this.detalleAbierto = undefined; }
          );
    } else {
      this.abriendoDetalle = undefined;
      this.detalleAbierto = undefined;
    }
    
  }

}
