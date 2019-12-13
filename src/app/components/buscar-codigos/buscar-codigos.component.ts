import { Component, OnInit, Output, EventEmitter } from '@angular/core';
import { NgModule } from '@angular/core';
import { StockService } from '../../services/stock.service';

// ES6 Modules or TypeScript
import Swal from 'sweetalert2';

@Component({
  selector: 'app-buscar-codigos',
  templateUrl: './buscar-codigos.component.html',
  styles: []
})
export class BuscarCodigosComponent implements OnInit {

  @Output() 

  codigo = '';
  codigos = [];
  cargando = false;

  @Output() actualizaItem: EventEmitter<object> = new EventEmitter();

  constructor( private stockSS: StockService ) { }

  ngOnInit() {}

  buscarCodigo() {
    this.cargando = true;
    this.stockSS.retrieveCodigos( this.codigo )
      .subscribe( (resultado: any) => {
        this.codigos = resultado.datos;
        this.cargando = false;
      });
  }

  trasladaDatos( det: any ) {
    // console.log(det);
    if ( det.cantidad <= 0 ) {
      Swal.fire('Cantidad no puede ser negativa o cero.');
    } else {
      // traslado el item
      this.actualizaItem.emit( det );
      let index = 0;
      // se quita de la matriz
      this.codigos.forEach(element => {
        if ( element.CodProd === det.CodProd ) {
          this.codigos.splice(index, 1);
          return;
        }
        index += 1;
      });
    }
  }

}
