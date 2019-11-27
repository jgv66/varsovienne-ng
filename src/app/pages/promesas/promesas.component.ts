import { Component, OnInit } from '@angular/core';
import { interval } from 'rxjs';
import { compileNgModule } from '@angular/compiler';

@Component({
  selector: 'app-promesas',
  templateUrl: './promesas.component.html',
  styles: []
})
export class PromesasComponent implements OnInit {

  constructor() {

    this.contarTres()
      .then(  (me)   => console.log('terminé', me ) )
      .catch( (er) => console.log('catch error : ', er) );

  }

  ngOnInit() {
  }

  contarTres(): Promise<boolean> {

    return new Promise( (resolve, reject) => {

      let contador = 0;

      const conteo = setInterval( () => {
              contador += 1;
              console.log(contador);
              if ( contador === 3 ) {
                resolve(true);
                // reject('existe un error');
                clearInterval( conteo );
              }
      }, 1000 );

    });

  }

}
