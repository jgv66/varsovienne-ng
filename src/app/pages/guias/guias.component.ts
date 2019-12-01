import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-guias',
  templateUrl: './guias.component.html',
  styles: []
})
export class GuiasComponent implements OnInit {

  bodegas = [];
  bodegaOrigen = '';
  bodegaDestino = '';
  cargando = false;

  constructor() { }

  ngOnInit() {
  }

  ValidarConsumo() {}

}
