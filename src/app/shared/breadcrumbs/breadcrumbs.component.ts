import { Component, OnInit } from '@angular/core';
import { Router, ActivationEnd } from '@angular/router';
import { filter, map } from 'rxjs/operators';
import { Title, Meta, MetaDefinition } from '@angular/platform-browser';
import { LoginService } from '../../services/login.service';

@Component({
  selector: 'app-breadcrumbs',
  templateUrl: './breadcrumbs.component.html',
  styles: []
})
export class BreadcrumbsComponent implements OnInit {

  granTitulo = '';
  nombreUsuario = '';

  constructor( private router: Router,
               private title: Title,
               private meta: Meta,
               public login: LoginService) {
    //
    try {
      this.nombreUsuario = this.login.usuario.nombre;
    } catch (error) {
      this.nombreUsuario = '';
    }
    //
    this.getDataRoute()
        .subscribe( data => {
          // console.log( data.titulo );
          this.granTitulo = data.titulo;
          this.title.setTitle( data.titulo );
          // esta in clusion permite cambiar los metatags de la pagina
          // para incluir descripciones y cosas varias
          const metaTag: MetaDefinition = {
            name: 'description',
            content: this.granTitulo,
          };
          this.meta.updateTag( metaTag );

        });

  }

  ngOnInit() {
  }

  getDataRoute() {

    return this.router.events
      .pipe(
        // primero se filtra por ActivationEnd
        filter( evento => evento instanceof ActivationEnd ),
        // segundo, de lo ya filtrado, se filtra solo por el child que esta con "data" nulo
        filter( (evento: ActivationEnd) => evento.snapshot.firstChild === null ),
        // ahora de lo que resulta, solo quiero lo referido a snapshot.data
        map( (evento: ActivationEnd) => evento.snapshot.data )
        //
      );

  }
}
