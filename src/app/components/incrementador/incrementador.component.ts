import { Component, OnInit, Input, Output, EventEmitter, ViewChild, ElementRef } from '@angular/core';

@Component({
  selector: 'app-incrementador',
  templateUrl: './incrementador.component.html',
  styles: []
})
export class IncrementadorComponent implements OnInit {

  @ViewChild('txtProgress', null ) txtProgress: ElementRef;

  @Input('nombre') leyenda: string = 'leyenda';
  @Input() progreso: number = 50;

  @Output() actualizaValor: EventEmitter<number> = new EventEmitter();

  constructor() { }

  ngOnInit() {
  }

  onChanges(newValue: number) {
    console.log(newValue);
    console.log( this.txtProgress );
    // this.txtProgress.nativeElement.value = this.progreso

  }

  cambiarValor( newValue ) {

    if ( this.progreso >= 100 && newValue > 0 ) {
      this.progreso = 100;
      return ;
    }
    if ( this.progreso <= 0 && newValue < 0 ) {
      this.progreso = 0;
      return;
    } else {
      this.progreso = newValue;
    }

    this.progreso = this.progreso + newValue;

    this.actualizaValor.emit( this.progreso );

  }

}
