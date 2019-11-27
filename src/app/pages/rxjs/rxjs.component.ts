import { Component, OnInit, OnDestroy } from '@angular/core';
import { Observable, Subscriber, Subscription } from 'rxjs';
import { retry, map, filter } from 'rxjs/operators';

@Component({
  selector: 'app-rxjs',
  templateUrl: './rxjs.component.html',
  styles: []
})
export class RxjsComponent implements OnInit, OnDestroy {

  subscripcion: Subscription;

  constructor() {

    this.subscripcion = this.regresaObservable()
                            .pipe( retry( 2 ) )
                            .subscribe(
                              num => console.log( 'Subs', num ),
                              err => console.log( 'Subs Err', err ),
                              ()  => console.log( 'Subs TERMINO !!!')
                            );
  }

  ngOnInit() {}
  ngOnDestroy() {
    console.log('la pagina se va a cerrar');
    this.subscripcion.unsubscribe();
  }

  regresaObservable(): Observable<any> {

    return new Observable( (observer: Subscriber<any>) => {
      let contador = 0;
      const intervalo = setInterval( () => {
        contador += 1;

        const salida = {
          valor: contador
        };

        // observer.next( contador );
        observer.next( salida );

        // se deja en comentario para probar el onDestroy()
        // if ( contador === 3 ) {
        //   clearInterval( intervalo );
        //   observer.complete();
        // }

        // if ( contador === 2 ) {
        //   // clearInterval( intervalo );
        //   observer.error('fallamos');
        // }

      }, 1000);
    }).pipe(
      // map permite cambiar los datos retornados por el observable
      map( resp => resp.valor ),
      // filtra la salida de datos, con verdadero o falso, ejemplo pares o impares
      filter( ( valor, index ) => {

        if ( (valor % 2 ) === 1 ) {
            return true;
        } else {
            return false;
        }
        return true;
      })
    );

  }

}
